package dev.luchoc.littlespaceship.core.domain.content;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.EnemyWeapon;
import dev.luchoc.littlespaceship.core.domain.component.Health;
import dev.luchoc.littlespaceship.core.domain.component.Lifetime;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.ScoreValue;
import dev.luchoc.littlespaceship.core.domain.component.Spawner;
import dev.luchoc.littlespaceship.core.domain.component.Sprite;
import dev.luchoc.littlespaceship.core.domain.component.Trajectory;
import dev.luchoc.littlespaceship.core.port.ComponentSpec;
import dev.luchoc.littlespaceship.core.port.SpriteId;
import dev.luchoc.littlespaceship.core.port.TrajectoryDefinition;
import java.util.HashMap;
import java.util.Map;

/**
 * {@code name -> ComponentFactory}, so a new component type is one registration and no change to
 * {@code SpawnSystem} or to the loader in {@code game}.
 *
 * <p>Lookup is by exact name — the registry never iterates its map, so its own order of registration
 * carries no observable behaviour and cannot affect a replay.
 */
public final class ComponentFactoryRegistry {

    private final Map<String, ComponentFactory> factories = new HashMap<>();

    /**
     * Registers a factory under a name, replacing whatever was registered before it.
     *
     * @param name the component name this factory handles
     * @param factory what builds and attaches the component
     * @return this registry, so registrations can be chained
     */
    public ComponentFactoryRegistry register(String name, ComponentFactory factory) {
        if (name == null || name.isEmpty()) {
            throw new IllegalArgumentException("a component factory needs a name to register under");
        }
        if (factory == null) {
            throw new IllegalArgumentException("a component factory cannot be null");
        }
        factories.put(name, factory);
        return this;
    }

    /**
     * Looks up the factory for {@code spec.name()} and attaches its component to {@code entity}.
     *
     * @param world the world to attach into
     * @param entity the entity to attach to
     * @param spec the component to build
     * @throws IllegalArgumentException if no factory is registered for {@code spec.name()}
     */
    public void attach(World world, int entity, ComponentSpec spec) {
        ComponentFactory factory = factories.get(spec.name());
        if (factory == null) {
            throw new IllegalArgumentException(
                "no component factory registered for '" + spec.name() + "'");
        }
        factory.attach(world, entity, spec);
    }

    /**
     * Builds the registry with the factories the MVP's content needs: motion, collider, sprite,
     * scoreValue, health, spawner, weapon. {@code "health"} was added in phase 05, alongside the
     * systems ({@code WeaponSystem}, {@code BombSystem}) that consume it — {@code 12-architecture.md}
     * named the component and its {@code {"points": N}} shape from the start, but no phase had it as
     * a task until the gap was caught in review. {@code "spawner"} was added in phase 07, for the
     * same reason: named in {@code 12-architecture.md}'s component table from the start, built only
     * once the strong encounter (two heavy carriers) needed the periodic spawn it names. {@code
     * "weapon"} — a per-archetype firing pattern for enemies — was the same kind of gap, closed once
     * {@code enemy-shooter} needed to actually shoot: no enemy fired at all before this, per {@code
     * 08-decisions-and-open-items.md}. The boss does not go through this registry — see {@code
     * BossSystem} — since its fire is a fixed state machine, not an archetype component. {@code
     * "lifetime"} was added for issue #84: an archetype's maximum time to live, expressed as data
     * rather than as a constant, and optional per archetype — an entity with no {@code "lifetime"}
     * spec relies on the safety box alone, exactly like every archetype does today.
     *
     * @return a registry ready to attach the MVP's archetypes
     */
    public static ComponentFactoryRegistry withDefaults() {
        return new ComponentFactoryRegistry()
            .register("motion", ComponentFactoryRegistry::attachMotion)
            .register("collider", ComponentFactoryRegistry::attachCollider)
            .register("sprite", ComponentFactoryRegistry::attachSprite)
            .register("scoreValue", ComponentFactoryRegistry::attachScoreValue)
            .register("health", ComponentFactoryRegistry::attachHealth)
            .register("spawner", ComponentFactoryRegistry::attachSpawner)
            .register("weapon", ComponentFactoryRegistry::attachEnemyWeapon)
            .register("lifetime", ComponentFactoryRegistry::attachLifetime);
    }

    /**
     * Resolves the {@code "trajectory"} field against {@link World#content()}, attaches its velocity
     * at elapsed time zero, and attaches a {@link Trajectory} component naming the same id — this
     * archetype's default shape, before {@code SpawnSystem} applies a per-spawn-event override, per
     * issue #164. Trajectories carry the whole vector on purpose — see {@link TrajectoryDefinition} —
     * so there is no per-archetype speed override to apply here.
     *
     * <p>The {@link Trajectory} is attached for every kind, {@code constant} included: {@code
     * MotionSystem} re-evaluates it every tick regardless of kind, and a {@code constant} shape's
     * {@code verticalVelocityAt} returns the same value it always has, so the result is identical to
     * the one-time snapshot this factory produced before {@link Trajectory} existed.
     */
    private static void attachMotion(World world, int entity, ComponentSpec spec) {
        String trajectoryId = spec.text("trajectory");
        attachTrajectory(world, entity, trajectoryId);
    }

    /**
     * Resolves {@code trajectoryId} against {@link World#content()}, attaches its velocity at
     * elapsed time zero into {@link Motion}, and attaches a {@link Trajectory} naming it so {@code
     * MotionSystem} can keep re-evaluating it. Shared between {@link #attachMotion} (the archetype's
     * default) and {@code SpawnSystem} (a spawn event's override, issue #164) so both go through the
     * exact same resolution.
     */
    public static void attachTrajectory(World world, int entity, String trajectoryId) {
        TrajectoryDefinition trajectory = world.content().trajectory(trajectoryId);
        world.motions().set(entity, new Motion(trajectory.vx(), trajectory.vy()));
        world.trajectories().set(entity, new Trajectory(trajectoryId));
    }

    /**
     * Every archetype spawned through this registry is an enemy — the content pipeline does not
     * spawn pickups or structures yet — so the layer is fixed here rather than read from a field
     * that would always carry the same value.
     *
     * <p>{@code "fragile"} is required, not defaulted. Four of the level 1 roster's six archetypes
     * are fragile per {@code 02-mvp-functional-spec.md}, so a false default would have been wrong
     * for the majority and would have silently let a weak enemy survive ramming the player whenever
     * content simply omitted the field. Requiring it forces every archetype's collider to say which
     * side of the crash rule it is on.
     */
    private static void attachCollider(World world, int entity, ComponentSpec spec) {
        float radius = spec.number("radius");
        boolean fragile = spec.flag("fragile");
        world.colliders().set(entity, new Collider(radius, CollisionLayer.ENEMY, fragile));
    }

    private static void attachSprite(World world, int entity, ComponentSpec spec) {
        String id = spec.text("id");
        world.sprites().set(entity, new Sprite(new SpriteId(id)));
    }

    private static void attachScoreValue(World world, int entity, ComponentSpec spec) {
        float points = spec.number("points");
        world.scoreValues().set(entity, new ScoreValue(Math.round(points)));
    }

    /**
     * {@code {"points": 40}}, exactly {@code 12-architecture.md}'s own example for a tank. That
     * {@code 40} is illustrative there, not a decided balance value — see {@link Health}'s javadoc.
     */
    private static void attachHealth(World world, int entity, ComponentSpec spec) {
        float points = spec.number("points");
        world.healths().set(entity, new Health(Math.round(points)));
    }

    /**
     * Reads which archetype to spawn, how often, and at what offset from the holder — the exact
     * fields {@link Spawner}'s constructor needs, so {@code level-designer} can tune the carrier's
     * encounter (interval, offset, even a different spawned archetype) purely in content.
     */
    private static void attachSpawner(World world, int entity, ComponentSpec spec) {
        String enemyId = spec.text("enemyId");
        float interval = spec.number("interval");
        float offsetX = spec.number("offsetX");
        float offsetY = spec.number("offsetY");
        world.spawners().set(entity, new Spawner(enemyId, interval, offsetX, offsetY));
    }

    /**
     * Reads the shot shape, the cooldown between shots, the projectile's speed and, optionally, the
     * delay before the first shot — the four fields {@link EnemyWeapon}'s constructor needs. {@code
     * "rate"} is the field name {@code 12-architecture.md}'s own example uses for the cooldown, kept
     * here for consistency with that document even though it reads as seconds between shots, not shots
     * per second — the same quantity {@code Weapon#cooldownRemaining} counts down from. {@code "speed"}
     * has no equivalent in that example: unlike {@code "motion"}, whose velocity is fully described by
     * a named {@code TrajectoryDefinition}, nothing else in the content pipeline yet carries a
     * projectile's speed for an enemy, so it is a plain required number here.
     *
     * <p>{@code "firstShotDelay"} is optional and defaults to the cooldown, matching {@link
     * EnemyWeapon}'s own three-argument constructor: content that predates this field keeps behaving
     * exactly as it did.
     */
    private static void attachEnemyWeapon(World world, int entity, ComponentSpec spec) {
        String pattern = spec.text("pattern");
        float cooldown = spec.number("rate");
        float speed = spec.number("speed");
        float firstShotDelay = spec.numberOr("firstShotDelay", cooldown);
        world.enemyWeapons().set(entity, new EnemyWeapon(pattern, cooldown, speed, firstShotDelay));
    }

    /**
     * Reads the one field {@link Lifetime}'s constructor needs. Required, not defaulted, like every
     * other numeric field this registry reads for a component an archetype opts into: the field
     * exists at all only for archetypes that declare a {@code "lifetime"} spec.
     */
    private static void attachLifetime(World world, int entity, ComponentSpec spec) {
        float seconds = spec.number("seconds");
        world.lifetimes().set(entity, new Lifetime(seconds));
    }
}
