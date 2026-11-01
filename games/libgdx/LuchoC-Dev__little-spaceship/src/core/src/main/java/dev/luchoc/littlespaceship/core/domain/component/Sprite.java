package dev.luchoc.littlespaceship.core.domain.component;

import dev.luchoc.littlespaceship.core.port.SpriteId;

/**
 * How an entity is drawn.
 *
 * <p>The simulation keeps no textures and no atlases: it holds the identifier the content gave it
 * and the animation state, and the adapter turns that into pixels. An entity without this component
 * simply is not drawn, which is what a projectile that only exists for collision purposes wants.
 */
public final class Sprite {

    /** Which graphic to draw. */
    public SpriteId id;

    /** Current animation frame. */
    public int frame;

    /** Rotation in degrees, zero when the entity is upright. */
    public float rotation;

    /**
     * Creates a sprite on its first frame and with no rotation.
     *
     * @param id the graphic identifier
     */
    public Sprite(SpriteId id) {
        this(id, 0, 0f);
    }

    /**
     * Creates a sprite in an explicit state.
     *
     * @param id the graphic identifier
     * @param frame the animation frame
     * @param rotation the rotation in degrees
     */
    public Sprite(SpriteId id, int frame, float rotation) {
        this.id = id;
        this.frame = frame;
        this.rotation = rotation;
    }
}
