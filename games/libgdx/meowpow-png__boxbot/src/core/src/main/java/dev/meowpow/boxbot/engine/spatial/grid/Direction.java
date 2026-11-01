package dev.meowpow.boxbot.engine.spatial.grid;

import java.util.Objects;

/**
 * A cardinal facing on the grid.
 * <p>
 * Doubles as the direction of a single
 * orthogonal step between two grid positions.
 */
public enum Direction {
    NORTH(0, 1, 0f),
    WEST(-1, 0, 90f),
    SOUTH(0, -1, 180f),
    EAST(1, 0, 270f);

    private final int dx, dy;
    private final float degrees;

    Direction(int dx, int dy, float degrees) {
        this.dx = dx;
        this.dy = dy;
        this.degrees = degrees;
    }

    /**
     * Returns this direction's angle in degrees.
     */
    public float degrees() {
        return degrees;
    }

    /**
     * Returns the direction of a single
     * orthogonal step from {@code from} to {@code to}.
     *
     * @throws NullPointerException if {@code from} or {@code to} is null
     * @throws IllegalArgumentException if {@code from} and {@code to}
     * are not one orthogonal grid step apart
     */
    public static Direction between(GridPos from, GridPos to) {
        Objects.requireNonNull(from, "from must not be null");
        Objects.requireNonNull(to, "to must not be null");

        long dx = (long) to.x() - from.x();
        long dy = (long) to.y() - from.y();

        for (Direction direction : values()) {
            if (direction.dx == dx && direction.dy == dy) {
                return direction;
            }
        }
        throw new IllegalArgumentException("Not an orthogonal step from " + from + " to " + to);
    }
}
