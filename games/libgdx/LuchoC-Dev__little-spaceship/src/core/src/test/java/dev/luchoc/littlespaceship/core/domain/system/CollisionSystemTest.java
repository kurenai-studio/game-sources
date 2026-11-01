package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.collision.CollisionHit;
import dev.luchoc.littlespaceship.core.domain.collision.CollisionPair;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class CollisionSystemTest {

    private static final float STEP = 1f / 60f;

    private final World world = new World(new TestContent(), new Rng(1), new GameEventQueue());
    private final CollisionSystem system = new CollisionSystem();

    @Test
    @DisplayName("an enemy overlapping the player is reported as enemy versus player")
    void detectsEnemyVersusPlayer() {
        int enemy = entity(0f, 0f, 3f, CollisionLayer.ENEMY);
        int player = playerEntity(4f, 0f, 3f);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(List.of(new CollisionHit(enemy, player, CollisionPair.ENEMY_VS_PLAYER)),
            world.collisionHits());
    }

    @Test
    @DisplayName("two circles farther apart than their combined radius do not overlap")
    void tooFarApartDoesNotOverlap() {
        entity(0f, 0f, 3f, CollisionLayer.ENEMY);
        playerEntity(100f, 0f, 3f);

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.collisionHits().isEmpty());
    }

    @Test
    @DisplayName("circles exactly touching count as overlapping")
    void exactlyTouchingOverlaps() {
        int enemy = entity(0f, 0f, 3f, CollisionLayer.ENEMY);
        int player = playerEntity(6f, 0f, 3f);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(List.of(new CollisionHit(enemy, player, CollisionPair.ENEMY_VS_PLAYER)),
            world.collisionHits());
    }

    @Test
    @DisplayName("an enemy projectile overlapping the player is reported as enemy projectile versus player")
    void detectsEnemyProjectileVersusPlayer() {
        int projectile = entity(0f, 0f, 2f, CollisionLayer.ENEMY_PROJECTILE);
        int player = playerEntity(3f, 0f, 2f);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(List.of(new CollisionHit(projectile, player, CollisionPair.ENEMY_PROJECTILE_VS_PLAYER)),
            world.collisionHits());
    }

    @Test
    @DisplayName("a player projectile overlapping an enemy is reported as player projectile versus enemy")
    void detectsPlayerProjectileVersusEnemy() {
        int projectile = entity(0f, 0f, 2f, CollisionLayer.PLAYER_PROJECTILE);
        int enemy = entity(3f, 0f, 2f, CollisionLayer.ENEMY);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(List.of(new CollisionHit(projectile, enemy, CollisionPair.PLAYER_PROJECTILE_VS_ENEMY)),
            world.collisionHits());
    }

    @Test
    @DisplayName("a pickup overlapping the player is reported as pickup versus player")
    void detectsPickupVersusPlayer() {
        int pickup = entity(0f, 0f, 2f, CollisionLayer.PICKUP);
        int player = playerEntity(3f, 0f, 2f);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(List.of(new CollisionHit(pickup, player, CollisionPair.PICKUP_VS_PLAYER)),
            world.collisionHits());
    }

    @Test
    @DisplayName("a pair not confirmed in the architecture is never reported, even when the circles overlap")
    void unconfirmedPairIsIgnored() {
        entity(0f, 0f, 3f, CollisionLayer.ENEMY);
        entity(0f, 0f, 3f, CollisionLayer.ENEMY_PROJECTILE);

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.collisionHits().isEmpty());
    }

    @Test
    @DisplayName("the previous tick's hits do not linger into one with nothing overlapping")
    void hitsDoNotLingerAcrossTicks() {
        entity(0f, 0f, 3f, CollisionLayer.ENEMY);
        int player = playerEntity(4f, 0f, 3f);
        system.update(world, STEP, InputFrame.IDLE);
        assertTrue(world.collisionHits().size() > 0);

        world.transforms().set(player, new Transform(1000f, 1000f));
        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.collisionHits().isEmpty());
    }

    @Test
    @DisplayName("an enemy already marked for destruction this tick produces no hit against the player")
    void markedEnemyProducesNoHit() {
        int enemy = entity(0f, 0f, 3f, CollisionLayer.ENEMY);
        playerEntity(4f, 0f, 3f);
        world.markForDestruction(enemy);

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.collisionHits().isEmpty(),
            "a bomb or LifetimeSystem marking this enemy earlier in the tick must stop it from "
                + "still hitting the player this same tick");
    }

    @Test
    @DisplayName("an enemy projectile already marked for destruction produces no hit against the player")
    void markedEnemyProjectileProducesNoHit() {
        int projectile = entity(0f, 0f, 2f, CollisionLayer.ENEMY_PROJECTILE);
        playerEntity(3f, 0f, 2f);
        world.markForDestruction(projectile);

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.collisionHits().isEmpty());
    }

    @Test
    @DisplayName("a marked player projectile or enemy produces no player-projectile-versus-enemy hit")
    void markedEitherSideOfTheManyAgainstManyPairProducesNoHit() {
        int markedProjectile = entity(0f, 0f, 2f, CollisionLayer.PLAYER_PROJECTILE);
        entity(3f, 0f, 2f, CollisionLayer.ENEMY);
        world.markForDestruction(markedProjectile);

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.collisionHits().isEmpty());
    }

    @Test
    @DisplayName("marking one candidate does not stop an unrelated, unmarked overlap from being reported")
    void markingOneEntityDoesNotSuppressOthers() {
        int markedEnemy = entity(0f, 0f, 3f, CollisionLayer.ENEMY);
        int unmarkedEnemy = entity(0f, 0f, 3f, CollisionLayer.ENEMY);
        int player = playerEntity(4f, 0f, 3f);
        world.markForDestruction(markedEnemy);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(List.of(new CollisionHit(unmarkedEnemy, player, CollisionPair.ENEMY_VS_PLAYER)),
            world.collisionHits());
    }

    private int entity(float x, float y, float radius, CollisionLayer layer) {
        int entity = world.createEntity();
        world.transforms().set(entity, new Transform(x, y));
        world.colliders().set(entity, new Collider(radius, layer));
        return entity;
    }

    /**
     * An entity on the {@link CollisionLayer#PLAYER} layer, with a {@link Player} component
     * attached too: {@link CollisionSystem} resolves the three "versus player" pairs through {@link
     * World#playerEntity()}, so a bare {@link CollisionLayer#PLAYER} collider with no {@link Player}
     * component would never be found.
     */
    private int playerEntity(float x, float y, float radius) {
        int entity = entity(x, y, radius, CollisionLayer.PLAYER);
        world.players().set(entity, new Player(3, 2, 1));
        return entity;
    }
}
