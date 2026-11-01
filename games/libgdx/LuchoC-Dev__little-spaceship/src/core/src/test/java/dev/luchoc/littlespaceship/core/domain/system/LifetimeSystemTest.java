package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.Drop;
import dev.luchoc.littlespaceship.core.domain.component.Lifetime;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.ScoreValue;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class LifetimeSystemTest {

    private static final float STEP = 1f / 60f;

    private final World world = new World(new TestContent(), new Rng(1), new GameEventQueue());
    private final LifetimeSystem system = new LifetimeSystem();

    @Test
    @DisplayName("a player projectile still inside the playfield is not marked for destruction")
    void keepsAProjectileInsideThePlayfield() {
        int projectile = projectile(100f, 150f);

        system.update(world, STEP, InputFrame.IDLE);

        assertFalse(world.pendingDestruction().contains(projectile));
    }

    @Test
    @DisplayName("a player projectile well past the top of the playfield is expired")
    void expiresAProjectileAboveThePlayfield() {
        int projectile = projectile(100f, SpawnSystem.PLAYFIELD_HEIGHT + 100f);

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.pendingDestruction().contains(projectile));
    }

    @Test
    @DisplayName("a pickup still inside the playfield is not marked for destruction")
    void keepsAPickupInsideThePlayfield() {
        int pickup = pickup(100f, 150f);

        system.update(world, STEP, InputFrame.IDLE);

        assertFalse(world.pendingDestruction().contains(pickup));
    }

    @Test
    @DisplayName("a pickup that has fallen past the bottom of the playfield is expired")
    void expiresAPickupThatFellPastTheBottom() {
        int pickup = pickup(100f, -100f);

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.pendingDestruction().contains(pickup));
    }

    @Test
    @DisplayName("an enemy well inside the playfield is never touched, with or without a lifetime")
    void keepsAnEnemyInsideThePlayfield() {
        int withoutLifetime = enemy(100f, 150f, 4f);
        int withLifetime = enemy(60f, 150f, 4f);
        world.lifetimes().set(withLifetime, new Lifetime(0.5f));

        for (int tick = 0; tick < 120; tick++) {
            system.update(world, STEP, InputFrame.IDLE);
        }

        assertFalse(world.pendingDestruction().contains(withoutLifetime));
        assertFalse(world.pendingDestruction().contains(withLifetime));
    }

    @Test
    @DisplayName("an enemy with no lifetime, merely off the playfield, is not touched by the timer path")
    void anEnemyWithNoLifetimeIsNotExpiredByPosition() {
        int enemy = enemy(100f, -50f, 4f);

        system.update(world, STEP, InputFrame.IDLE);

        assertFalse(world.pendingDestruction().contains(enemy));
    }

    @Test
    @DisplayName("an enemy's lifetime expiring while it is still on screen leaves it alone")
    void anExpiredLifetimeNeverRemovesAVisibleEnemy() {
        int enemy = enemy(100f, 150f, 4f);
        world.lifetimes().set(enemy, new Lifetime(0.01f));

        system.update(world, STEP, InputFrame.IDLE);
        system.update(world, STEP, InputFrame.IDLE);

        assertFalse(world.pendingDestruction().contains(enemy),
            "the lifetime expired but the enemy is still visible, so it must wait");
    }

    @Test
    @DisplayName("an enemy's lifetime expiring once it is off screen removes it")
    void anExpiredLifetimeRemovesAnEnemyThatHasLeft() {
        int enemy = enemy(100f, -50f, 4f);
        world.lifetimes().set(enemy, new Lifetime(0.01f));

        system.update(world, STEP, InputFrame.IDLE);
        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.pendingDestruction().contains(enemy));
    }

    @Test
    @DisplayName("the safety box removes an enemy far outside the playfield, with no lifetime at all")
    void safetyBoxRemovesAnEnemyWithNoLifetime() {
        int enemy = enemy(100f, SpawnSystem.PLAYFIELD_HEIGHT + LifetimeSystem.SAFETY_MARGIN + 50f, 4f);

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.pendingDestruction().contains(enemy));
    }

    @Test
    @DisplayName("the safety box clears the worst-case spawn: column-3's 44-unit spread on enemy-carrier's 15-unit radius")
    void safetyBoxClearsTheWorstCaseSpawn() {
        float carrierRadius = 15f;
        float columnThreeSpread = 44f;
        float worstCaseSpawnY = SpawnSystem.PLAYFIELD_HEIGHT + carrierRadius + columnThreeSpread;
        int enemy = enemy(100f, worstCaseSpawnY, carrierRadius);

        system.update(world, STEP, InputFrame.IDLE);

        assertFalse(world.pendingDestruction().contains(enemy),
            "a legitimate spawn must never be destroyed by the safety box");
    }

    @Test
    @DisplayName("an escaped enemy has its ScoreValue, Drop and Collider stripped before being marked")
    void escapedEnemyIsStrippedOfWhatWouldMakeItCountAsAKill() {
        int enemy = enemy(100f, SpawnSystem.PLAYFIELD_HEIGHT + LifetimeSystem.SAFETY_MARGIN + 50f, 4f);
        world.scoreValues().set(enemy, new ScoreValue(500));
        world.drops().set(enemy, new Drop("shield"));

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.pendingDestruction().contains(enemy));
        assertFalse(world.scoreValues().has(enemy), "an escaped enemy must not keep its score value");
        assertFalse(world.drops().has(enemy), "an escaped enemy must not keep its drop");
        assertFalse(world.colliders().has(enemy), "an escaped enemy must not keep its collider");
    }

    @Test
    @DisplayName("an enemy that leaves the playfield never scores, drops, or emits EnemyDestroyed")
    void anEscapedEnemyGivesNothing() {
        int player = world.createEntity();
        world.players().set(player, new Player(3, 1, 1));
        int enemy = enemy(100f, SpawnSystem.PLAYFIELD_HEIGHT + LifetimeSystem.SAFETY_MARGIN + 50f, 4f);
        world.scoreValues().set(enemy, new ScoreValue(500));
        world.drops().set(enemy, new Drop("shield"));

        system.update(world, STEP, InputFrame.IDLE);
        new ScoreSystem().update(world, STEP, InputFrame.IDLE);
        new CleanupSystem().update(world, STEP, InputFrame.IDLE);

        assertFalse(world.isAlive(enemy), "the enemy must still leave the simulation");
        assertEquals(0, world.players().get(player).score,
            "escaping must never award the score the player did not earn");
        assertEquals(0, world.pickups().size(), "escaping must never drop anything");
        assertEquals(0, world.events().pendingCount(),
            "escaping off screen must never emit EnemyDestroyed, or AudioDirector plays an explosion "
                + "for an enemy nobody hit");
    }

    private int enemy(float x, float y, float radius) {
        int entity = world.createEntity();
        world.transforms().set(entity, new Transform(x, y));
        world.colliders().set(entity, new Collider(radius, CollisionLayer.ENEMY));
        return entity;
    }

    private int projectile(float x, float y) {
        int entity = world.createEntity();
        world.transforms().set(entity, new Transform(x, y));
        world.colliders().set(entity, new Collider(1.5f, CollisionLayer.PLAYER_PROJECTILE));
        return entity;
    }

    private int pickup(float x, float y) {
        int entity = world.createEntity();
        world.transforms().set(entity, new Transform(x, y));
        world.colliders().set(entity, new Collider(6f, CollisionLayer.PICKUP));
        return entity;
    }
}
