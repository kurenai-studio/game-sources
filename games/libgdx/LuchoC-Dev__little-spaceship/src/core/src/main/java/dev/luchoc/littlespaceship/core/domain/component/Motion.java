package dev.luchoc.littlespaceship.core.domain.component;

/**
 * Velocity of an entity, in logical units per second.
 *
 * <p>Per second and not per tick: the step is fixed, so the conversion happens once inside the
 * motion system and the balance values stay readable.
 *
 * <p>A curved or shaped trajectory does not live here: this still holds only the velocity {@code
 * MotionSystem} integrates each tick, exactly as before. What decides that velocity for an entity
 * following a shape is {@link Trajectory}'s {@code elapsed} time, evaluated through the shape's
 * {@code verticalVelocityAt}; the resolved result still lands here, the same way a constant
 * trajectory always has.
 */
public final class Motion {

    /** Horizontal velocity. */
    public float vx;

    /** Vertical velocity. */
    public float vy;

    /**
     * Creates a motion component with the given velocity.
     *
     * @param vx horizontal velocity
     * @param vy vertical velocity
     */
    public Motion(float vx, float vy) {
        this.vx = vx;
        this.vy = vy;
    }
}
