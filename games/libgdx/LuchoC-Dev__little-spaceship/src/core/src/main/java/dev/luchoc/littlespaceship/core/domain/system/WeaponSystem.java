package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.Sprite;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.component.Weapon;
import dev.luchoc.littlespaceship.core.domain.entity.EntityId;
import dev.luchoc.littlespaceship.core.port.BalanceValues;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.SpriteId;

/**
 * The player's sustained, automatic main shot: rate of fire, volley shape and projectile creation.
 *
 * <p>Fires while {@link InputFrame#fire()} is held and {@link Weapon#cooldownRemaining} has decayed
 * to zero, resetting it to {@link BalanceValues#weaponFireCooldown()} on every volley. The cooldown
 * decays whether or not fire is held, exactly like {@code Invulnerable}'s grace time in {@code
 * DamageSystem}, so releasing and re-pressing fire mid-cooldown does not let a volley out early.
 *
 * <p>The volley's shape comes straight from {@code docs/design/02-sprite-sizes.md}'s weapon level
 * table — 1, 2, 3 and 5 projectiles, the wider {@code shot-p2} appearing from level 3 — which is
 * exactly the spec's requirement that a level be "recognisable by the shape, count or size of the
 * shot, without requiring a numeric indicator" turned into data. {@link #SHOT_SPACING} is this
 * system's one invented number: the table fixes shape and count, not how far apart parallel shots
 * sit, so a constant plays the same role here that {@link Collider}'s hand-placed radii play for
 * hand-drawn art elsewhere in the project.
 */
public final class WeaponSystem implements GameSystem {

    private static final SpriteId SHOT_P1 = new SpriteId("shot-p1");
    private static final SpriteId SHOT_P2 = new SpriteId("shot-p2");

    private static final float SHOT_P1_RADIUS = 1.5f;
    private static final float SHOT_P2_RADIUS = 2.0f;

    /** Horizontal distance between two adjacent parallel shots, in logical units. */
    private static final float SHOT_SPACING = 3f;

    @Override
    public SystemOrder order() {
        return SystemOrder.WEAPON;
    }

    @Override
    public void update(World world, float step, InputFrame input) {
        int player = world.playerEntity();
        if (player == EntityId.NONE) {
            return;
        }
        Weapon weapon = world.weapons().get(player);
        Player state = world.players().get(player);
        Transform transform = world.transforms().get(player);
        if (weapon == null || state == null || transform == null) {
            return;
        }

        weapon.cooldownRemaining = Math.max(0f, weapon.cooldownRemaining - step);
        if (!input.fire() || weapon.cooldownRemaining > 0f) {
            return;
        }

        BalanceValues balance = world.content().balance();
        fireVolley(world, state.shotLevel, transform, balance.weaponProjectileSpeed());
        weapon.cooldownRemaining = balance.weaponFireCooldown();
    }

    /**
     * One shot per offset of {@link #pattern(int)}, every one of them created the same way: a
     * projectile that only exists to fly straight up and be detected by {@code CollisionSystem}, not
     * to be aimed or to curve.
     */
    private static void fireVolley(World world, int shotLevel, Transform origin, float speed) {
        for (Shot shot : pattern(shotLevel)) {
            int projectile = world.createEntity();
            world.transforms().set(projectile, new Transform(origin.x + shot.offsetX(), origin.y));
            world.motions().set(projectile, new Motion(0f, speed));
            world.colliders().set(projectile,
                new Collider(shot.radius(), CollisionLayer.PLAYER_PROJECTILE));
            world.sprites().set(projectile, new Sprite(shot.sprite()));
        }
    }

    /**
     * The four weapon levels, told apart by count and shape per {@code
     * docs/design/02-sprite-sizes.md}: level 1 is a single centred {@code shot-p1}; level 2 adds a
     * second one beside it, still parallel; level 3 introduces the wider {@code shot-p2} at the
     * centre with a {@code shot-p1} on each side; level 4 adds one more {@code shot-p1} pair further
     * out. A level below 1 or above 4 clamps to the nearest defined one instead of failing, since a
     * malformed {@code shotLevel} is a bug for {@code BalanceValues#weaponLevels()} to have
     * prevented earlier, not something this system should crash a tick over.
     */
    private static Shot[] pattern(int shotLevel) {
        int level = Math.max(1, Math.min(4, shotLevel));
        return switch (level) {
            case 1 -> new Shot[] {centreP1()};
            case 2 -> new Shot[] {side(-1), side(1)};
            case 3 -> new Shot[] {centreP2(), side(-1), side(1)};
            default -> new Shot[] {centreP2(), side(-1), side(1), side(-2), side(2)};
        };
    }

    private static Shot centreP1() {
        return new Shot(0f, SHOT_P1_RADIUS, SHOT_P1);
    }

    private static Shot centreP2() {
        return new Shot(0f, SHOT_P2_RADIUS, SHOT_P2);
    }

    private static Shot side(int steps) {
        return new Shot(steps * SHOT_SPACING, SHOT_P1_RADIUS, SHOT_P1);
    }

    private record Shot(float offsetX, float radius, SpriteId sprite) {
    }
}
