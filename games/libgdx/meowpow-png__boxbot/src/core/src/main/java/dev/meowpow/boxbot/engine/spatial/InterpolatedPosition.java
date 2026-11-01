package dev.meowpow.boxbot.engine.spatial;

import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.engine.time.Alpha;

import java.util.Objects;

/**
 * A reusable position blended between two grid positions.
 */
@SuppressWarnings("NotNullFieldNotInitialized")
public final class InterpolatedPosition {

    private GridPos from;
    private GridPos to;
    private Alpha alpha;

    /**
     * Creates an interpolation ready to be configured.
     */
    public InterpolatedPosition() {}

    /**
     * Creates an interpolation between {@code from} and {@code to}.
     *
     * @param from grid position at the start of the interpolation
     * @param to grid position at the end of the interpolation
     * @param alpha blend position between {@code from} and {@code to}
     *
     * @throws NullPointerException if any argument is null
     */
    public InterpolatedPosition(GridPos from, GridPos to, Alpha alpha) {
        set(from, to, alpha);
    }

    /**
     * Updates this interpolation's endpoints and blend fraction.
     *
     * @param from grid position at the start of the interpolation
     * @param to grid position at the end of the interpolation
     * @param alpha blend position between {@code from} and {@code to}
     *
     * @throws NullPointerException if any argument is null
     */
    public void set(GridPos from, GridPos to, Alpha alpha) {
        this.from = Objects.requireNonNull(from, "from must not be null");
        this.to = Objects.requireNonNull(to, "to must not be null");
        this.alpha = Objects.requireNonNull(alpha, "alpha must not be null");
    }

    /**
     * Returns the blended X position
     * in pixels, centered within the tile.
     *
     * @param tileSize the tile size in pixels
     */
    public float centerX(TileSize tileSize) {
        return (lerp(from.x(), to.x(), alpha.value()) + 0.5f) * tileSize.pixels();
    }

    /**
     * Returns the blended Y position
     * in pixels, centered within the tile.
     *
     * @param tileSize the tile size in pixels
     */
    public float centerY(TileSize tileSize) {
        return (lerp(from.y(), to.y(), alpha.value()) + 0.5f) * tileSize.pixels();
    }

    private static float lerp(float a, float b, float t) {
        return a + (b - a) * t;
    }
}
