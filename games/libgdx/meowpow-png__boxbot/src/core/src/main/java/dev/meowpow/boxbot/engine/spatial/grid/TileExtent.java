package dev.meowpow.boxbot.engine.spatial.grid;

/**
 * A footprint's size, in tiles.
 *
 * @param widthTiles width in tiles
 * @param heightTiles height in tiles
 */
public record TileExtent(int widthTiles, int heightTiles) {

    /**
     * @throws IllegalArgumentException if {@code widthTiles} or {@code heightTiles} is negative
     */
    public TileExtent {
        if (widthTiles < 0 || heightTiles < 0) {
            var message = "widthTiles and heightTiles must be >= 0, got (%d, %d)";
            throw new IllegalArgumentException(message.formatted(widthTiles, heightTiles));
        }
    }
}
