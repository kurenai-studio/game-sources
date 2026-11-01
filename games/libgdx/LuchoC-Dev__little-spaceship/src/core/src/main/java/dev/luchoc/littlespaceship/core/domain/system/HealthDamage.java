package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Health;

/**
 * Applies a fixed amount of damage to an entity's {@link Health}, shared by every system that deals
 * damage to an enemy — {@code DamageSystem} for a player projectile, {@code BombSystem} for a
 * detonation — so "no {@link Health} means one point" is decided in exactly one place.
 *
 * <p>Package-private: this is an implementation detail of the two systems that use it, not a rule
 * either of them exposes.
 */
final class HealthDamage {

    private HealthDamage() {
    }

    /**
     * Subtracts {@code amount} from {@code entity}'s {@link Health} and marks it for destruction
     * once it reaches zero. An entity with no {@link Health} component is destroyed outright by any
     * positive amount — shorthand for the weakest case of the same rule, per {@link Health}'s
     * javadoc, not a second mechanism that could disagree with it.
     *
     * @param world the world to read and mark destruction in
     * @param entity the entity taking damage
     * @param amount hit points to subtract, expected strictly positive
     */
    static void apply(World world, int entity, int amount) {
        Health health = world.healths().get(entity);
        if (health == null) {
            world.markForDestruction(entity);
            return;
        }
        health.points -= amount;
        if (health.points <= 0) {
            world.markForDestruction(entity);
        }
    }
}
