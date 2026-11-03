using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using MonoGameLibrary;
using MonoGameLibrary.Input;
using MonoGameLibrary.World;
using Proto4X.Sandbox.Components;
using Proto4X.Sandbox.Game;
using Proto4X.Sandbox.Rendering;
using Proto4X.Sandbox.Systems;
using System;

namespace Proto4X.Sandbox
{
    /// <summary>
    /// A slim space RTS in the Age of Empires mould - mine, build, expand, fight, raze. See
    /// DESIGN.md for the shape of the game and ENGINE_REQUESTS.md for what the engine made awkward.
    /// </summary>
    public class Sandbox() : Core("Void Command", 1280, 720, true)
    {
        private const int WorldWidth = 6400;
        private const int WorldHeight = 3600;
        private const int StartingMinerals = 150;
        private const int StartingMiners = 3;

        /// <summary>Each faction's home corner, as a fraction of the world, so the map scales in one place.</summary>
        private static readonly (FactionId Faction, Vector2 HomeFraction)[] Homelands =
        [
            (FactionId.Player, new Vector2(0.12f, 0.80f)),
            (FactionId.Enemy, new Vector2(0.88f, 0.80f)),
            (FactionId.Rival, new Vector2(0.50f, 0.15f)),
        ];

        private const int AsteroidFieldCount = 90;
        private const int MinimumRocksPerField = 4;
        private const int MaximumRocksPerField = 11;
        private const int MapSeed = 20260805;

        private readonly Economy economy = new(StartingMinerals);
        private readonly SpawnQueue spawnQueue = new();

        private SpriteSet sprites = null!;
        private StationIndexSystem stationIndex = null!;
        private FleetCensusSystem fleetCensus = null!;
        private SelectionSystem selectionSystem = null!;
        private SelectionSummarySystem selectionSummary = null!;
        private PerformanceGraphRenderer performanceGraph = null!;

        /// <summary>
        /// Victory is only judged once every faction has actually appeared. Entity creation is
        /// deferred - only the very first entity of a new archetype is added synchronously - so on
        /// the opening frame the world genuinely contains one station and no opponents, which used
        /// to read as an instant win.
        /// </summary>
        private bool hasWorldSettled;
        private FactionId? victor;

        protected override GameWorld InitializeGameWorld()
        {
            return new GameWorld(0, 0, WorldWidth, WorldHeight);
        }

        protected override void OnInitialize()
        {
            // Order matters: the index systems publish the snapshots every later system reads, and
            // input has to be turned into orders before steering acts on them.
            var asteroidIndex = new AsteroidIndexSystem();
            stationIndex = new StationIndexSystem();
            fleetCensus = new FleetCensusSystem();
            selectionSystem = new SelectionSystem(UserInterfaceManager.Camera);
            selectionSummary = new SelectionSummarySystem();

            SystemScheduler.Add(World, asteroidIndex);
            SystemScheduler.Add(World, stationIndex);
            SystemScheduler.Add(World, fleetCensus);

            // Selection first, then the commands that act on it - a key pressed this frame should
            // apply to what the click this frame selected.
            SystemScheduler.Add(World, selectionSystem);
            SystemScheduler.Add(World, selectionSummary);
            SystemScheduler.Add(World, new MoveOrderSystem(UserInterfaceManager.Camera));
            SystemScheduler.Add(World, new RallyPointSystem(UserInterfaceManager.Camera));
            SystemScheduler.Add(World, new StationCommandSystem(economy));
            SystemScheduler.Add(World, new MinerConstructionSystem(economy, spawnQueue));

            // Expansion runs before production because production has to be told what the expansion
            // fund is before it decides what to spend - see AiDoctrine for the full priority ladder.
            var expansionAi = new ExpansionAiSystem(economy, asteroidIndex, stationIndex);
            SystemScheduler.Add(World, expansionAi);
            SystemScheduler.Add(World, new MinerSystem(asteroidIndex, stationIndex, economy));
            SystemScheduler.Add(World, new EnemyProductionAiSystem(economy, fleetCensus, stationIndex, expansionAi));
            SystemScheduler.Add(World, new EnemyFleetAiSystem(stationIndex, fleetCensus));

            SystemScheduler.Add(World, new MoveToTargetSystem());
            // After steering, which zeroes acceleration for idle ships - that's what lets the
            // separation nudge survive through to the movement integrator.
            SystemScheduler.Add(World, new SeparationSystem());
            SystemScheduler.Add(World, new MovementSystem());

            // Repair before combat, so healing applies to last frame's damage and a station reduced
            // to zero can't be topped back up before DeathSystem sees it.
            SystemScheduler.Add(World, new StationRepairSystem());
            SystemScheduler.Add(World, new CombatSystem());
            SystemScheduler.Add(World, new DeathSystem());
            // Standing orders refill an empty queue just before the factory looks at it, so a
            // station on repeat starts its next ship on the same frame it finished the last.
            SystemScheduler.Add(World, new StationAutoQueueSystem(economy));
            SystemScheduler.Add(World, new ProductionSystem(spawnQueue));
        }

        protected override void LoadContent()
        {
            sprites = new SpriteSet(Content, GraphicsDevice);
            performanceGraph = new PerformanceGraphRenderer(sprites.Pixel, GraphicsDevice);

            SystemScheduler.Add(World, new WeaponBeamRenderer(sprites.Pixel));
            SystemScheduler.Add(World, new SelectionRingRenderer(sprites.Pixel));
            SystemScheduler.Add(World, new RallyPointRenderer(sprites.Pixel));
            SystemScheduler.Add(World, new HealthBarRenderer(sprites.Pixel));
            SystemScheduler.Add(World, new BuildProgressRenderer(sprites.Pixel, sprites));
            SystemScheduler.Add(World, new ConstructionProgressRenderer(sprites.Pixel, sprites));

            SystemScheduler.Add(World, new MinimapRenderer(sprites.Pixel, GraphicsDevice, UserInterfaceManager.Camera, World.Bounds));
            SystemScheduler.Add(World, new BuildMenuRenderer(sprites.Pixel, GraphicsDevice, sprites, economy, selectionSummary));
            SystemScheduler.Add(World, new SelectionBoxRenderer(sprites.Pixel, selectionSystem));
            SystemScheduler.Add(World, performanceGraph);

            GenerateMap();
        }

        protected override void OnUpdate(GameTime gameTime)
        {
            performanceGraph.Record(gameTime);

            var keyboard = InputManager.Instance.KeyboardInfo;
            if (keyboard.IsKeyDown(Keys.Escape))
            {
                Exit();
            }

            if (keyboard.WasKeyJustPressed(Keys.F))
            {
                SpawnStressTestFleet();
            }

            // Systems describe what they finished building; only code outside a running system is
            // allowed to actually create entities. See SpawnQueue.
            foreach (var spawn in spawnQueue.Pending)
            {
                World.AddEntity(ShipBlueprints.CreateUnit(spawn.Kind, spawn.Location, spawn.Faction, sprites, spawn.InitialDestination));
            }
            spawnQueue.Clear();

            UpdateVictoryState();
            Window.Title = BuildStatusLine();
        }

        protected override void OnDraw(GameTime gameTime)
        {
            GraphicsDevice.Clear(new Color(8, 10, 22));
        }

        private void GenerateMap()
        {
            var random = new Random(MapSeed);

            foreach (var (faction, homeFraction) in Homelands)
            {
                var home = new Vector2(WorldWidth * homeFraction.X, WorldHeight * homeFraction.Y);
                World.AddEntity(ShipBlueprints.CreateStation(home, faction, sprites.StationSpriteFor(faction)));
                SpawnStartingMiners(home, faction);

                // A guaranteed field next to each home, so nobody starves on an unlucky seed.
                SpawnAsteroidField(random, home + new Vector2(180f, -200f), 6);
                SpawnAsteroidField(random, home + new Vector2(-200f, 190f), 5);
            }

            for (var field = 0; field < AsteroidFieldCount; field++)
            {
                var centre = new Vector2(
                    (float)random.NextDouble() * WorldWidth,
                    (float)random.NextDouble() * WorldHeight);

                SpawnAsteroidField(random, centre, random.Next(MinimumRocksPerField, MaximumRocksPerField + 1));
            }
        }

        private void SpawnStartingMiners(Vector2 stationLocation, FactionId faction)
        {
            for (var i = 0; i < StartingMiners; i++)
            {
                var angle = MathHelper.TwoPi * i / StartingMiners;
                var location = stationLocation + new Vector2(MathF.Cos(angle), MathF.Sin(angle)) * 80f;
                World.AddEntity(ShipBlueprints.CreateMiner(location, faction, sprites.MinerSpriteFor(faction)));
            }
        }

        private void SpawnAsteroidField(Random random, Vector2 centre, int count)
        {
            for (var i = 0; i < count; i++)
            {
                var angle = (float)(random.NextDouble() * MathHelper.TwoPi);
                var distance = 30f + (float)random.NextDouble() * 120f;
                var location = centre + new Vector2(MathF.Cos(angle), MathF.Sin(angle)) * distance;
                var spriteId = sprites.AsteroidSpriteIds[random.Next(sprites.AsteroidSpriteIds.Length)];
                World.AddEntity(ShipBlueprints.CreateAsteroid(location, spriteId));
            }
        }

        /// <summary>
        /// Dumps a free fighter wave on every faction. Purely a load test - it bypasses the economy
        /// so the entity count can be pushed far past what the game would reach on its own.
        /// </summary>
        private void SpawnStressTestFleet()
        {
            const int FleetSize = 40;

            foreach (var (faction, homeFraction) in Homelands)
            {
                var home = new Vector2(WorldWidth * homeFraction.X, WorldHeight * homeFraction.Y);
                for (var i = 0; i < FleetSize; i++)
                {
                    var angle = MathHelper.TwoPi * i / FleetSize;
                    var location = home + new Vector2(MathF.Cos(angle), MathF.Sin(angle)) * (140f + i * 3f);
                    World.AddEntity(ShipBlueprints.CreateFighter(location, faction, sprites.FighterSpriteFor(faction)));
                }
            }
        }

        private void UpdateVictoryState()
        {
            if (!hasWorldSettled)
            {
                var everyoneHasArrived = true;
                foreach (var faction in Faction.Playing)
                {
                    if (stationIndex.CountFor(faction) == 0)
                    {
                        everyoneHasArrived = false;
                    }
                }

                hasWorldSettled = everyoneHasArrived;
                return;
            }

            if (victor is not null)
            {
                return;
            }

            if (stationIndex.CountFor(FactionId.Player) == 0)
            {
                victor = FactionId.Enemy;
                return;
            }

            var survivingOpponents = 0;
            foreach (var faction in Faction.AiControlled)
            {
                survivingOpponents += stationIndex.CountFor(faction);
            }

            if (survivingOpponents == 0)
            {
                victor = FactionId.Player;
            }
        }

        /// <summary>
        /// A debug readout, not the HUD - the game itself renders no text on purpose (see
        /// DESIGN.md). Kept because raw entity counts are exactly what a load test wants to see.
        /// </summary>
        private string BuildStatusLine()
        {
            if (victor == FactionId.Player)
            {
                return "VICTORY - every rival station destroyed. Esc to quit.";
            }

            if (victor == FactionId.Enemy)
            {
                return "DEFEAT - your last station is gone. Esc to quit.";
            }

            return $"Minerals {economy.GetMinerals(FactionId.Player)}"
                + $" | You {fleetCensus.MinersFor(FactionId.Player)}m/{fleetCensus.FightersFor(FactionId.Player)}f/{stationIndex.CountFor(FactionId.Player)}s"
                + $" | Enemy {fleetCensus.MinersFor(FactionId.Enemy)}m/{fleetCensus.FightersFor(FactionId.Enemy)}f/{stationIndex.CountFor(FactionId.Enemy)}s"
                + $" | Rival {fleetCensus.MinersFor(FactionId.Rival)}m/{fleetCensus.FightersFor(FactionId.Rival)}f/{stationIndex.CountFor(FactionId.Rival)}s"
                + " | [F] stress fleet";
        }
    }
}
