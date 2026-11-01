package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.ComponentStore;
import dev.luchoc.littlespaceship.core.domain.component.EnemyWeapon;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Sprite;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.SpriteId;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Ticks down every entity's {@link EnemyWeapon} and creates a projectile the instant one is due —
 * the first system in this codebase to let anything but the player and the boss fire. See {@link
 * SystemOrder#ENEMY_WEAPON} for the ordering and determinism reasoning.
 *
 * <p>Stateless, the same shape {@code SpawnerSystem} already is: every enemy's countdown lives on
 * its own {@link EnemyWeapon} component, not on this system.
 *
 * <p>{@code "shot-e-small"} is the one projectile sprite this system emits — {@code
 * 02-sprite-sizes.md}'s "small" enemy bullet, 5x5, radius 2.0 — since {@code "straight-single"} is
 * the only pattern the MVP needs. A second pattern would need a second sprite id; nothing here
 * justifies guessing one ahead of that need.
 */
public final class EnemyWeaponSystem implements GameSystem {

    private static final SpriteId SHOT_SPRITE = new SpriteId("shot-e-small");

    /** {@code 02-sprite-sizes.md}: "Enemy bullet, small", 5x5. */
    private static final float PROJECTILE_RADIUS = 2.0f;

    private static final String PATTERN_STRAIGHT_SINGLE = "straight-single";

    @Override
    public SystemOrder order() {
        return SystemOrder.ENEMY_WEAPON;
    }

    @Override
    public void update(World world, float step, InputFrame input) {
        Set<Integer> destroyed = destroyedThisTick(world);
        ComponentStore<EnemyWeapon> weapons = world.enemyWeapons();
        for (int i = 0; i < weapons.size(); i++) {
            int entity = weapons.entityAt(i);
            if (destroyed.contains(entity)) {
                continue;
            }
            EnemyWeapon weapon = weapons.valueAt(i);
            weapon.cooldownRemaining -= step;
            if (weapon.cooldownRemaining > 0f) {
                continue;
            }
            weapon.cooldownRemaining = weapon.cooldown;
            fire(world, entity, weapon);
        }
    }

    /**
     * A lookup of what {@code World#pendingDestruction()} holds this tick, the same trade {@code
     * CollisionSystem} and {@code SpawnerSystem} already make: empty, allocating nothing, in the
     * ordinary case where nothing earlier in the pipeline marked a holder for destruction this tick.
     */
    private static Set<Integer> destroyedThisTick(World world) {
        List<Integer> pending = world.pendingDestruction();
        if (pending.isEmpty()) {
            return Set.of();
        }
        return new HashSet<>(pending);
    }

    private static void fire(World world, int entity, EnemyWeapon weapon) {
        Transform origin = world.transforms().get(entity);
        if (origin == null) {
            // No position to fire from is a bug in whoever built this entity, not something this
            // system should crash a tick over.
            return;
        }
        float vx;
        float vy;
        switch (weapon.pattern) {
            case PATTERN_STRAIGHT_SINGLE -> {
                vx = 0f;
                // Straight down, towards the player: Transform.y grows upward, same convention
                // WeaponSystem's own projectiles use in reverse.
                vy = -weapon.projectileSpeed;
            }
            default -> throw new IllegalArgumentException(
                "unknown enemy weapon pattern '" + weapon.pattern + "' on entity " + entity);
        }
        int projectile = world.createEntity();
        world.transforms().set(projectile, new Transform(origin.x, origin.y));
        world.motions().set(projectile, new Motion(vx, vy));
        world.colliders().set(projectile,
            new Collider(PROJECTILE_RADIUS, CollisionLayer.ENEMY_PROJECTILE));
        world.sprites().set(projectile, new Sprite(SHOT_SPRITE));
    }
}
