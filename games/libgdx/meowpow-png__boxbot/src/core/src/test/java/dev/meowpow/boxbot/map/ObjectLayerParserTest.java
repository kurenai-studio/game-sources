package dev.meowpow.boxbot.map;

import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.engine.spatial.grid.TileExtent;
import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.engine.spatial.grid.Zone;

import com.badlogic.gdx.maps.MapLayer;
import com.badlogic.gdx.maps.MapObject;
import com.badlogic.gdx.maps.objects.RectangleMapObject;
import com.badlogic.gdx.maps.tiled.TiledMap;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalStateException;

@SuppressWarnings("SameParameterValue")
class ObjectLayerParserTest {

    private static final String ENTITIES_LAYER = ObjectLayerParser.ENTITIES_LAYER_NAME;
    private static final String SHELVES_LAYER = ObjectLayerParser.SHELVES_LAYER_NAME;
    private static final String ZONES_LAYER = ObjectLayerParser.ZONES_LAYER_NAME;

    private static final TileSize TILE_SIZE = new TileSize(10);

    @Nested
    @DisplayName("parse")
    class ParseMethodTests {

        @Test
        @DisplayName("Converts rectangular map objects into a warehouse layout")
        void should_CreateWarehouseLayout_when_LayersAreValid() {
            var loadingBay = loadingBay(20, 10, 20, 10);
            var chargingStation = chargingStation(40, 10, 10, 20);
            var map = mapWithLayers(
                    layer(ENTITIES_LAYER, loadingBay, chargingStation),
                    layer(SHELVES_LAYER, shelf(7, 10, 20)),
                    layer(ZONES_LAYER, zone("Cold", 0, 0, 30, 20))
            );
            var layout = ObjectLayerParser.parse(map, TILE_SIZE);
            assertThat(layout.shelves()).singleElement().satisfies(shelf -> {
                assertThat(shelf.id()).isEqualTo(new ShelfId(7));
                assertThat(shelf.pos()).isEqualTo(new GridPos(1, 2));
            });
            assertThat(layout.zones()).containsExactly(new Zone(
                    "Cold",
                    new GridPos(0, 0),
                    new GridPos(2, 1)
            ));
            assertThat(layout.loadingBay()).isEqualTo(new GridPos(2, 1));
            assertThat(layout.loadingBayExtent()).isEqualTo(new TileExtent(2, 1));
            assertThat(layout.chargingStation()).isEqualTo(new GridPos(4, 1));
            assertThat(layout.chargingStationExtent()).isEqualTo(new TileExtent(1, 2));
        }

        @Test
        @DisplayName("Rejects a map without a loading bay")
        void should_RejectMap_when_LoadingBayIsMissing() {
            var chargingStation = chargingStation(0, 0, 10, 10);
            var map = mapWithLayers(
                    layer(ENTITIES_LAYER, chargingStation),
                    layer(SHELVES_LAYER),
                    layer(ZONES_LAYER)
            );
            assertThatIllegalStateException().isThrownBy(() -> parse(map));
        }

        @Test
        @DisplayName("Rejects a map without a charging station")
        void should_RejectMap_when_ChargingStationIsMissing() {
            var loadingBay = loadingBay(0, 0, 10, 10);
            var map = mapWithLayers(
                    layer(ENTITIES_LAYER, loadingBay),
                    layer(SHELVES_LAYER),
                    layer(ZONES_LAYER)
            );
            assertThatIllegalStateException().isThrownBy(() -> parse(map));
        }

        @Test
        @DisplayName("Rejects a map with multiple loading bays")
        void should_RejectMap_when_LoadingBayIsDuplicated() {
            var entityLayers = layer(ENTITIES_LAYER,
                    loadingBay(0, 0, 10, 10),
                    loadingBay(10, 0, 10, 10)
            );
            var map = mapWithLayers(
                    entityLayers,
                    layer(SHELVES_LAYER),
                    layer(ZONES_LAYER)
            );
            assertThatIllegalStateException().isThrownBy(() -> parse(map));
        }

        @Test
        @DisplayName("Rejects a map with multiple charging stations")
        void should_RejectMap_when_ChargingStationIsDuplicated() {
            var entityLayers = layer(ENTITIES_LAYER,
                    chargingStation(0, 0, 10, 10),
                    chargingStation(10, 0, 10, 10)
            );
            var map = mapWithLayers(
                    entityLayers,
                    layer(SHELVES_LAYER),
                    layer(ZONES_LAYER)
            );
            assertThatIllegalStateException().isThrownBy(() -> parse(map));
        }

        @Test
        @DisplayName("Rejects an unknown entity type")
        void should_RejectMap_when_EntityTypeIsUnknown() {
            var conveyor = entity("conveyor", 0, 0, 10, 10);
            var map = mapWithLayers(
                    layer(ENTITIES_LAYER, conveyor),
                    layer(SHELVES_LAYER),
                    layer(ZONES_LAYER)
            );
            assertThatIllegalStateException().isThrownBy(() -> parse(map));
        }

        @Test
        @DisplayName("Rejects a non-rectangular entity")
        void should_RejectMap_when_EntityIsNotRectangular() {
            var map = mapWithLayers(
                    layer(ENTITIES_LAYER, new MapObject()),
                    layer(SHELVES_LAYER),
                    layer(ZONES_LAYER)
            );
            assertThatIllegalStateException().isThrownBy(() -> parse(map));
        }

        @Test
        @DisplayName("Rejects a non-rectangular shelf")
        void should_RejectMap_when_ShelfIsNotRectangular() {
            var map = mapWithLayers(
                    layer(ENTITIES_LAYER),
                    layer(SHELVES_LAYER, new MapObject()),
                    layer(ZONES_LAYER)
            );
            assertThatIllegalStateException().isThrownBy(() -> parse(map));
        }

        @Test
        @DisplayName("Rejects a non-rectangular zone")
        void should_RejectMap_when_ZoneIsNotRectangular() {
            var map = mapWithLayers(
                    layer(ENTITIES_LAYER),
                    layer(SHELVES_LAYER),
                    layer(ZONES_LAYER, new MapObject())
            );
            assertThatIllegalStateException().isThrownBy(() -> parse(map));
        }
    }

    private static void parse(TiledMap map) {
        ObjectLayerParser.parse(map, TILE_SIZE);
    }

    private static TiledMap mapWithLayers(MapLayer... layers) {
        var map = new TiledMap();
        for (var layer : layers) {
            map.getLayers().add(layer);
        }
        return map;
    }

    private static MapLayer layer(String name, MapObject... objects) {
        var layer = new MapLayer();
        layer.setName(name);
        for (var object : objects) {
            layer.getObjects().add(object);
        }
        return layer;
    }

    private static RectangleMapObject entity(
            String type,
            int x,
            int y,
            float width,
            float height
    ) {
        var object = new RectangleMapObject(x, y, width, height);
        object.getProperties().put("type", type);
        return object;
    }

    private static RectangleMapObject loadingBay(int x, int y, float width, float height) {
        return entity("loadingBay", x, y, width, height);
    }

    private static RectangleMapObject chargingStation(int x, int y, float width, float height) {
        return entity("chargingStation", x, y, width, height);
    }

    private static MapObject shelf(int id, int x, int y) {
        var object = new RectangleMapObject(x, y, 10, 10);
        object.getProperties().put("id", id);
        return object;
    }

    private static MapObject zone(String name, int x, int y, float width, float height) {
        var object = new RectangleMapObject(x, y, width, height);
        object.setName(name);
        return object;
    }
}
