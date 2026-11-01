package dev.meowpow.boxbot.engine.spatial.grid;

/**
 * The pixel size of one square grid tile,
 * used to convert grid coordinates to pixel coordinates.
 *
 * @param pixels width and height of one tile, in pixels
 */
public record TileSize(int pixels) {

    /**
     * @throws IllegalArgumentException if {@code pixels} is not positive
     */
    public TileSize {
        if (pixels <= 0) {
            throw new IllegalArgumentException("pixels must be > 0, got " + pixels);
        }
    }
}
