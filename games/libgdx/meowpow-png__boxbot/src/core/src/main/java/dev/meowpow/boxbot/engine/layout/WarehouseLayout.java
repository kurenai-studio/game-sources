package dev.meowpow.boxbot.engine.layout;

import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.engine.spatial.grid.TileExtent;
import dev.meowpow.boxbot.engine.spatial.grid.Zone;

import java.util.List;
import java.util.Objects;

/**
 * The warehouse's fixed layout.
 * <p>
 * Parsed once from the map and unchanged for the run.
 *
 * @param shelves every shelf slot's identity and position
 * @param zones the named regions used to group and label shelves
 * @param loadingBay the loading bay's anchor position
 * @param loadingBayExtent the loading bay's size, in tiles
 * @param chargingStation the charging station's anchor position
 * @param chargingStationExtent the charging station's size, in tiles
 */
public record WarehouseLayout(
        List<ShelfSlot> shelves,
        List<Zone> zones,
        GridPos loadingBay,
        TileExtent loadingBayExtent,
        GridPos chargingStation,
        TileExtent chargingStationExtent
) {

    /**
     * @throws NullPointerException if any argument is null
     */
    public WarehouseLayout {
        Objects.requireNonNull(shelves, "shelves must not be null");
        Objects.requireNonNull(zones, "zones must not be null");
        Objects.requireNonNull(loadingBay, "loadingBay must not be null");
        Objects.requireNonNull(loadingBayExtent, "loadingBayExtent must not be null");
        Objects.requireNonNull(chargingStation, "chargingStation must not be null");
        Objects.requireNonNull(chargingStationExtent, "chargingStationExtent must not be null");
    }
}
