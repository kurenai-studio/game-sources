package dev.luchoc.littlespaceship.core.port;

/**
 * Receives everything that has to be drawn, one entity at a time.
 *
 * <p>A visitor and not a list: returning a collection would allocate an object per entity per
 * frame, which at sixty frames per second and hundreds of entities is constant work for the garbage
 * collector. Passing primitives keeps the boundary allocation-free, which matters more here than
 * anywhere else in the project.
 */
@FunctionalInterface
public interface SpriteVisitor {

    /**
     * Called once per drawable entity, in no guaranteed order.
     *
     * @param sprite which graphic to draw
     * @param x horizontal position in logical units
     * @param y vertical position in logical units
     * @param frame current animation frame
     * @param rotation rotation in degrees, zero when the entity is upright
     */
    void accept(SpriteId sprite, float x, float y, int frame, float rotation);
}
