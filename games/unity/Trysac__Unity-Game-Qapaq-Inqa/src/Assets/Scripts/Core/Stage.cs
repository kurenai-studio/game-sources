using System;
using System.Collections.Generic;

namespace QapaqInqa.Core
{
    public enum StagePhase
    {
        Playing,
        /// <summary>The player fell; after <see cref="Tuning.DyingTime"/> the run decides respawn or game over.</summary>
        Dying,
        /// <summary>The player walked through the open Sun Gate.</summary>
        Cleared,
    }

    public enum StageEventKind
    {
        Jump,
        Land,
        Climb,
        Shoot,
        ArrowBroke,
        Coin,
        Artifact,
        Shell,
        Heart,
        Checkpoint,
        GateOpened,
        Hurt,
        Died,
        EnemyHit,
        EnemyDefeated,
        Stomp,
        BossWoke,
        BossSlam,
        BossThrow,
        BossDefeated,
        Cleared,
    }

    /// <summary>Something the view should show or play, at a place in the world.</summary>
    public readonly struct StageEvent
    {
        public StageEvent(StageEventKind kind, Vec2 at, int points = 0)
        {
            Kind = kind;
            At = at;
            Points = points;
        }

        public StageEventKind Kind { get; }
        public Vec2 At { get; }
        public int Points { get; }
        public override string ToString() => $"{Kind} at {At} (+{Points})";
    }

    /// <summary>A coin, idol, shell, heart or checkpoint, with a stable id for the view.</summary>
    public sealed class Pickup
    {
        public Pickup(int id, ThingKind kind, Vec2 tile)
        {
            Id = id;
            Kind = kind;
            Tile = tile;
        }

        public int Id { get; }
        public ThingKind Kind { get; }
        /// <summary>Bottom-left of its tile.</summary>
        public Vec2 Tile { get; }
        public bool Taken { get; set; }
        public Vec2 Center => new Vec2(Tile.X + 0.5f, Tile.Y + 0.5f);
        public Box Bounds => Kind == ThingKind.Checkpoint
            ? new Box(Tile.X + 0.5f, Tile.Y, 1f, 2f)
            : new Box(Tile.X + 0.5f, Tile.Y + 0.15f, 0.7f, 0.7f);
    }

    /// <summary>
    /// One level being played: the player, enemies, pickups, arrows and rocks, stepped at a fixed
    /// rate. It knows nothing about lives or menus; <see cref="Run"/> owns those.
    /// </summary>
    public sealed class Stage
    {
        readonly List<StageEvent> events = new List<StageEvent>();
        readonly List<Enemy> enemies = new List<Enemy>();
        readonly List<Pickup> pickups = new List<Pickup>();
        readonly List<Arrow> arrows = new List<Arrow>();
        readonly List<Rock> rocks = new List<Rock>();
        float fireCooldown;
        int rocksThrown;

        public Stage(LevelMap map)
        {
            Map = map ?? throw new ArgumentNullException(nameof(map));
            Player = new PlayerMotor(map.Start);
            Health = new Health(Tuning.MaxHearts);
            RespawnPoint = map.Start;
            int id = 0;
            foreach (Placement p in map.Placements)
            {
                var feet = new Vec2(p.X + 0.5f, p.Y);
                switch (p.Kind)
                {
                    case ThingKind.Walker: enemies.Add(new Walker(id, feet)); break;
                    case ThingKind.Bat: enemies.Add(new Bat(id, new Vec2(p.X + 0.5f, p.Y + 0.2f))); break;
                    case ThingKind.Boss:
                        Boss = new StonePuma(id, new Vec2(p.X + 1f, p.Y));
                        enemies.Add(Boss);
                        break;
                    default: pickups.Add(new Pickup(id, p.Kind, new Vec2(p.X, p.Y))); break;
                }
                id++;
            }
            ArtifactsTotal = map.Count(ThingKind.Artifact);
            GateOpen = ArtifactsTotal == 0 && Boss == null;
        }

        public LevelMap Map { get; }
        public PlayerMotor Player { get; }
        public Health Health { get; }
        public StonePuma Boss { get; }
        public StagePhase Phase { get; private set; }
        public float PhaseTime { get; private set; }
        /// <summary>Seconds spent playing this level (not counting deaths or pauses).</summary>
        public float Elapsed { get; private set; }
        public Vec2 RespawnPoint { get; private set; }
        public int ArtifactsTotal { get; }
        public int ArtifactsFound { get; private set; }
        public int CoinsFound { get; private set; }
        public bool GateOpen { get; private set; }
        /// <summary>Points earned in this level so far (the run adds them to its score).</summary>
        public int Points { get; private set; }
        public int Deaths { get; private set; }
        /// <summary>For tests and the screenshot tool: the player cannot be hurt.</summary>
        public bool Invincible { get; set; }

        public IReadOnlyList<Enemy> Enemies => enemies;
        public IReadOnlyList<Pickup> Pickups => pickups;
        public IReadOnlyList<Arrow> Arrows => arrows;
        public IReadOnlyList<Rock> Rocks => rocks;
        /// <summary>What happened during the last <see cref="Step"/>.</summary>
        public IReadOnlyList<StageEvent> Events => events;

        public Box GateBounds => new Box(Map.Gate.X + 1f, Map.Gate.Y, 2f, 3f);
        public Vec2 PlayerCenter => new Vec2(Player.X, Player.Y + Player.Height / 2f);

        public void Step(InputFrame input, float dt)
        {
            events.Clear();
            PhaseTime += dt;
            Health.Tick(dt);
            fireCooldown = Math.Max(0f, fireCooldown - dt);

            foreach (Enemy enemy in enemies)
            {
                enemy.Tick(Map, Player.Feet, dt);
            }
            if (Boss != null) BossTurn();
            MoveShots(dt);

            if (Phase != StagePhase.Playing)
            {
                return;
            }
            Elapsed += dt;

            MoveEvents moved = Player.Step(Map, input, dt);
            if ((moved & MoveEvents.Jumped) != 0) Emit(StageEventKind.Jump, Player.Feet);
            if ((moved & MoveEvents.Landed) != 0) Emit(StageEventKind.Land, Player.Feet);
            if ((moved & MoveEvents.StartedClimbing) != 0) Emit(StageEventKind.Climb, Player.Feet);

            if (input.Fire && fireCooldown <= 0f && !Player.Climbing)
            {
                fireCooldown = Tuning.FireCooldown;
                var from = new Vec2(Player.X + Player.Facing * 0.4f, Player.Y + 0.85f);
                arrows.Add(new Arrow(from, Player.Facing));
                Emit(StageEventKind.Shoot, from);
            }

            HitEnemiesWithArrows();
            TouchEnemies();
            TouchSpikes();
            TouchPickups();
            TouchGate();

            if (Player.Y < Tuning.FallOutDepth)
            {
                Health.Kill();
            }
            if (Health.IsDead && Phase == StagePhase.Playing)
            {
                Phase = StagePhase.Dying;
                PhaseTime = 0f;
                Deaths++;
                Emit(StageEventKind.Died, Player.Feet);
            }
        }

        /// <summary>
        /// Puts the player back at the last checkpoint with full hearts. Pickups already taken stay
        /// taken (and their points stay earned), defeated enemies stay down, and a boss still standing
        /// goes back to sleep at full health.
        /// </summary>
        public void Respawn()
        {
            Player.Respawn(RespawnPoint);
            Health.Restore();
            arrows.Clear();
            rocks.Clear();
            if (Boss != null && Boss.Alive) Boss.Reset();
            Phase = StagePhase.Playing;
            PhaseTime = 0f;
        }

        /// <summary>For tests and tools: damages an enemy exactly as an arrow hit would.</summary>
        public void Strike(Enemy enemy, int damage) => Damage(enemy, damage, new Vec2(enemy.X, enemy.Y + enemy.Height / 2f));

        /// <summary>For tests and tools: puts the player's feet somewhere.</summary>
        public void PlacePlayer(Vec2 feet) => Player.Respawn(feet);

        void BossTurn()
        {
            if (Boss.WokeNow) Emit(StageEventKind.BossWoke, Boss.Bounds.Center());
            if (Boss.SlammedNow) Emit(StageEventKind.BossSlam, new Vec2(Boss.X, Boss.Y));
            if (Boss.ThrowsRockNow && Boss.Alive && Phase == StagePhase.Playing)
            {
                rocks.Add(Boss.MakeRock(PlayerCenter, rocksThrown++));
                Emit(StageEventKind.BossThrow, new Vec2(Boss.X, Boss.Y + Boss.Height));
            }
        }

        void MoveShots(float dt)
        {
            foreach (Arrow arrow in arrows)
            {
                arrow.Tick(Map, dt);
                if (arrow.Gone && arrow.Age <= Tuning.ArrowLifetime) Emit(StageEventKind.ArrowBroke, arrow.Position);
            }
            arrows.RemoveAll(a => a.Gone);
            foreach (Rock rock in rocks)
            {
                rock.Tick(Map, dt);
            }
            rocks.RemoveAll(r => r.Gone);
        }

        void HitEnemiesWithArrows()
        {
            foreach (Arrow arrow in arrows)
            {
                foreach (Enemy enemy in enemies)
                {
                    if (!enemy.Alive || !arrow.Bounds.Overlaps(enemy.Bounds)) continue;
                    arrow.Gone = true;
                    Damage(enemy, Tuning.ArrowDamage, arrow.Position);
                    break;
                }
            }
            arrows.RemoveAll(a => a.Gone);
        }

        void Damage(Enemy enemy, int damage, Vec2 at)
        {
            if (enemy.Kind == EnemyKind.Boss && Boss.Move == BossMove.Defeated) return;
            bool defeated = enemy.Hurt(damage);
            if (!defeated)
            {
                Emit(StageEventKind.EnemyHit, at);
                return;
            }
            Score(enemy.Points);
            if (enemy.Kind == EnemyKind.Boss)
            {
                rocks.Clear();
                Emit(StageEventKind.BossDefeated, enemy.Bounds.Center(), enemy.Points);
                UpdateGate();
            }
            else
            {
                Emit(StageEventKind.EnemyDefeated, enemy.Bounds.Center(), enemy.Points);
            }
        }

        void TouchEnemies()
        {
            Box me = Player.Bounds;
            foreach (Enemy enemy in enemies)
            {
                if (!enemy.Alive || !me.Overlaps(enemy.Bounds)) continue;
                bool stomp = enemy.Stompable && Player.VelocityY < 0f && Player.Y >= enemy.Bounds.Top - 0.35f;
                if (stomp)
                {
                    Player.Bounce();
                    Score(Tuning.StompBonus);
                    Emit(StageEventKind.Stomp, new Vec2(Player.X, Player.Y), Tuning.StompBonus);
                    Damage(enemy, enemy.Kind == EnemyKind.Boss ? 2 : enemy.HealthLeft, new Vec2(Player.X, Player.Y));
                    continue;
                }
                HurtPlayer(enemy.Bounds.CenterX);
            }
            foreach (Rock rock in rocks)
            {
                if (!rock.Gone && me.Overlaps(rock.Bounds) && HurtPlayer(rock.Position.X))
                {
                    rock.Gone = true;
                }
            }
        }

        void TouchSpikes()
        {
            Box me = Player.Bounds;
            int row = LevelMap.Floor(me.Bottom + 0.05f);
            for (int x = LevelMap.Floor(me.Left + 0.1f); x <= LevelMap.Floor(me.Right - 0.1f); x++)
            {
                // Spikes fill the lower half of their tile.
                if (Map.At(x, row) == Tile.Spikes && me.Bottom < row + 0.5f)
                {
                    if (HurtPlayer(x + 0.5f))
                    {
                        Player.Bounce();
                    }
                    return;
                }
            }
        }

        bool HurtPlayer(float fromX)
        {
            if (Invincible || !Health.TryHurt(1)) return false;
            Player.Knockback(fromX);
            Emit(StageEventKind.Hurt, Player.Feet);
            return true;
        }

        void TouchPickups()
        {
            Box me = Player.Bounds;
            foreach (Pickup pickup in pickups)
            {
                if (pickup.Taken || !me.Overlaps(pickup.Bounds)) continue;
                switch (pickup.Kind)
                {
                    case ThingKind.Coin:
                        pickup.Taken = true;
                        CoinsFound++;
                        Score(Tuning.CoinPoints);
                        Emit(StageEventKind.Coin, pickup.Center, Tuning.CoinPoints);
                        break;
                    case ThingKind.Artifact:
                        pickup.Taken = true;
                        ArtifactsFound++;
                        Score(Tuning.ArtifactPoints);
                        Emit(StageEventKind.Artifact, pickup.Center, Tuning.ArtifactPoints);
                        UpdateGate();
                        break;
                    case ThingKind.Shell:
                        pickup.Taken = true;
                        Score(Tuning.ShellPoints);
                        Emit(StageEventKind.Shell, pickup.Center, Tuning.ShellPoints);
                        break;
                    case ThingKind.Heart:
                        pickup.Taken = true;
                        int points = Health.Heal(1) ? 0 : Tuning.SpareHeartPoints;
                        Score(points);
                        Emit(StageEventKind.Heart, pickup.Center, points);
                        break;
                    case ThingKind.Checkpoint:
                        pickup.Taken = true; // lit: it stays lit
                        RespawnPoint = new Vec2(pickup.Tile.X + 0.5f, pickup.Tile.Y);
                        Emit(StageEventKind.Checkpoint, pickup.Center);
                        break;
                }
            }
        }

        void UpdateGate()
        {
            bool open = ArtifactsFound >= ArtifactsTotal && (Boss == null || !Boss.Alive);
            if (open && !GateOpen)
            {
                GateOpen = true;
                Emit(StageEventKind.GateOpened, GateBounds.Center());
            }
        }

        void TouchGate()
        {
            if (!GateOpen) return;
            Box gate = GateBounds;
            if (Player.Bounds.Overlaps(gate) && Player.X > gate.Left + 0.4f && Player.X < gate.Right - 0.4f)
            {
                Phase = StagePhase.Cleared;
                PhaseTime = 0f;
                Emit(StageEventKind.Cleared, GateBounds.Center());
            }
        }

        void Score(int points) => Points += points;

        void Emit(StageEventKind kind, Vec2 at, int points = 0) => events.Add(new StageEvent(kind, at, points));
    }

    public static class BoxExtensions
    {
        public static Vec2 Center(this Box box) => new Vec2(box.CenterX, box.CenterY);
    }
}
