package dev.luchoc.littlespaceship.core.domain.collision;

/**
 * One overlap detected by {@code CollisionSystem} this tick, for the systems that run right after it
 * in the fixed order to resolve.
 *
 * <p>Not every pair has a consumer yet. {@code DamageSystem} reacts to {@link
 * CollisionPair#ENEMY_VS_PLAYER} and {@link CollisionPair#ENEMY_PROJECTILE_VS_PLAYER}. The other
 * two are detected the same way and wait for the weapon and pickup systems that arrive in a later
 * phase — an unread hit is simply cleared at the start of the next tick, the same as an unregistered
 * {@code SystemOrder} stage is simply skipped.
 *
 * <p>This is an internal detail of the domain, not a {@code GameEvent}: it never crosses towards
 * presentation, and it is resolved within the same tick it was produced.
 *
 * @param first the entity named first by {@link CollisionPair}'s documentation
 * @param second the entity named second
 * @param pair which layers collided
 */
public record CollisionHit(int first, int second, CollisionPair pair) {
}
