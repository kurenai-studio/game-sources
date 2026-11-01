package dev.meowpow.boxbot.map;

import dev.meowpow.boxbot.engine.spatial.grid.TileSize;

import com.badlogic.gdx.maps.tiled.TiledMap;

/**
 * Reads a Tiled map's tile dimensions
 * into engine's {@link TileSize} representation.
 */
public final class TileSizeParser {

    private TileSizeParser() {}

    /**
     * Returns the given map's tile size.
     *
     * @param map the Tiled map to read
     *
     * @throws IllegalStateException if the map's tiles are not square
     */
    public static TileSize parse(TiledMap map) {
        int tileWidth = map.getProperties().get("tilewidth", Integer.class);
        int tileHeight = map.getProperties().get("tileheight", Integer.class);

        if (tileWidth != tileHeight) {
            var message = "Non-square tiles are not supported: tilewidth=%d, tileheight=%d";
            throw new IllegalStateException(message.formatted(tileWidth, tileHeight));
        }
        return new TileSize(tileWidth);
    }
}
