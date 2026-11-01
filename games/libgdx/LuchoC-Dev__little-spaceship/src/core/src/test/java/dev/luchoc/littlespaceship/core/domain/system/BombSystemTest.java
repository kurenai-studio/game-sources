package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.Health;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.testsupport.TestBalance;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class BombSystemTest {

    private static final float STEP = 1f / 60f;
    private static final InputFrame BOMB_INPUT = new InputFrame(0f, 0f, false, false, true);
    private static final InputFrame IDLE_INPUT = new InputFrame(0f, 0f, false, false, false);

    /** Well inside the 208x270 playfield, for entities that should count as on screen. */
    private static final float ON_SCREEN_Y = 100f;

    private final TestBalance balance = new TestBalance();
    private final World world = new World(new TestContent(balance), new Rng(1), new GameEventQueue());
    private final BombSystem system = new BombSystem();

    @Test
    @DisplayName("clears fragile enemies and enemy projectiles, spends one bomb")
    void detonatesAndSpendsABomb() {
        int player = spawnPlayer(2);
        int fragileEnemy = enemy(true, ON_SCREEN_Y);
        int enemyProjectile = enemyProjectile(ON_SCREEN_Y);

        system.update(world, STEP, BOMB_INPUT);

        assertTrue(world.pendingDestruction().contains(fragileEnemy));
        assertTrue(world.pendingDestruction().contains(enemyProjectile));
        assertEquals(1, world.players().get(player).bombs);
    }

    @Test
    @DisplayName("a fragile enemy is destroyed outright by the bomb even with health left")
    void fragileEnemyIsDestroyedRegardlessOfHealth() {
        spawnPlayer(2);
        int enemy = enemy(true, ON_SCREEN_Y);
        world.healths().set(enemy, new Health(1000));

        system.update(world, STEP, BOMB_INPUT);

        assertTrue(world.pendingDestruction().contains(enemy),
            "fragile is a whole-body outcome, independent of Health");
    }

    @Test
    @DisplayName("a resistant enemy with enough health survives the bomb, losing bombDamage points")
    void resistantEnemyWithEnoughHealthSurvives() {
        spawnPlayer(2);
        int tank = enemy(false, ON_SCREEN_Y);
        Health health = new Health(balance.bombDamage + 10);
        world.healths().set(tank, health);

        system.update(world, STEP, BOMB_INPUT);

        assertFalse(world.pendingDestruction().contains(tank));
        assertEquals(10, health.points);
    }

    @Test
    @DisplayName("a resistant enemy whose health is exhausted by the bomb is destroyed")
    void resistantEnemyDestroyedOnceHealthIsExhausted() {
        spawnPlayer(2);
        int tank = enemy(false, ON_SCREEN_Y);
        world.healths().set(tank, new Health(balance.bombDamage));

        system.update(world, STEP, BOMB_INPUT);

        assertTrue(world.pendingDestruction().contains(tank));
    }

    @Test
    @DisplayName("a resistant enemy with no health is destroyed outright, the same as one point")
    void resistantEnemyWithNoHealthIsDestroyed() {
        spawnPlayer(2);
        int tank = enemy(false, ON_SCREEN_Y);

        system.update(world, STEP, BOMB_INPUT);

        assertTrue(world.pendingDestruction().contains(tank),
            "no Health is shorthand for one point, not a second rule the bomb treats differently");
    }

    @Test
    @DisplayName("an enemy above the playfield, not yet on screen, is untouched by the bomb")
    void enemyAbovePlayfieldIsUntouched() {
        spawnPlayer(2);
        int notYetVisible = enemy(true, SpawnSystem.PLAYFIELD_HEIGHT + 5.5f);

        system.update(world, STEP, BOMB_INPUT);

        assertFalse(world.pendingDestruction().contains(notYetVisible));
    }

    @Test
    @DisplayName("an enemy projectile above the playfield is untouched by the bomb")
    void enemyProjectileAbovePlayfieldIsUntouched() {
        spawnPlayer(2);
        int notYetVisible = enemyProjectile(SpawnSystem.PLAYFIELD_HEIGHT + 5.5f);

        system.update(world, STEP, BOMB_INPUT);

        assertFalse(world.pendingDestruction().contains(notYetVisible));
    }

    @Test
    @DisplayName("an enemy exactly on the playfield's edge counts as on screen")
    void enemyExactlyOnTheEdgeCountsAsOnScreen() {
        spawnPlayer(2);
        int atTheEdge = enemy(true, SpawnSystem.PLAYFIELD_HEIGHT);

        system.update(world, STEP, BOMB_INPUT);

        assertTrue(world.pendingDestruction().contains(atTheEdge));
    }

    @Test
    @DisplayName("an enemy with no transform is untouched instead of crashing the tick")
    void enemyWithNoTransformIsUntouched() {
        spawnPlayer(2);
        int noTransform = world.createEntity();
        world.colliders().set(noTransform, new Collider(5f, CollisionLayer.ENEMY, true));

        system.update(world, STEP, BOMB_INPUT);

        assertFalse(world.pendingDestruction().contains(noTransform));
    }

    @Test
    @DisplayName("holding the bomb control across two ticks spends only one charge")
    void holdingAcrossTwoTicksSpendsOnlyOneCharge() {
        int player = spawnPlayer(2);
        int firstEnemy = enemy(true, ON_SCREEN_Y);

        system.update(world, STEP, BOMB_INPUT);
        system.update(world, STEP, BOMB_INPUT);

        assertEquals(1, world.players().get(player).bombs,
            "GameLoop feeds the same InputFrame to every tick of one frame; a held press must not "
                + "spend a second charge on the tick after the one that already spent it");
        assertTrue(world.pendingDestruction().contains(firstEnemy));
    }

    @Test
    @DisplayName("releasing and pressing again spends a second charge")
    void releaseThenPressSpendsASecondCharge() {
        int player = spawnPlayer(2);

        system.update(world, STEP, BOMB_INPUT);
        system.update(world, STEP, IDLE_INPUT);
        system.update(world, STEP, BOMB_INPUT);

        assertEquals(0, world.players().get(player).bombs);
    }

    @Test
    @DisplayName("with no bomb requested, nothing happens")
    void doesNothingWithoutTheBombInput() {
        int player = spawnPlayer(2);
        int fragileEnemy = enemy(true, ON_SCREEN_Y);

        system.update(world, STEP, InputFrame.IDLE);

        assertFalse(world.pendingDestruction().contains(fragileEnemy));
        assertEquals(2, world.players().get(player).bombs);
    }

    @Test
    @DisplayName("with no bomb charge left, requesting the bomb does nothing")
    void doesNothingWithNoBombsLeft() {
        int player = spawnPlayer(0);
        int fragileEnemy = enemy(true, ON_SCREEN_Y);

        system.update(world, STEP, BOMB_INPUT);

        assertFalse(world.pendingDestruction().contains(fragileEnemy));
        assertEquals(0, world.players().get(player).bombs);
    }

    @Test
    @DisplayName("does nothing when there is no player entity")
    void noPlayerIsHarmless() {
        int fragileEnemy = enemy(true, ON_SCREEN_Y);

        system.update(world, STEP, BOMB_INPUT);

        assertFalse(world.pendingDestruction().contains(fragileEnemy));
    }

    private int spawnPlayer(int bombs) {
        int player = world.createEntity();
        world.transforms().set(player, new Transform(100f, 50f));
        world.players().set(player, new Player(3, bombs, 1));
        return player;
    }

    private int enemy(boolean fragile, float y) {
        int entity = world.createEntity();
        world.transforms().set(entity, new Transform(100f, y));
        world.colliders().set(entity, new Collider(5f, CollisionLayer.ENEMY, fragile));
        return entity;
    }

    private int enemyProjectile(float y) {
        int entity = world.createEntity();
        world.transforms().set(entity, new Transform(100f, y));
        world.colliders().set(entity, new Collider(2f, CollisionLayer.ENEMY_PROJECTILE));
        return entity;
    }
}
