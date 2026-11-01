package dev.meowpow.boxbot.map;

import dev.meowpow.boxbot.engine.spatial.grid.Grid;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.TiledMapTile;
import com.badlogic.gdx.maps.tiled.TiledMapTileLayer;

/**
 * Converts a Tiled tile layer into
 * the engine's {@link Grid} representation.
 */
public final class GridParser {

    private static final String WALKABLE_PROPERTY = "walkable";

    private GridParser() {}

    /**
     * Builds a {@link Grid} matching the given layer's dimensions,
     * marking a cell walkable only when it holds a tile whose
     * {@code walkable} property is {@code true}.
     *
     * @param map the Tiled map containing the layer
     * @param layerName the name of the tile layer to read
     *
     * @return a grid sized to the layer, with walkability copied from each tile
     * @throws IllegalStateException if no tile layer named {@code layerName} exists
     */
    public static Grid parseWalkableGrid(TiledMap map, String layerName) {
        var mapLayer = map.getLayers().get(layerName);
        if (!(mapLayer instanceof TiledMapTileLayer layer)) {
            var message = "No tile layer named '%s' found in map";
            throw new IllegalStateException(message.formatted(layerName));
        }
        var grid = new Grid(layer.getWidth(), layer.getHeight());

        for (int x = 0; x < layer.getWidth(); x++) {
            for (int y = 0; y < layer.getHeight(); y++) {
                grid.setWalkable(x, y, isWalkable(layer.getCell(x, y)));
            }
        }
        return grid;
    }

    private static boolean isWalkable(TiledMapTileLayer.@Nullable Cell cell) {
        return cell != null && isWalkable(cell.getTile());
    }

    private static boolean isWalkable(@Nullable TiledMapTile tile) {
        return tile != null && tile.getProperties().get(WALKABLE_PROPERTY, false, Boolean.class);
    }
}
