package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.Drop;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Pickup;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.event.EnemyDestroyed;
import dev.luchoc.littlespaceship.core.domain.event.GameEvent;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class CleanupSystemTest {

    private static final float STEP = 1f / 60f;

    private final World world = new World(new TestContent(), new Rng(1), new GameEventQueue());
    private final CleanupSystem system = new CleanupSystem();

    @Test
    @DisplayName("destroys every entity marked this tick and forgets the list")
    void destroysMarkedEntities() {
        int marked = world.createEntity();
        int untouched = world.createEntity();
        world.markForDestruction(marked);

        system.update(world, STEP, InputFrame.IDLE);

        assertFalse(world.isAlive(marked));
        assertTrue(world.isAlive(untouched));
        assertTrue(world.pendingDestruction().isEmpty());
    }

    @Test
    @DisplayName("marking the same entity twice destroys it once, harmlessly")
    void markingTwiceIsHarmless() {
        int entity = world.createEntity();
        world.markForDestruction(entity);
        world.markForDestruction(entity);

        system.update(world, STEP, InputFrame.IDLE);

        assertFalse(world.isAlive(entity));
        assertEquals(0, world.entityCount());
    }

    @Test
    @DisplayName("nothing is destroyed when nothing was marked")
    void nothingMarkedIsHarmless() {
        int entity = world.createEntity();

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.isAlive(entity));
    }

    @Test
    @DisplayName("a destroyed entity with a drop spawns a pickup at its last position")
    void spawnsAPickupFromADrop() {
        int enemy = world.createEntity();
        world.transforms().set(enemy, new Transform(77f, 133f));
        world.drops().set(enemy, new Drop("shield"));
        world.markForDestruction(enemy);

        system.update(world, STEP, InputFrame.IDLE);

        int pickup = findPickup();
        Pickup component = world.pickups().get(pickup);
        assertEquals("shield", component.kind);
        Transform transform = world.transforms().get(pickup);
        assertEquals(77f, transform.x);
        assertEquals(133f, transform.y);
        assertEquals(CollisionLayer.PICKUP, world.colliders().get(pickup).layer);
    }

    @Test
    @DisplayName("a spawned pickup falls, at the speed read from balance")
    void spawnedPickupFalls() {
        int enemy = world.createEntity();
        world.transforms().set(enemy, new Transform(77f, 133f));
        world.drops().set(enemy, new Drop("shield"));
        world.markForDestruction(enemy);

        system.update(world, STEP, InputFrame.IDLE);

        int pickup = findPickup();
        Motion motion = world.motions().get(pickup);
        assertEquals(0f, motion.vx, "a pickup falls straight down, with no horizontal drift");
        assertEquals(-world.content().balance().pickupFallSpeed(), motion.vy,
            "a pickup's fall speed comes from balance, negated since Transform.y grows upward");
    }

    @Test
    @DisplayName("a destroyed entity with no drop spawns nothing")
    void noDropSpawnsNothing() {
        int enemy = world.createEntity();
        world.transforms().set(enemy, new Transform(0f, 0f));
        world.markForDestruction(enemy);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(0, world.pickups().size());
    }

    @Test
    @DisplayName("a drop with no transform spawns nothing, instead of crashing the tick")
    void dropWithNoTransformIsHarmless() {
        int enemy = world.createEntity();
        world.drops().set(enemy, new Drop("shield"));
        world.markForDestruction(enemy);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(0, world.pickups().size());
        assertNull(world.transforms().get(enemy));
    }

    @Test
    @DisplayName("destroying an ENEMY-layer entity emits EnemyDestroyed at its last position")
    void emitsEnemyDestroyedForAnEnemy() {
        int enemy = world.createEntity();
        world.transforms().set(enemy, new Transform(42f, 99f));
        world.colliders().set(enemy, new Collider(5f, CollisionLayer.ENEMY));
        world.markForDestruction(enemy);

        system.update(world, STEP, InputFrame.IDLE);

        List<GameEvent> events = drain();
        assertEquals(1, events.size());
        EnemyDestroyed event = (EnemyDestroyed) events.get(0);
        assertEquals(42f, event.x());
        assertEquals(99f, event.y());
    }

    @Test
    @DisplayName("destroying a non-ENEMY-layer entity emits nothing")
    void emitsNothingForOtherLayers() {
        int projectile = world.createEntity();
        world.transforms().set(projectile, new Transform(0f, 0f));
        world.colliders().set(projectile, new Collider(1.5f, CollisionLayer.PLAYER_PROJECTILE));
        world.markForDestruction(projectile);

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(drain().isEmpty());
    }

    @Test
    @DisplayName("destroying an ENEMY-layer entity with no collider left to read emits nothing")
    void emitsNothingWithNoCollider() {
        int enemy = world.createEntity();
        world.transforms().set(enemy, new Transform(0f, 0f));
        world.markForDestruction(enemy);

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(drain().isEmpty());
    }

    private List<GameEvent> drain() {
        List<GameEvent> collected = new ArrayList<>();
        world.events().drainTo(collected::add);
        return collected;
    }

    private int findPickup() {
        assertEquals(1, world.pickups().size(), "exactly one pickup should have spawned");
        return world.pickups().entityAt(0);
    }
}
