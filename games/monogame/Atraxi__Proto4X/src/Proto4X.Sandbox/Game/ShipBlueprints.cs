using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using Proto4X.Sandbox.Components;
using System;

namespace Proto4X.Sandbox.Game
{
    /// <summary>Cost and build time for anything buildable, in one place so the HUD, the AI and the factory agree.</summary>
    public readonly record struct Blueprint(int MineralCost, float BuildSeconds);

    /// <summary>
    /// One command a selected unit can be given, and the key that gives it.
    /// </summary>
    /// <remarks>
    /// This is what "per-entity-type instructions" means concretely: a key doesn't do a fixed thing,
    /// it does whatever the current selection's kind says it does. <c>1</c> at a station trains a
    /// miner; <c>1</c> at a miner founds a station. The command list is also what
    /// <c>BuildMenuRenderer</c> draws, so the UI and the input handling can't drift apart - they
    /// read the same table.
    /// </remarks>
    public readonly record struct UnitCommand(Keys Hotkey, int HotkeyPips, UnitKind Produces);

    /// <summary>
    /// Builds the <see cref="EntityBuilder"/> for every entity in the game, and answers what each
    /// kind of unit costs and can be told to do. Component order matters:
    /// <c>IDependsOnOtherComponents</c> is checked at <c>With</c> time, so dependencies have to be
    /// added before the components that declare them.
    /// </summary>
    public static class ShipBlueprints
    {
        public static readonly Blueprint Miner = new(MineralCost: 50, BuildSeconds: 6f);
        public static readonly Blueprint Fighter = new(MineralCost: 75, BuildSeconds: 8f);
        public static readonly Blueprint Station = new(MineralCost: 200, BuildSeconds: 12f);

        private static readonly UnitCommand[] StationCommands =
        [
            new(Keys.D1, HotkeyPips: 1, Produces: UnitKind.Miner),
            new(Keys.D2, HotkeyPips: 2, Produces: UnitKind.Fighter),
        ];

        private static readonly UnitCommand[] MinerCommands =
        [
            new(Keys.D1, HotkeyPips: 1, Produces: UnitKind.Station),
        ];

        private static readonly UnitCommand[] NoCommands = [];

        public static Blueprint For(UnitKind kind) => kind switch
        {
            UnitKind.Miner => Miner,
            UnitKind.Fighter => Fighter,
            UnitKind.Station => Station,
            _ => throw new ArgumentOutOfRangeException(nameof(kind), kind, "Not a buildable unit kind"),
        };

        /// <summary>What a unit of this kind can be ordered to build while selected.</summary>
        public static UnitCommand[] CommandsFor(UnitKind kind) => kind switch
        {
            UnitKind.Station => StationCommands,
            UnitKind.Miner => MinerCommands,
            _ => NoCommands,
        };

        public static EntityBuilder CreateMiner(Vector2 location, FactionId faction, int spriteId, Vector2? destination = null)
            => EntityBuilder.CreateEntity()
                .With(new Position(location))
                .With(new Motion(Vector2.Zero))
                .With(new MoveOrder(destination))
                .With(new Faction(faction))
                .With(new Health(60f))
                .With(new Timer(0, shouldRepeat: false))
                .With(new Weapon(damagePerSecond: 0f, range: 0f))
                .With(new Selectable(pickRadius: 18f))
                .With(new UnitType(UnitKind.Miner))
                .With(new Miner(capacity: 12f, miningRatePerSecond: 6f))
                .With(new Drawable(spriteId, null));

        public static EntityBuilder CreateFighter(Vector2 location, FactionId faction, int spriteId, Vector2? destination = null)
            => EntityBuilder.CreateEntity()
                .With(new Position(location))
                .With(new Motion(Vector2.Zero))
                .With(new MoveOrder(destination))
                .With(new Faction(faction))
                .With(new Health(100f))
                .With(new Weapon(damagePerSecond: 14f, range: 150f))
                .With(new Selectable(pickRadius: 18f))
                .With(new UnitType(UnitKind.Fighter))
                .With(new Drawable(spriteId, null));

        public static EntityBuilder CreateStation(Vector2 location, FactionId faction, int spriteId)
            => EntityBuilder.CreateEntity()
                .With(new Position(location))
                .With(new Faction(faction))
                // A station has to survive long enough for its owner's fleet to turn around and come
                // home, or defending is theatre - see the recall logic in EnemyFleetAiSystem.
                .With(new Health(2600f))
                .With(new Timer(0, shouldRepeat: false))
                .With(new Weapon(damagePerSecond: 34f, range: 260f))
                .With(new Selectable(pickRadius: 34f))
                .With(new UnitType(UnitKind.Station))
                // 18/s repair against a fighter's 14 dps: one raider is a nuisance, nine are a siege.
                .With(new Station(rallyDistance: 70f, repairPerSecond: 18f))
                .With(new Drawable(spriteId, null));

        public static EntityBuilder CreateAsteroid(Vector2 location, int spriteId)
            => EntityBuilder.CreateEntity()
                .With(new Position(location))
                .With(new Gatherable(10))
                .With(new Drawable(spriteId, null));

        public static EntityBuilder CreateUnit(UnitKind kind, Vector2 location, FactionId faction, SpriteSet sprites, Vector2? destination = null) => kind switch
        {
            UnitKind.Miner => CreateMiner(location, faction, sprites.MinerSpriteFor(faction), destination),
            UnitKind.Fighter => CreateFighter(location, faction, sprites.FighterSpriteFor(faction), destination),
            // Stations have no Motion or MoveOrder, so a rally destination is meaningless for them.
            UnitKind.Station => CreateStation(location, faction, sprites.StationSpriteFor(faction)),
            _ => throw new ArgumentOutOfRangeException(nameof(kind), kind, "Not a buildable unit kind"),
        };

        public static int SpriteIdFor(UnitKind kind, FactionId faction, SpriteSet sprites) => kind switch
        {
            UnitKind.Miner => sprites.MinerSpriteFor(faction),
            UnitKind.Fighter => sprites.FighterSpriteFor(faction),
            UnitKind.Station => sprites.StationSpriteFor(faction),
            _ => throw new ArgumentOutOfRangeException(nameof(kind), kind, "Has no sprite"),
        };
    }
}
