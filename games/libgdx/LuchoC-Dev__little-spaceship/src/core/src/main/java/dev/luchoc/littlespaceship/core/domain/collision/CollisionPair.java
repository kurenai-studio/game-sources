package dev.luchoc.littlespaceship.core.domain.collision;

/**
 * The four layer pairs the simulation actually tests, confirmed in {@code 12-architecture.md}.
 *
 * <p>Collision is resolved by these pairs and never by comparing everything against everything,
 * which is what keeps the cost low with no spatial structure: the naive comparison was measured at
 * 0.028 ms for the MVP scenario.
 */
public enum CollisionPair {

    /**
     * A player projectile reaching an enemy. In the {@link CollisionHit} it produces, {@code first}
     * is the projectile and {@code second} the enemy.
     */
    PLAYER_PROJECTILE_VS_ENEMY,

    /**
     * An enemy projectile reaching the player. {@code first} is the projectile, {@code second} the
     * player.
     */
    ENEMY_PROJECTILE_VS_PLAYER,

    /**
     * An enemy's body reaching the player. {@code first} is the enemy, {@code second} the player.
     */
    ENEMY_VS_PLAYER,

    /**
     * A pickup reaching the player. {@code first} is the pickup, {@code second} the player.
     */
    PICKUP_VS_PLAYER
}
