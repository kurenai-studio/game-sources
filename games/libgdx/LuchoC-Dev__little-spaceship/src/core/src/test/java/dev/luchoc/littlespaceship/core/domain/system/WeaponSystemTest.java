package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.Sprite;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.component.Weapon;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.SpriteId;
import dev.luchoc.littlespaceship.core.testsupport.TestBalance;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class WeaponSystemTest {

    private static final float STEP = 1f / 60f;

    private final TestBalance balance = new TestBalance();
    private final World world = new World(new TestContent(balance), new Rng(1), new GameEventQueue());
    private final WeaponSystem system = new WeaponSystem();

    @Test
    @DisplayName("holding fire creates the level's projectile count on the first tick")
    void firesOnFirstTickWhenFireIsHeld() {
        int player = spawnPlayer(1);
        InputFrame firing = new InputFrame(0f, 0f, true, false, false);

        system.update(world, STEP, firing);

        assertEquals(1, projectileCount(player));
    }

    @Test
    @DisplayName("releasing fire creates nothing")
    void doesNothingWithoutFire() {
        spawnPlayer(1);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(0, world.colliders().size());
    }

    @Test
    @DisplayName("a second shot within the cooldown does not fire again")
    void respectsTheCooldownBetweenVolleys() {
        int player = spawnPlayer(1);
        InputFrame firing = new InputFrame(0f, 0f, true, false, false);

        system.update(world, STEP, firing);
        int afterFirstShot = world.colliders().size();
        system.update(world, STEP, firing);

        assertEquals(afterFirstShot, world.colliders().size(),
            "the cooldown has not elapsed yet, so no second volley should fire");
    }

    @Test
    @DisplayName("once the cooldown elapses, holding fire produces a second volley")
    void firesAgainOnceTheCooldownElapses() {
        int player = spawnPlayer(1);
        InputFrame firing = new InputFrame(0f, 0f, true, false, false);
        system.update(world, STEP, firing);

        int ticksToWait = (int) Math.ceil(balance.weaponFireCooldown / STEP) + 1;
        for (int i = 0; i < ticksToWait; i++) {
            system.update(world, STEP, firing);
        }

        assertEquals(2, projectileCount(player));
    }

    @Test
    @DisplayName("the four weapon levels fire 1, 2, 3 and 5 projectiles")
    void projectileCountMatchesTheWeaponLevelTable() {
        assertEquals(1, projectilesFiredAtLevel(1));
        assertEquals(2, projectilesFiredAtLevel(2));
        assertEquals(3, projectilesFiredAtLevel(3));
        assertEquals(5, projectilesFiredAtLevel(4));
    }

    @Test
    @DisplayName("every projectile fired is on the player-projectile layer, moving away from the player")
    void projectilesAreOnThePlayerProjectileLayer() {
        int player = spawnPlayer(3);
        system.update(world, STEP, new InputFrame(0f, 0f, true, false, false));

        for (int i = 0; i < world.colliders().size(); i++) {
            int entity = world.colliders().entityAt(i);
            if (entity == player) {
                continue;
            }
            assertEquals(CollisionLayer.PLAYER_PROJECTILE, world.colliders().valueAt(i).layer);
            Motion motion = world.motions().get(entity);
            assertTrue(motion.vy > 0f, "a player projectile must move away from the player");
        }
    }

    @Test
    @DisplayName("does nothing when there is no player entity")
    void noPlayerIsHarmless() {
        system.update(world, STEP, new InputFrame(0f, 0f, true, false, false));

        assertEquals(0, world.colliders().size());
    }

    private int projectilesFiredAtLevel(int shotLevel) {
        World levelWorld = new World(new TestContent(balance), new Rng(1), new GameEventQueue());
        int player = levelWorld.createEntity();
        levelWorld.transforms().set(player, new Transform(100f, 50f));
        levelWorld.players().set(player, new Player(3, 2, shotLevel));
        levelWorld.weapons().set(player, new Weapon());
        levelWorld.sprites().set(player, new Sprite(new SpriteId("ship-basic")));

        new WeaponSystem().update(levelWorld, STEP, new InputFrame(0f, 0f, true, false, false));

        return levelWorld.colliders().size();
    }

    private int projectileCount(int player) {
        int count = 0;
        for (int i = 0; i < world.colliders().size(); i++) {
            if (world.colliders().entityAt(i) != player) {
                count++;
            }
        }
        return count;
    }

    private int spawnPlayer(int shotLevel) {
        int player = world.createEntity();
        world.transforms().set(player, new Transform(100f, 50f));
        world.players().set(player, new Player(3, 2, shotLevel));
        world.weapons().set(player, new Weapon());
        return player;
    }
}
