package dev.meowpow.boxbot.map;

import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.TiledMapTileLayer;
import com.badlogic.gdx.maps.tiled.tiles.StaticTiledMapTile;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class GridParserTest {

    private static final String LAYER_NAME = "floor";

    @Nested
    @DisplayName("parseWalkableGrid")
    class ParseWalkableGridMethodTests {

        @Test
        @DisplayName("Creates a grid with the tile layer dimensions")
        void should_CreateGridWithLayerDimensions_when_LayerExists() {
            var grid = GridParser.parseWalkableGrid(
                    mapWithLayer(2, 3),
                    LAYER_NAME
            );
            assertThat(grid.width()).isEqualTo(2);
            assertThat(grid.height()).isEqualTo(3);
        }

        @Test
        @DisplayName("Marks only cells with a true walkable property as walkable")
        void should_MarkCellWalkable_when_TileWalkablePropertyIsTrue() {
            var map = mapWithLayer(2, 2);
            var layer = (TiledMapTileLayer) map.getLayers().get(LAYER_NAME);

            layer.setCell(0, 0, cellWithWalkableProperty(true));
            layer.setCell(1, 0, cellWithWalkableProperty(false));
            layer.setCell(0, 1, new TiledMapTileLayer.Cell());

            var grid = GridParser.parseWalkableGrid(map, LAYER_NAME);

            assertThat(grid.isWalkable(0, 0)).isTrue();
            assertThat(grid.isWalkable(1, 0)).isFalse();
            assertThat(grid.isWalkable(0, 1)).isFalse();
            assertThat(grid.isWalkable(1, 1)).isFalse();
        }
    }

    @SuppressWarnings("SameParameterValue")
    private static TiledMap mapWithLayer(int width, int height) {
        var layer = new TiledMapTileLayer(width, height, 1, 1);
        layer.setName(LAYER_NAME);

        var map = new TiledMap();
        map.getLayers().add(layer);
        return map;
    }

    private static TiledMapTileLayer.Cell cellWithWalkableProperty(boolean walkable) {
        var tile = new StaticTiledMapTile((TextureRegion) null);
        tile.getProperties().put("walkable", walkable);

        return new TiledMapTileLayer.Cell().setTile(tile);
    }
}
