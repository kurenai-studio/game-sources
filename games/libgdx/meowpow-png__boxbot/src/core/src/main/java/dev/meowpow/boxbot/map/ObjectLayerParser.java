package dev.meowpow.boxbot.map;

import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.layout.ShelfSlot;
import dev.meowpow.boxbot.engine.layout.WarehouseLayout;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.engine.spatial.grid.TileExtent;
import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.engine.spatial.grid.Zone;

import com.badlogic.gdx.maps.MapObject;
import com.badlogic.gdx.maps.objects.RectangleMapObject;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.math.Rectangle;

import java.util.ArrayList;
import java.util.List;

/**
 * Reads the warehouse's fixed
 * layout from a Tiled map's object layers.
 */
public final class ObjectLayerParser {

    private static final String TYPE_PROPERTY = "type";
    private static final String LOADING_BAY_TYPE = "loadingBay";
    private static final String CHARGING_STATION_TYPE = "chargingStation";

    static final String ENTITIES_LAYER_NAME = "entities";
    static final String SHELVES_LAYER_NAME = "shelves";
    static final String ZONES_LAYER_NAME = "zones";

    private ObjectLayerParser() {}

    /**
     * Parses the given object layers into a {@link WarehouseLayout}.
     *
     * @param map the Tiled map containing the layers
     * @param tileSize the map's tile size
     *
     * @return the parsed warehouse layout
     * @throws IllegalStateException if entities layer does not contain
     * exactly one {@code loadingBay} and one {@code chargingStation} object,
     * if any layer contains a non-rectangular object, or if entities
     * layer contains an object of an unrecognized type
     */
    public static WarehouseLayout parse(TiledMap map, TileSize tileSize) {
        var shelves = parseShelves(map, tileSize);
        var zones = parseZones(map, tileSize);

        GridPos loadingBay = null;
        GridPos chargingStation = null;

        TileExtent loadingBayExtent = null;
        TileExtent chargingStationExtent = null;

        for (MapObject object : map.getLayers().get(ENTITIES_LAYER_NAME).getObjects()) {
            var rectangleObject = requireRectangle(object, ENTITIES_LAYER_NAME);
            var type = object.getProperties().get(TYPE_PROPERTY, String.class);
            var rect = rectangleObject.getRectangle();
            var pos = toGridPos(rect, tileSize);
            var extent = toExtent(rect, tileSize);

            switch (type) {
                case LOADING_BAY_TYPE -> {
                    if (loadingBay != null) {
                        var message = "Multiple loadingBay objects found in layer '%s'";
                        throw new IllegalStateException(message.formatted(ENTITIES_LAYER_NAME));
                    }
                    loadingBay = pos;
                    loadingBayExtent = extent;
                }
                case CHARGING_STATION_TYPE -> {
                    if (chargingStation != null) {
                        var message = "Multiple chargingStation objects found in layer '%s'";
                        throw new IllegalStateException(message.formatted(ENTITIES_LAYER_NAME));
                    }
                    chargingStation = pos;
                    chargingStationExtent = extent;
                }
                default -> {
                    var message = "Unknown entity type '%s' in layer '%s'";
                    throw new IllegalStateException(message.formatted(type, ENTITIES_LAYER_NAME));
                }
            }
        }
        if (loadingBay == null) {
            var message = "No loadingBay object found in layer '%s'";
            throw new IllegalStateException(message.formatted(ENTITIES_LAYER_NAME));
        }
        if (chargingStation == null) {
            var message = "No chargingStation object found in layer '%s'";
            throw new IllegalStateException(message.formatted(ENTITIES_LAYER_NAME));
        }
        return new WarehouseLayout(
                shelves,
                zones,
                loadingBay,
                loadingBayExtent,
                chargingStation,
                chargingStationExtent
        );
    }

    private static List<ShelfSlot> parseShelves(TiledMap map, TileSize tileSize) {
        var shelves = new ArrayList<ShelfSlot>();
        for (var object : map.getLayers().get(SHELVES_LAYER_NAME).getObjects()) {
            var rectangleObject = requireRectangle(object, SHELVES_LAYER_NAME);
            int id = object.getProperties().get("id", Integer.class);
            var pos = toGridPos(rectangleObject.getRectangle(), tileSize);

            shelves.add(new ShelfSlot(new ShelfId(id), pos));
        }
        return shelves;
    }

    private static List<Zone> parseZones(TiledMap map, TileSize tileSize) {
        var zones = new ArrayList<Zone>();
        for (var object : map.getLayers().get(ZONES_LAYER_NAME).getObjects()) {
            var rectangleObject = requireRectangle(object, ZONES_LAYER_NAME);
            var zone = toZone(
                    object.getName(),
                    rectangleObject.getRectangle(),
                    tileSize
            );
            zones.add(zone);
        }
        return zones;
    }

    private static RectangleMapObject requireRectangle(MapObject object, String layerName) {
        if (!(object instanceof RectangleMapObject rectangleObject)) {
            var message = "Unsupported object shape in layer '" + layerName + "': " + object;
            throw new IllegalStateException(message);
        }
        return rectangleObject;
    }

    private static GridPos toGridPos(Rectangle rect, TileSize tileSize) {
        int x = Math.round(rect.x / tileSize.pixels());
        int y = Math.round(rect.y / tileSize.pixels());

        return new GridPos(x, y);
    }

    private static TileExtent toExtent(Rectangle rect, TileSize tileSize) {
        int widthTiles = Math.round(rect.width / tileSize.pixels());
        int heightTiles = Math.round(rect.height / tileSize.pixels());

        return new TileExtent(widthTiles, heightTiles);
    }

    private static Zone toZone(String name, Rectangle rect, TileSize tileSize) {
        int minX = Math.round(rect.x / tileSize.pixels());
        int minY = Math.round(rect.y / tileSize.pixels());
        int maxX = Math.round((rect.x + rect.width) / tileSize.pixels()) - 1;
        int maxY = Math.round((rect.y + rect.height) / tileSize.pixels()) - 1;

        return new Zone(name, new GridPos(minX, minY), new GridPos(maxX, maxY));
    }
}
