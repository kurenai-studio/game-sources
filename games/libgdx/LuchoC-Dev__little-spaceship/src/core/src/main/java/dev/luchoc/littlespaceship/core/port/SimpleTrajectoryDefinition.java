package dev.luchoc.littlespaceship.core.port;

/**
 * The {@code constant} shape from the catalogue: a fixed velocity for the entity's whole life.
 * {@code velocity(t) = (vx, vy)} — {@link #verticalVelocityAt(float)} ignores its argument entirely.
 *
 * @param id the content id
 * @param vx horizontal velocity, in logical units per second
 * @param vy vertical velocity, in logical units per second
 */
public record SimpleTrajectoryDefinition(String id, float vx, float vy) implements TrajectoryDefinition {

    /**
     * Rejects a trajectory that names nothing.
     */
    public SimpleTrajectoryDefinition {
        if (id == null || id.isEmpty()) {
            throw new IllegalArgumentException("a trajectory needs an id");
        }
    }

    @Override
    public float verticalVelocityAt(float elapsedSeconds) {
        return vy;
    }
}
