package dev.luchoc.littlespaceship.core.domain.component;

/**
 * Collision volume of an entity: a circle around its position.
 *
 * <p>A circle and not a rectangle because the comparison is a squared distance, with no square root
 * and no branching, and because in a shoot 'em up a generous circular hitbox reads as fairer than
 * an exact one.
 */
public final class Collider {

    /** Radius in logical units. */
    public float radius;

    /** Side this entity collides as. */
    public CollisionLayer layer;

    /**
     * Whether this entity is destroyed when its body crashes into the player.
     *
     * <p>Meaningful only for {@link CollisionLayer#ENEMY} colliders. Weak archetypes — basic, light,
     * fast — set it true and are destroyed in the crash; tanks and heavy carriers leave it false and
     * shrug the impact off. Every other layer ignores the field.
     */
    public boolean fragile;

    /**
     * Creates a collider that survives crashing into the player, which is the right default for
     * every layer except a weak enemy.
     *
     * @param radius radius in logical units
     * @param layer the side this entity collides as
     */
    public Collider(float radius, CollisionLayer layer) {
        this(radius, layer, false);
    }

    /**
     * Creates a collider with an explicit crash behaviour.
     *
     * @param radius radius in logical units
     * @param layer the side this entity collides as
     * @param fragile whether an enemy's body is destroyed when it crashes into the player
     */
    public Collider(float radius, CollisionLayer layer, boolean fragile) {
        this.radius = radius;
        this.layer = layer;
        this.fragile = fragile;
    }
}
