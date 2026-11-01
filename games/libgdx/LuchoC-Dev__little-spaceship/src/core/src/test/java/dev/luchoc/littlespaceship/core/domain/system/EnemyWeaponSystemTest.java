package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.EnemyWeapon;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * {@code EnemyWeaponSystem} against content built inline, the same reasoning {@code
 * SpawnerSystemTest} states for the system it mirrors.
 */
class EnemyWeaponSystemTest {

    private final World world = new World(new TestContent(), new Rng(1), new GameEventQueue());
    private final EnemyWeaponSystem system = new EnemyWeaponSystem();

    @Test
    @DisplayName("does not fire before its cooldown has elapsed")
    void doesNotFireBeforeCooldown() {
        shooterAt(50f, 100f, 2f, 90f);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(1, world.entityCount());
    }

    @Test
    @DisplayName("fires straight down once its cooldown elapses, from its own position")
    void firesOnceCooldownElapses() {
        shooterAt(50f, 100f, 2f, 90f);

        system.update(world, 2f, InputFrame.IDLE);

        assertEquals(2, world.entityCount());
        int projectile = projectileEntity();
        Transform transform = world.transforms().get(projectile);
        assertEquals(50f, transform.x);
        assertEquals(100f, transform.y);
        Motion motion = world.motions().get(projectile);
        assertEquals(0f, motion.vx);
        assertEquals(-90f, motion.vy);
        Collider collider = world.colliders().get(projectile);
        assertEquals(CollisionLayer.ENEMY_PROJECTILE, collider.layer);
    }

    @Test
    @DisplayName("the cooldown resets to its full value, not to zero, after firing")
    void cooldownResetsToFullValue() {
        int shooter = shooterAt(0f, 0f, 2f, 90f);

        system.update(world, 2f, InputFrame.IDLE);

        assertEquals(2f, world.enemyWeapons().get(shooter).cooldownRemaining, 0.0001f);
    }

    @Test
    @DisplayName("keeps firing every cooldown, one shot per due tick")
    void firesRepeatedly() {
        shooterAt(0f, 0f, 1f, 90f);

        // Same reasoning as SpawnerSystemTest.spawnsRepeatedly: a little over 5s at 1/60s ticks
        // crosses five cooldown boundaries and comfortably avoids a sixth this early.
        for (int i = 0; i < 305; i++) {
            system.update(world, 1f / 60f, InputFrame.IDLE);
        }

        assertEquals(5, world.entityCount() - 1);
    }

    @Test
    @DisplayName("a holder marked for destruction earlier this tick does not fire")
    void destroyedHolderDoesNotFire() {
        int shooter = shooterAt(0f, 0f, 1f, 90f);
        world.markForDestruction(shooter);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(1, world.entityCount());
    }

    @Test
    @DisplayName("an explicit first shot delay fires the first shot on time, independent of the cooldown")
    void firstShotDelayFiresIndependentlyOfCooldown() {
        int shooter = world.createEntity();
        world.transforms().set(shooter, new Transform(0f, 0f));
        // A cooldown much longer than the delay: if the delay were ignored and cooldown used instead
        // (today's bug), nothing would fire within these 0.5s.
        world.enemyWeapons().set(shooter, new EnemyWeapon("straight-single", 1.8f, 90f, 0.4f));

        system.update(world, 0.3f, InputFrame.IDLE);
        assertEquals(1, world.entityCount(), "should not fire before the delay elapses");

        system.update(world, 0.1f, InputFrame.IDLE);
        assertEquals(2, world.entityCount(), "should fire once the delay elapses");
    }

    @Test
    @DisplayName("after the delayed first shot, the second shot still waits a full cooldown, not the delay again")
    void secondShotWaitsFullCooldownAfterDelayedFirstShot() {
        int shooter = world.createEntity();
        world.transforms().set(shooter, new Transform(0f, 0f));
        world.enemyWeapons().set(shooter, new EnemyWeapon("straight-single", 1.8f, 90f, 0.4f));

        system.update(world, 0.4f, InputFrame.IDLE);
        assertEquals(2, world.entityCount(), "first shot due at the delay");

        system.update(world, 1.7f, InputFrame.IDLE);
        assertEquals(2, world.entityCount(), "one tick short of a full cooldown after the first shot");

        system.update(world, 0.1f, InputFrame.IDLE);
        assertEquals(3, world.entityCount(), "second shot due a full cooldown after the first");
    }

    @Test
    @DisplayName("a zero or negative first shot delay is rejected, not read as fire on the first tick")
    void rejectsNonPositiveFirstShotDelay() {
        assertThrows(IllegalArgumentException.class,
            () -> new EnemyWeapon("straight-single", 1.8f, 90f, 0f));
        assertThrows(IllegalArgumentException.class,
            () -> new EnemyWeapon("straight-single", 1.8f, 90f, -0.1f));
    }

    @Test
    @DisplayName("the three-argument constructor keeps defaulting the first shot delay to the cooldown")
    void threeArgumentConstructorDefaultsFirstShotDelayToCooldown() {
        EnemyWeapon weapon = new EnemyWeapon("straight-single", 1.8f, 90f);

        assertEquals(1.8f, weapon.cooldownRemaining);
    }

    @Test
    @DisplayName("an unknown pattern fails naming it and the entity, rather than firing nothing")
    void unknownPatternFails() {
        int shooter = world.createEntity();
        world.transforms().set(shooter, new Transform(0f, 0f));
        world.enemyWeapons().set(shooter, new EnemyWeapon("orbiting-swarm", 1f, 90f));

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> system.update(world, 1f, InputFrame.IDLE));
        assertTrue(e.getMessage().contains("orbiting-swarm"));
    }

    @Test
    @DisplayName("an enemy weapon with no position to fire from is skipped, not a crash")
    void noPositionIsSkipped() {
        int shooter = world.createEntity();
        world.enemyWeapons().set(shooter, new EnemyWeapon("straight-single", 1f, 90f));

        system.update(world, 1f, InputFrame.IDLE);

        assertFalse(world.motions().has(shooter));
        assertEquals(1, world.entityCount());
    }

    private int shooterAt(float x, float y, float cooldown, float speed) {
        int shooter = world.createEntity();
        world.transforms().set(shooter, new Transform(x, y));
        world.enemyWeapons().set(shooter, new EnemyWeapon("straight-single", cooldown, speed));
        return shooter;
    }

    private int projectileEntity() {
        for (int i = 0; i < world.transforms().size(); i++) {
            int entity = world.transforms().entityAt(i);
            if (!world.enemyWeapons().has(entity)) {
                return entity;
            }
        }
        throw new IllegalStateException("no projectile entity found");
    }
}
