package dev.meowpow.boxbot.engine.entity;

import dev.meowpow.boxbot.engine.spatial.grid.Footprint;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.engine.spatial.grid.TileExtent;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static dev.meowpow.boxbot.engine.entity.LoadingBayFixtures.loadingBay;
import static dev.meowpow.boxbot.engine.entity.PackageFixtures.packageWithId;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class LoadingBayTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null footprint")
        void should_RejectFootprint_when_Null() {
            assertThatNullPointerException().isThrownBy(() -> new LoadingBay(null));
        }
    }

    @Nested
    @DisplayName("footprint")
    class FootprintMethodTests {

        @Test
        @DisplayName("Returns the supplied footprint")
        void should_ReturnFootprint_when_Requested() {
            var footprint = new Footprint(
                    new GridPos(1, 2),
                    new TileExtent(3, 4)
            );
            var loadingBay = new LoadingBay(footprint);

            assertThat(loadingBay.footprint()).isEqualTo(footprint);
        }
    }

    @Nested
    @DisplayName("capacity")
    class CapacityTests {

        @Test
        @DisplayName("Reports total and free tile counts when empty")
        void should_ReportTotalAndFreeTileCounts_when_Empty() {
            var loadingBay = loadingBay(3);

            assertThat(loadingBay.totalTiles()).isEqualTo(3);
            assertThat(loadingBay.freeTiles()).isEqualTo(3);
        }
    }

    @Nested
    @DisplayName("tryPlaceIncoming")
    class TryPlaceIncomingMethodTests {

        @Test
        @DisplayName("Places an incoming package on a free tile")
        void should_PlaceIncomingPackage_when_TileIsFree() {
            var loadingBay = loadingBay(1);
            var pkg = packageWithId(1);

            var placed = loadingBay.tryPlaceIncoming(pkg);

            assertThat(placed).isTrue();
            var placement = loadingBay.incomingPackagePlacements().first();
            assertThat(loadingBay.incomingPackages().get(placement.position())).isEqualTo(pkg);
            assertThat(loadingBay.outgoingPackages().isEmpty()).isTrue();
        }

        @Test
        @DisplayName("Exposes a live placement view")
        void should_ExposeLivePlacementView_when_IncomingPackageIsPlaced() {
            var loadingBay = loadingBay(1);
            var pkg = packageWithId(1);

            var placements = loadingBay.incomingPackagePlacements();
            loadingBay.tryPlaceIncoming(pkg);

            assertThat(placements.size()).isEqualTo(1);
            assertThat(placements.first().pkg()).isEqualTo(pkg);
        }

        @Test
        @DisplayName("Refuses an incoming package when the bay is full")
        void should_RefuseIncomingPackage_when_BayIsFull() {
            var loadingBay = loadingBay(1);

            loadingBay.tryPlaceOutgoing(packageWithId(1));

            assertThat(loadingBay.tryPlaceIncoming(packageWithId(2))).isFalse();
        }
    }

    @Nested
    @DisplayName("tryPlaceOutgoing")
    class TryPlaceOutgoingMethodTests {

        @Test
        @DisplayName("Places an outgoing package on a free tile")
        void should_PlaceOutgoingPackage_when_TileIsFree() {
            var loadingBay = loadingBay(1);
            var pkg = packageWithId(1);

            var placed = loadingBay.tryPlaceOutgoing(pkg);
            var placement = loadingBay.outgoingPackagePlacements().first();

            assertThat(placed).isTrue();
            assertThat(loadingBay.outgoingPackages().get(placement.position())).isEqualTo(pkg);
            assertThat(loadingBay.incomingPackages().isEmpty()).isTrue();
        }

        @Test
        @DisplayName("Refuses an outgoing package when the bay is full")
        void should_RefuseOutgoingPackage_when_BayIsFull() {
            var loadingBay = loadingBay(1);

            loadingBay.tryPlaceIncoming(packageWithId(1));

            assertThat(loadingBay.tryPlaceOutgoing(packageWithId(2))).isFalse();
        }
    }

    @Nested
    @DisplayName("remove")
    class RemoveMethodTests {

        @Test
        @DisplayName("Removes a stored package and frees its tile")
        void should_RemovePackage_when_PackageIsStored() {
            var loadingBay = loadingBay(1);
            var pkg = packageWithId(1);

            loadingBay.tryPlaceIncoming(pkg);
            loadingBay.remove(pkg);

            assertThat(loadingBay.incomingPackages().isEmpty()).isTrue();
            assertThat(loadingBay.freeTiles()).isEqualTo(1);
        }
    }

    @Nested
    @DisplayName("shipUpTo")
    class ShipUpToMethodTests {

        @Test
        @DisplayName("Ships outgoing packages up to the requested count in bay order")
        void should_ShipOutgoingPackages_when_RequestedCountIsAvailable() {
            var loadingBay = loadingBay(4);
            var first = packageWithId(1);
            var second = packageWithId(2);
            var third = packageWithId(3);
            var incoming = packageWithId(4);

            loadingBay.tryPlaceOutgoing(first);
            loadingBay.tryPlaceOutgoing(second);
            loadingBay.tryPlaceOutgoing(third);
            loadingBay.tryPlaceIncoming(incoming);

            var shipped = loadingBay.shipUpTo(2);

            assertThat(shipped).isEqualTo(2);
            assertThat(loadingBay.outgoingPackagePlacements().first().pkg()).isEqualTo(third);
            assertThat(loadingBay.incomingPackagePlacements().first().pkg()).isEqualTo(incoming);
        }
    }

    @Nested
    @DisplayName("shipNext")
    class ShipNextMethodTests {

        @Test
        @DisplayName("Removes and returns the next package awaiting shipment")
        void should_RemoveAndReturnPackage_when_OneIsAwaitingShipment() {
            var loadingBay = loadingBay(2);
            var first = packageWithId(1);
            var second = packageWithId(2);

            loadingBay.tryPlaceOutgoing(first);
            loadingBay.tryPlaceOutgoing(second);

            var shipped = loadingBay.shipNext();

            assertThat(shipped).isEqualTo(first);
            assertThat(loadingBay.outgoingPackagePlacements().first().pkg()).isEqualTo(second);
            assertThat(loadingBay.freeTiles()).isEqualTo(1);
        }

        @Test
        @DisplayName("Returns null when no package is awaiting shipment")
        void should_ReturnNull_when_NoneAreAwaitingShipment() {
            var loadingBay = loadingBay(1);

            assertThat(loadingBay.shipNext()).isNull();
        }
    }
}
