package dev.meowpow.boxbot.engine.spatial;

import dev.meowpow.boxbot.engine.spatial.grid.Direction;
import dev.meowpow.boxbot.engine.time.Alpha;

import java.util.Objects;

/**
 * A reusable facing angle blended between two grid directions.
 */
@SuppressWarnings("NotNullFieldNotInitialized")
public final class InterpolatedFacing {

    private Direction from;
    private Direction to;
    private Alpha alpha;

    /**
     * Creates an interpolation ready to be configured.
     */
    public InterpolatedFacing() {}

    /**
     * Creates an interpolation between {@code from} and {@code to}.
     *
     * @param from direction at the start of the interpolation
     * @param to direction at the end of the interpolation
     * @param alpha blend position between {@code from} and {@code to}
     *
     * @throws NullPointerException if any argument is null
     */
    public InterpolatedFacing(Direction from, Direction to, Alpha alpha) {
        set(from, to, alpha);
    }

    /**
     * Updates this interpolation's endpoints and blend fraction.
     *
     * @param from direction at the start of the interpolation
     * @param to direction at the end of the interpolation
     * @param alpha blend position between {@code from} and {@code to}
     *
     * @throws NullPointerException if any argument is null
     */
    public void set(Direction from, Direction to, Alpha alpha) {
        this.from = Objects.requireNonNull(from, "from must not be null");
        this.to = Objects.requireNonNull(to, "to must not be null");
        this.alpha = Objects.requireNonNull(alpha, "alpha must not be null");
    }

    /**
     * Returns the blended angle in degrees,
     * taking the shortest path around the 0/360 wrap point.
     */
    public float degrees() {
        return from.degrees() + shortestDelta(from.degrees(), to.degrees()) * alpha.value();
    }

    private static float shortestDelta(float from, float to) {
        float diff = to - from;
        return ((diff % 360f) + 540f) % 360f - 180f;
    }
}
