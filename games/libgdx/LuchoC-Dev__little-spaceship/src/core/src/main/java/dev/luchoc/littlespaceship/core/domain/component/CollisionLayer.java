package dev.luchoc.littlespaceship.core.domain.component;

/**
 * The side an entity collides as.
 *
 * <p>Collision is resolved by layer pairs and not everything against everything, which is what
 * keeps the cost low without any spatial structure. The pairs that are actually tested are decided
 * in the architecture document:
 *
 * <pre>
 * player projectile  x  enemy
 * enemy projectile   x  player
 * enemy              x  player
 * pickup             x  player
 * </pre>
 */
public enum CollisionLayer {

    /** The player's ship. */
    PLAYER,

    /** Anything the player shoots. */
    PLAYER_PROJECTILE,

    /** Enemies, the boss and destructible structures. */
    ENEMY,

    /** Anything an enemy shoots. */
    ENEMY_PROJECTILE,

    /** Collectables lying in the playfield. */
    PICKUP
}
