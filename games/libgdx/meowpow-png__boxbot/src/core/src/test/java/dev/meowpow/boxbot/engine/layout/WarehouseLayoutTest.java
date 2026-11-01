package dev.meowpow.boxbot.engine.layout;

import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.engine.spatial.grid.TileExtent;
import dev.meowpow.boxbot.engine.spatial.grid.Zone;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class WarehouseLayoutTest {

    private static final List<ShelfSlot> SHELVES = List.of();
    private static final List<Zone> ZONES = List.of();
    private static final GridPos LOADING_BAY = new GridPos(1, 2);
    private static final TileExtent LOADING_BAY_EXTENT = new TileExtent(3, 4);
    private static final GridPos CHARGING_STATION = new GridPos(5, 6);
    private static final TileExtent CHARGING_STATION_EXTENT = new TileExtent(7, 8);

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains valid layout data")
        void should_RetainValues_when_ValuesAreValid() {
            var layout = layout();

            assertThat(layout.shelves()).isEqualTo(SHELVES);
            assertThat(layout.zones()).isEqualTo(ZONES);
            assertThat(layout.loadingBay()).isEqualTo(LOADING_BAY);
            assertThat(layout.loadingBayExtent()).isEqualTo(LOADING_BAY_EXTENT);
            assertThat(layout.chargingStation()).isEqualTo(CHARGING_STATION);
            assertThat(layout.chargingStationExtent()).isEqualTo(CHARGING_STATION_EXTENT);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null shelf-slot list")
        void should_RejectShelves_when_ShelvesAreNull() {
            assertThatNullPointerException().isThrownBy(() -> new WarehouseLayout(
                    null,
                    ZONES,
                    LOADING_BAY,
                    LOADING_BAY_EXTENT,
                    CHARGING_STATION,
                    CHARGING_STATION_EXTENT
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null zone list")
        void should_RejectZones_when_ZonesAreNull() {
            assertThatNullPointerException().isThrownBy(() -> new WarehouseLayout(
                    SHELVES,
                    null,
                    LOADING_BAY,
                    LOADING_BAY_EXTENT,
                    CHARGING_STATION,
                    CHARGING_STATION_EXTENT
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null loading-bay position")
        void should_RejectLoadingBay_when_LoadingBayIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new WarehouseLayout(
                    SHELVES,
                    ZONES,
                    null,
                    LOADING_BAY_EXTENT,
                    CHARGING_STATION,
                    CHARGING_STATION_EXTENT
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null loading-bay extent")
        void should_RejectLoadingBayExtent_when_LoadingBayExtentIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new WarehouseLayout(
                    SHELVES,
                    ZONES,
                    LOADING_BAY,
                    null,
                    CHARGING_STATION,
                    CHARGING_STATION_EXTENT
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null charging-station position")
        void should_RejectChargingStation_when_ChargingStationIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new WarehouseLayout(
                    SHELVES,
                    ZONES,
                    LOADING_BAY,
                    LOADING_BAY_EXTENT,
                    null,
                    CHARGING_STATION_EXTENT
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null charging-station extent")
        void should_RejectChargingStationExtent_when_ChargingStationExtentIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new WarehouseLayout(
                    SHELVES,
                    ZONES,
                    LOADING_BAY,
                    LOADING_BAY_EXTENT,
                    CHARGING_STATION,
                    null
            ));
        }
    }

    private static WarehouseLayout layout() {
        return new WarehouseLayout(
                SHELVES,
                ZONES,
                LOADING_BAY,
                LOADING_BAY_EXTENT,
                CHARGING_STATION,
                CHARGING_STATION_EXTENT
        );
    }
}
