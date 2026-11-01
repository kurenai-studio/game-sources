package dev.luchoc.littlespaceship.core.port;

/**
 * The {@code arc} shape from the catalogue: a fixed horizontal velocity with a constant vertical
 * acceleration — the U-shaped attack run named in
 * {@code docs/plan/11c-movement-shapes/shape-catalogue.md}. {@code velocity(t) = (vx, vy + ay * t)}.
 *
 * <p>{@code ay = 0} degenerates to the same numbers a {@link SimpleTrajectoryDefinition} would give,
 * which the catalogue calls a coincidence of the maths, not a reason to route a constant shape
 * through this record instead.
 *
 * @param id the content id
 * @param vx horizontal velocity, in logical units per second, constant for the whole life
 * @param vy vertical velocity at elapsed time zero, in logical units per second, positive upwards
 * @param ay vertical acceleration, in logical units per second squared
 */
public record ArcTrajectoryDefinition(String id, float vx, float vy, float ay) implements TrajectoryDefinition {

    /**
     * Rejects a trajectory that names nothing, and any parameter that is not a finite number — an
     * arc's turning point and apex are derived from {@code vy} and {@code ay}
     * ({@code shape-catalogue.md}'s own worked examples), and a {@code NaN} or infinite input would
     * silently make those derivations meaningless rather than fail where the bad data was declared.
     */
    public ArcTrajectoryDefinition {
        if (id == null || id.isEmpty()) {
            throw new IllegalArgumentException("a trajectory needs an id");
        }
        requireFinite(vx, "vx");
        requireFinite(vy, "vy");
        requireFinite(ay, "ay");
    }

    private static void requireFinite(float value, String field) {
        if (Float.isNaN(value) || Float.isInfinite(value)) {
            throw new IllegalArgumentException(
                "an arc trajectory's " + field + " must be a finite number, was " + value);
        }
    }

    @Override
    public float verticalVelocityAt(float elapsedSeconds) {
        return vy + ay * elapsedSeconds;
    }
}
