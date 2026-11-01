package dev.luchoc.littlespaceship.core.application;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.Sprite;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.component.BombState;
import dev.luchoc.littlespaceship.core.domain.component.Weapon;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.domain.system.BombSystem;
import dev.luchoc.littlespaceship.core.domain.system.BossSystem;
import dev.luchoc.littlespaceship.core.domain.system.CleanupSystem;
import dev.luchoc.littlespaceship.core.domain.system.CollisionSystem;
import dev.luchoc.littlespaceship.core.domain.system.DamageSystem;
import dev.luchoc.littlespaceship.core.domain.system.EnemyWeaponSystem;
import dev.luchoc.littlespaceship.core.domain.system.GameSystem;
import dev.luchoc.littlespaceship.core.domain.system.LifetimeSystem;
import dev.luchoc.littlespaceship.core.domain.system.MotionSystem;
import dev.luchoc.littlespaceship.core.domain.system.PickupSystem;
import dev.luchoc.littlespaceship.core.domain.system.ScoreSystem;
import dev.luchoc.littlespaceship.core.domain.system.SpawnSystem;
import dev.luchoc.littlespaceship.core.domain.system.SpawnerSystem;
import dev.luchoc.littlespaceship.core.domain.system.SystemPipeline;
import dev.luchoc.littlespaceship.core.domain.system.WeaponSystem;
import dev.luchoc.littlespaceship.core.port.BalanceValues;
import dev.luchoc.littlespaceship.core.port.ContentSource;
import dev.luchoc.littlespaceship.core.port.GameEventSink;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.SpriteId;
import dev.luchoc.littlespaceship.core.port.WorldView;
import java.util.ArrayList;
import java.util.List;

/**
 * One run of the game, assembled and ready to be ticked.
 *
 * <p>This is what the composition root builds, and the only thing it needs to know about the core:
 * everything it takes and everything it returns is a contract. The world, the entity registry, the
 * component stores and the systems stay inside, which is what stops presentation from reaching into
 * the ECS.
 *
 * <p>It takes a seed and not a generator, so no source of randomness other than the one in the core
 * can be injected. A run is reproducible from that seed plus the sequence of input frames, and that
 * is exactly what a replay stores.
 *
 * <p>Events are drained once the tick is over, never in the middle of it.
 */
public final class Simulation implements TickHandler {

    /**
     * The player's fixed footprint, from {@code docs/design/02-sprite-sizes.md} — synchronisation
     * point 1. Radius and sprite id are art/collision facts that document fixes, not values that
     * change with balancing, so they live here as constants instead of in {@link BalanceValues}. The
     * starting position is different: nothing in the planning docs fixes a number for it yet, so it
     * is a balance value instead, exactly like {@link BalanceValues#playerSpeed()}.
     */
    private static final float PLAYER_COLLIDER_RADIUS = 3.0f;

    private static final SpriteId PLAYER_SPRITE = new SpriteId("ship-basic");

    /** Base shot level, the one every run starts at before any weapon upgrade is picked up. */
    private static final int PLAYER_INITIAL_SHOT_LEVEL = 1;

    private final World world;
    private final SystemPipeline pipeline;
    private final GameEventQueue events;
    private final GameEventSink sink;

    private int tickCount;

    /**
     * Assembles a level-less run with the systems of the MVP, minus {@code SpawnSystem}: nothing
     * spawns because there is no level id to load a timeline for. Useful for a sandbox or a test that
     * builds its own entities; real gameplay uses {@link #Simulation(ContentSource, GameEventSink,
     * int, String)}.
     *
     * @param content where the balance values and definitions come from
     * @param sink where the events of each tick are delivered
     * @param seed the value that makes this run reproducible
     */
    public Simulation(ContentSource content, GameEventSink sink, int seed) {
        this(content, sink, seed, mvpPipeline(null));
    }

    /**
     * Assembles a run with the systems of the MVP, {@code SpawnSystem} included.
     *
     * @param content where the balance values and definitions come from
     * @param sink where the events of each tick are delivered
     * @param seed the value that makes this run reproducible
     * @param levelId the content id of the level whose timeline drives spawning
     */
    public Simulation(ContentSource content, GameEventSink sink, int seed, String levelId) {
        this(content, sink, seed, mvpPipeline(requireLevelId(levelId)));
    }

    /**
     * Assembles a run with an explicit pipeline. Visible to the tests of this package, which need
     * to observe the world with systems of their own, without that possibility leaking outside the
     * core.
     *
     * <p>Every constructor funnels through this one, which is what guarantees a {@code Simulation}
     * never starts with an empty world: the player's ship exists from the first tick, the same way
     * respawn already relies on the player entity never being destroyed.
     */
    Simulation(ContentSource content, GameEventSink sink, int seed, SystemPipeline pipeline) {
        if (content == null || sink == null || pipeline == null) {
            throw new IllegalArgumentException("a simulation needs content, a sink and a pipeline");
        }
        this.events = new GameEventQueue();
        this.world = new World(content, new Rng(seed), events);
        this.pipeline = pipeline;
        this.sink = sink;
        spawnPlayer(world, content.balance());
    }

    /**
     * Runs every system once, in the fixed order, and then delivers what happened.
     *
     * @param step seconds elapsed, always the same fixed value
     * @param input what the player asked for during this tick
     */
    @Override
    public void tick(float step, InputFrame input) {
        if (input == null) {
            throw new IllegalArgumentException("a tick needs an input frame");
        }
        pipeline.run(world, step, input);
        events.drainTo(sink);
        tickCount++;
    }

    /**
     * Returns the read-only view of the run, which is all presentation ever gets.
     *
     * @return a view that cannot modify anything
     */
    public WorldView view() {
        return world.view();
    }

    /**
     * Returns how many ticks this run has simulated.
     *
     * @return the tick count
     */
    public int tickCount() {
        return tickCount;
    }

    /**
     * The systems of the MVP, in the one place they are listed.
     *
     * <p>Each system joins with the phase that implements it, and where it runs is decided by the
     * stage it declares and not by its position in this list. Stages with no system yet — input,
     * weapon, lifetime, pickup, score — are simply skipped by {@link SystemPipeline}.
     *
     * @param levelId the level to spawn waves for, or null to leave the {@code SPAWN} stage empty
     */
    private static SystemPipeline mvpPipeline(String levelId) {
        List<GameSystem> systems = new ArrayList<>();
        systems.add(new MotionSystem());
        systems.add(new WeaponSystem());
        systems.add(new BombSystem());
        if (levelId != null) {
            systems.add(new SpawnSystem(levelId));
        }
        // Stateless and level-independent, unlike SpawnSystem/BossSystem: it only ever reacts to a
        // Spawner component that already exists on some entity, wherever that entity came from, so it
        // is registered unconditionally the same way CollisionSystem or DamageSystem are.
        systems.add(new SpawnerSystem());
        // Stateless and level-independent, the same reasoning as SpawnerSystem right above it: it
        // only ever reacts to an EnemyWeapon component that already exists on some entity.
        systems.add(new EnemyWeaponSystem());
        if (levelId != null) {
            systems.add(new BossSystem(levelId));
        }
        systems.add(new LifetimeSystem());
        systems.add(new CollisionSystem());
        systems.add(new DamageSystem());
        systems.add(new PickupSystem());
        systems.add(new ScoreSystem());
        systems.add(new CleanupSystem());
        return SystemPipeline.of(systems.toArray(new GameSystem[0]));
    }

    private static String requireLevelId(String levelId) {
        if (levelId == null || levelId.isEmpty()) {
            throw new IllegalArgumentException("a level id is needed to build the spawn timeline");
        }
        return levelId;
    }

    /**
     * Creates the player's ship so a run never starts with an empty world — respawn already relies
     * on this entity never being destroyed, so it has to exist from tick zero, not from whenever
     * presentation gets around to creating it.
     */
    private static void spawnPlayer(World world, BalanceValues balance) {
        int player = world.createEntity();
        world.transforms().set(player, new Transform(balance.playerStartX(), balance.playerStartY()));
        world.motions().set(player, new Motion(0f, 0f));
        world.colliders().set(player, new Collider(PLAYER_COLLIDER_RADIUS, CollisionLayer.PLAYER));
        world.sprites().set(player, new Sprite(PLAYER_SPRITE));
        world.players().set(player,
            new Player(balance.initialLives(), balance.initialBombs(), PLAYER_INITIAL_SHOT_LEVEL));
        world.weapons().set(player, new Weapon());
        world.bombStates().set(player, new BombState());
    }

    /**
     * The world behind the view. Package-private on purpose: the tests of this package assert
     * against the simulation state, and nothing outside the core can reach it.
     */
    World world() {
        return world;
    }
}
