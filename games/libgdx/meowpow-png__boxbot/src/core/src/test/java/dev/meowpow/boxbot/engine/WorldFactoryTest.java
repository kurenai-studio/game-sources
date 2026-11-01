package dev.meowpow.boxbot.engine;

import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.layout.ShelfSlot;
import dev.meowpow.boxbot.engine.layout.WarehouseLayout;
import dev.meowpow.boxbot.engine.spatial.grid.Grid;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.engine.spatial.grid.TileExtent;
import dev.meowpow.boxbot.engine.spatial.grid.Zone;
import dev.meowpow.boxbot.engine.time.SimulationClock;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;

import static dev.meowpow.boxbot.engine.spatial.grid.FootprintFixtures.tilesOf;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalStateException;

class WorldFactoryTest {

    @Nested
    @DisplayName("fromLayout")
    class FromLayoutMethodTests {

        @Test
        @DisplayName("Creates zone-labelled shelves and facilities from the layout")
        void should_CreateWorldContents_when_LayoutIsValid() {
            var layout = new WarehouseLayout(
                    List.of(
                            shelfSlot(2, 2, 0),
                            shelfSlot(1, 1, 0),
                            shelfSlot(3, 0, 1)
                    ),
                    List.of(
                            zone("A", 0, 0, 2, 0),
                            zone("B", 0, 1, 2, 1)
                    ),
                    new GridPos(0, 2),
                    new TileExtent(1, 1),
                    new GridPos(1, 2),
                    new TileExtent(1, 1)
            );
            var world = worldFrom(layout);
            var robot = world.robot();
            var loadingBay = world.loadingBay();
            var chargingStation = world.chargingStation();
            var shelves = world.shelves();

            assertThat(robot.position()).isEqualTo(layout.loadingBay());
            assertThat(robot.battery().capacity()).isEqualTo(50);
            assertThat(tilesOf(loadingBay.footprint())).containsExactly(new GridPos(0, 2));
            assertThat(tilesOf(chargingStation.footprint())).containsExactly(new GridPos(1, 2));

            assertThat(shelves.size()).isEqualTo(3);
            assertThat(shelves.get(0).label()).isEqualTo("A1");
            assertThat(shelves.get(1).label()).isEqualTo("A2");
            assertThat(shelves.get(2).label()).isEqualTo("B1");
        }

        @Test
        @DisplayName("Rejects a layout with a shelf outside every zone")
        void should_RejectLayout_when_ShelfIsOutsideEveryZone() {
            var layout = new WarehouseLayout(
                    List.of(shelfSlot(1, 0, 0)),
                    List.of(zone("A", 1, 1, 2, 2)),
                    new GridPos(0, 2),
                    new TileExtent(1, 1),
                    new GridPos(1, 2),
                    new TileExtent(1, 1)
            );
            assertThatIllegalStateException().isThrownBy(() -> worldFrom(layout));
        }

        @Test
        @DisplayName("Rejects a layout with a shelf in multiple zones")
        void should_RejectLayout_when_ShelfIsInMultipleZones() {
            var layout = new WarehouseLayout(
                    List.of(shelfSlot(1, 1, 1)),
                    List.of(
                            zone("A", 0, 0, 1, 1),
                            zone("B", 1, 1, 2, 2)
                    ),
                    new GridPos(0, 2),
                    new TileExtent(1, 1),
                    new GridPos(1, 2),
                    new TileExtent(1, 1)
            );
            assertThatIllegalStateException().isThrownBy(() -> worldFrom(layout));
        }
    }

    private static ShelfSlot shelfSlot(int id, int x, int y) {
        return new ShelfSlot(new ShelfId(id), new GridPos(x, y));
    }

    private static Zone zone(String name, int x1, int y1, int x2, int y2) {
        return new Zone(name, new GridPos(x1, y1), new GridPos(x2, y2));
    }

    private static World worldFrom(WarehouseLayout layout) {
        return WorldFactory.fromLayout(
                layout,
                new Grid(3, 3),
                50,
                new SimulationClock()
        );
    }
}
