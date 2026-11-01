package dev.meowpow.boxbot.engine.spatial.grid;

import com.badlogic.gdx.math.Rectangle;

/**
 * Converts grid geometry into
 * pixel-space bounding rectangles.
 */
public final class TileBounds {

    private TileBounds() {}

    /**
     * Sets {@code out} to the pixel
     * bounds of the single tile at {@code pos}.
     *
     * @param out the rectangle to populate
     * @param pos the tile's grid position
     * @param tileSize the map's tile size, in pixels
     */
    public static void set(Rectangle out, GridPos pos, TileSize tileSize) {
        float pixels = tileSize.pixels();
        out.set(pos.x() * pixels, pos.y() * pixels, pixels, pixels);
    }

    /**
     * Sets {@code out} to the
     * pixel bounds of {@code footprint}.
     *
     * @param out the rectangle to populate
     * @param footprint the footprint to convert
     * @param tileSize the map's tile size, in pixels
     */
    public static void set(Rectangle out, Footprint footprint, TileSize tileSize) {
        float pixels = tileSize.pixels();
        var anchor = footprint.anchor();
        var extent = footprint.extent();

        out.set(
                anchor.x() * pixels,
                anchor.y() * pixels,
                extent.widthTiles() * pixels,
                extent.heightTiles() * pixels
        );
    }
}
