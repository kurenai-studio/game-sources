package dev.luchoc.littlespaceship.core.domain.content;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.EnemyWeapon;
import dev.luchoc.littlespaceship.core.domain.component.Health;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.ScoreValue;
import dev.luchoc.littlespaceship.core.domain.component.Sprite;
import dev.luchoc.littlespaceship.core.domain.component.Trajectory;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.MapComponentSpec;
import dev.luchoc.littlespaceship.core.port.SimpleTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class ComponentFactoryRegistryTest {

    @Test
    @DisplayName("the default registry attaches motion from a resolved trajectory")
    void motionFactoryResolvesTrajectory() {
        TestContent content = new TestContent()
            .withTrajectory(new SimpleTrajectoryDefinition("slow-descent", 0f, -18f));
        World world = worldOf(content);
        int entity = world.createEntity();

        ComponentFactoryRegistry.withDefaults().attach(world, entity,
            new MapComponentSpec("motion", Map.of("trajectory", "slow-descent")));

        Motion motion = world.motions().get(entity);
        assertEquals(0f, motion.vx);
        assertEquals(-18f, motion.vy);
        Trajectory trajectory = world.trajectories().get(entity);
        assertEquals("slow-descent", trajectory.trajectoryId, "so MotionSystem can re-evaluate it per tick, issue #164");
        assertEquals(0f, trajectory.elapsed);
    }

    @Test
    @DisplayName("the default registry attaches a collider on the enemy layer, fragile flag included")
    void colliderFactoryAttachesEnemyCollider() {
        World world = worldOf(new TestContent());
        int entity = world.createEntity();

        ComponentFactoryRegistry.withDefaults().attach(world, entity,
            new MapComponentSpec("collider", Map.of("radius", 5.5f, "fragile", true)));

        Collider collider = world.colliders().get(entity);
        assertEquals(5.5f, collider.radius);
        assertEquals(CollisionLayer.ENEMY, collider.layer);
        assertTrue(collider.fragile);
    }

    @Test
    @DisplayName("collider fragile can be explicitly false, matching a tank or a carrier")
    void colliderFragileCanBeFalse() {
        World world = worldOf(new TestContent());
        int entity = world.createEntity();

        ComponentFactoryRegistry.withDefaults().attach(world, entity,
            new MapComponentSpec("collider", Map.of("radius", 10.5f, "fragile", false)));

        assertEquals(false, world.colliders().get(entity).fragile);
    }

    @Test
    @DisplayName("collider fragile is required, not defaulted — omitting it fails instead of "
        + "silently producing a weak enemy that survives ramming the player")
    void colliderFragileIsRequired() {
        World world = worldOf(new TestContent());
        int entity = world.createEntity();

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> ComponentFactoryRegistry.withDefaults().attach(world, entity,
                new MapComponentSpec("collider", Map.of("radius", 10.5f))));

        assertTrue(e.getMessage().contains("fragile"));
    }

    @Test
    @DisplayName("the default registry attaches a sprite from its content id")
    void spriteFactoryAttachesSprite() {
        World world = worldOf(new TestContent());
        int entity = world.createEntity();

        ComponentFactoryRegistry.withDefaults().attach(world, entity,
            new MapComponentSpec("sprite", Map.of("id", "enemy-tank")));

        Sprite sprite = world.sprites().get(entity);
        assertEquals("enemy-tank", sprite.id.value());
    }

    @Test
    @DisplayName("the default registry attaches a scoreValue, rounded to an int")
    void scoreValueFactoryAttachesPoints() {
        World world = worldOf(new TestContent());
        int entity = world.createEntity();

        ComponentFactoryRegistry.withDefaults().attach(world, entity,
            new MapComponentSpec("scoreValue", Map.of("points", 500f)));

        ScoreValue scoreValue = world.scoreValues().get(entity);
        assertEquals(500, scoreValue.points);
    }

    @Test
    @DisplayName("the default registry attaches health, rounded to an int, matching the architecture's "
        + "own tank example")
    void healthFactoryAttachesPoints() {
        World world = worldOf(new TestContent());
        int entity = world.createEntity();

        ComponentFactoryRegistry.withDefaults().attach(world, entity,
            new MapComponentSpec("health", Map.of("points", 40f)));

        Health health = world.healths().get(entity);
        assertEquals(40, health.points);
    }

    @Test
    @DisplayName("the default registry attaches a spawner, for the heavy carrier's periodic spawn")
    void spawnerFactoryAttachesFields() {
        World world = worldOf(new TestContent());
        int entity = world.createEntity();

        ComponentFactoryRegistry.withDefaults().attach(world, entity,
            new MapComponentSpec("spawner",
                Map.of("enemyId", "enemy-basic", "interval", 4f, "offsetX", 0f, "offsetY", -10f)));

        dev.luchoc.littlespaceship.core.domain.component.Spawner spawner = world.spawners().get(entity);
        assertEquals("enemy-basic", spawner.enemyId);
        assertEquals(4f, spawner.interval);
        assertEquals(0f, spawner.offsetX);
        assertEquals(-10f, spawner.offsetY);
    }

    @Test
    @DisplayName("the default registry attaches an enemy weapon, rate read as the cooldown in seconds")
    void weaponFactoryAttachesFields() {
        World world = worldOf(new TestContent());
        int entity = world.createEntity();

        ComponentFactoryRegistry.withDefaults().attach(world, entity,
            new MapComponentSpec("weapon",
                Map.of("rate", 2.2f, "pattern", "straight-single", "speed", 90f)));

        EnemyWeapon weapon = world.enemyWeapons().get(entity);
        assertEquals("straight-single", weapon.pattern);
        assertEquals(2.2f, weapon.cooldown);
        assertEquals(90f, weapon.projectileSpeed);
        assertEquals(2.2f, weapon.cooldownRemaining);
    }

    @Test
    @DisplayName("an explicit firstShotDelay seeds cooldownRemaining instead of the cooldown")
    void weaponFactoryReadsExplicitFirstShotDelay() {
        World world = worldOf(new TestContent());
        int entity = world.createEntity();

        ComponentFactoryRegistry.withDefaults().attach(world, entity,
            new MapComponentSpec("weapon",
                Map.of("rate", 2.2f, "pattern", "straight-single", "speed", 90f, "firstShotDelay", 0.5f)));

        EnemyWeapon weapon = world.enemyWeapons().get(entity);
        assertEquals(2.2f, weapon.cooldown);
        assertEquals(0.5f, weapon.cooldownRemaining);
    }

    @Test
    @DisplayName("an unregistered component name fails, naming it, instead of doing nothing silently")
    void unknownComponentFails() {
        World world = worldOf(new TestContent());
        int entity = world.createEntity();

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> ComponentFactoryRegistry.withDefaults().attach(world, entity,
                new MapComponentSpec("unknown-component", Map.of())));

        assertTrue(e.getMessage().contains("unknown-component"));
    }

    @Test
    @DisplayName("adding a component type is one registration, with no change to the lookup itself")
    void registeringANewFactoryWorks() {
        World world = worldOf(new TestContent());
        int entity = world.createEntity();
        ComponentFactoryRegistry registry = new ComponentFactoryRegistry()
            .register("marker", (w, e, spec) -> w.sprites().set(e,
                new Sprite(new dev.luchoc.littlespaceship.core.port.SpriteId("marker"))));

        registry.attach(world, entity, new MapComponentSpec("marker", Map.of()));

        assertEquals("marker", world.sprites().get(entity).id.value());
    }

    private static World worldOf(TestContent content) {
        return new World(content, new Rng(1), new GameEventQueue());
    }
}
