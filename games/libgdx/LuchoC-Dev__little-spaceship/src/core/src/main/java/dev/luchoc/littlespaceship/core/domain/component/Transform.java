package dev.luchoc.littlespaceship.core.domain.component;

/**
 * Position of an entity in the playfield, in logical units.
 *
 * <p>Plain data with public fields and no behaviour: the rules live in the systems. Mutating in
 * place is deliberate, so moving an entity does not allocate sixty times per second.
 */
public final class Transform {

    /** Horizontal position, growing to the right. */
    public float x;

    /** Vertical position, growing upwards. */
    public float y;

    /**
     * Creates a transform at the given position.
     *
     * @param x horizontal position
     * @param y vertical position
     */
    public Transform(float x, float y) {
        this.x = x;
        this.y = y;
    }
}
