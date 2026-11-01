package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.config.SupplyConfig;
import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.LoadingBay;
import dev.meowpow.boxbot.engine.entity.OrderId;
import dev.meowpow.boxbot.engine.entity.OutboundOrder;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.robot.JobId;
import dev.meowpow.boxbot.engine.robot.JobType;
import dev.meowpow.boxbot.gdx.ArrayView;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;

import static dev.meowpow.boxbot.engine.TestWorldBuilder.world;
import static dev.meowpow.boxbot.engine.entity.PackageFixtures.packageWithId;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class TruckTest {

    private static final long TRUCK_SEED = 1L;
    private static final long DEMAND_SEED = 42L;

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Rejects a non-positive visit interval")
        void should_ThrowIllegalArgumentException_when_VisitIntervalIsNotPositive() {
            var world = world().build();

            assertThatIllegalArgumentException().isThrownBy(() ->
                    truck(world, 0, 0, 1)
            );
            assertThatIllegalArgumentException().isThrownBy(() ->
                    truck(world, -1, 0, 1)
            );
        }

        @Test
        @DisplayName("Creates the initial cargo with world package IDs and colored packages")
        void should_CreateInitialCargo_when_Constructed() {
            var world = world()
                    .withShelves(3)
                    .withLoadingBayCapacity(4)
                    .withOutgoingPackages(2)
                    .build();

            var truck = truck(world, 1, 0, 2);

            assertThat(world.nextPackageId()).isEqualTo(new PackageId(2));

            advance(truck, world, 4);

            var packages = world.loadingBay().incomingPackagePlacements();
            assertThat(packages.size()).isEqualTo(2);
            assertThat(packages.get(0).pkg().id()).isEqualTo(new PackageId(0));
            assertThat(packages.get(1).pkg().id()).isEqualTo(new PackageId(1));
            assertThat(packages.get(0).pkg().color()).isNotEqualTo(PackageColor.NONE);
            assertThat(packages.get(1).pkg().color()).isNotEqualTo(PackageColor.NONE);
        }

        @Test
        @DisplayName("Limits the cargo to colors with remaining storage quota")
        void should_LimitCargoToRemainingStorageQuota_when_OtherColorsAreAtQuota() {
            var world = world()
                    .withShelfPackages(List.of(PackageColor.RED, PackageColor.GREEN, PackageColor.NONE))
                    .withLoadingBayCapacity(3)
                    .withOutgoingPackages(1)
                    .build();

            var quota = new StorageQuota(new ColorDemand(DEMAND_SEED)).targets(world);
            var truck = truck(world, 1, 0, 3);
            var loadingBay = world.loadingBay();

            advance(truck, world, 2);

            var placements = loadingBay.incomingPackagePlacements();
            assertThat(placements.size()).isEqualTo(1);
            assertThat(placements.first().pkg().color()).isEqualTo(PackageColor.BLUE);

            for (var color : PackageColor.colored()) {
                var expected = quota.get(color, 0);
                assertThat(world.liveCount(color)).isLessThanOrEqualTo(expected);
            }
        }

        @Test
        @DisplayName("Brings exactly each color's deficit when the total deficit fits within capacity")
        void should_BringExactDeficits_when_TotalDeficitFitsWithinCapacity() {
            var world = world()
                    .withShelves(6)
                    .withLoadingBayCapacity(20)
                    .build();

            // seed 42 targets 6 shelves as RED=2, GREEN=2, BLUE=2; an empty
            // warehouse is short exactly that many of each, total deficit 6.
            var truck = truck(world, 1, 0, 10);
            fuelPickups(world, 6);

            advance(truck, world, 12);

            var placements = world.loadingBay().incomingPackagePlacements();
            assertThat(placements.size()).isEqualTo(6);
            assertThat(countColor(placements, PackageColor.RED)).isEqualTo(2);
            assertThat(countColor(placements, PackageColor.GREEN)).isEqualTo(2);
            assertThat(countColor(placements, PackageColor.BLUE)).isEqualTo(2);
        }

        @Test
        @DisplayName("Splits capacity proportional to deficit share when total deficit exceeds capacity")
        void should_SplitProportionalToDeficit_when_TotalDeficitExceedsCapacity() {
            var packages = List.of(
                    PackageColor.RED,
                    PackageColor.RED,
                    PackageColor.RED,
                    PackageColor.RED,
                    PackageColor.BLUE,
                    PackageColor.NONE,
                    PackageColor.NONE,
                    PackageColor.NONE,
                    PackageColor.NONE,
                    PackageColor.NONE
            );
            var world = world()
                    .withShelfPackages(packages)
                    .withLoadingBayCapacity(20)
                    .build();

            // seed 42 targets 10 shelves as RED=4, GREEN=3, BLUE=3.
            // RED is already at quota (deficit 0), GREEN is short 3,
            // BLUE is short 2. Total deficit 5 exceeds capacity 3, so
            // it's split proportional to deficit share: GREEN 3/5,
            // BLUE 2/5, largest-remainder rounded to GREEN=2, BLUE=1.
            var truck = truck(world, 1, 0, 3);
            fuelPickups(world, 3);

            advance(truck, world, 6);

            var placements = world.loadingBay().incomingPackagePlacements();
            assertThat(placements.size()).isEqualTo(3);
            assertThat(countColor(placements, PackageColor.RED)).isEqualTo(0);
            assertThat(countColor(placements, PackageColor.GREEN)).isEqualTo(2);
            assertThat(countColor(placements, PackageColor.BLUE)).isEqualTo(1);

            // neither color's allocation exceeds its own deficit
            assertThat(countColor(placements, PackageColor.GREEN)).isLessThanOrEqualTo(3);
            assertThat(countColor(placements, PackageColor.BLUE)).isLessThanOrEqualTo(2);
        }
    }

    @Nested
    @DisplayName("tick")
    class TickMethodTests {

        @Test
        @DisplayName("Performs no loading-bay operation before the visit interval elapses")
        void should_DoNothing_when_VisitIntervalHasNotElapsed() {
            var world = world()
                    .withShelves(1)
                    .withOutgoingPackages(1)
                    .build();

            var loadingBay = world.loadingBay();
            var truck = truck(world, 2, 0, 1);

            truck.tick(world);

            assertThat(loadingBay.outgoingPackages().size()).isEqualTo(1);
            assertThat(loadingBay.incomingPackages().isEmpty()).isTrue();
            assertThat(world.jobs().isEmpty()).isTrue();
            assertThat(world.score()).isZero();
        }

        @Test
        @DisplayName("Begins a visit with a pickup on the interval tick")
        void should_AttemptPickup_when_VisitIntervalElapses() {
            var world = world()
                    .withShelves(1)
                    .withOutgoingPackages(1)
                    .build();

            var loadingBay = world.loadingBay();
            var truck = truck(world, 2, 0, 1);

            advance(truck, world, 2);

            assertThat(loadingBay.outgoingPackages().isEmpty()).isTrue();
            assertThat(loadingBay.incomingPackages().isEmpty()).isTrue();
            assertThat(world.jobs().isEmpty()).isTrue();
        }

        @Test
        @DisplayName("Removes one outbound package and records one shipment after a pickup")
        void should_RemovePackageAndRecordShipment_when_PickupSucceeds() {
            var world = world()
                    .withShelves(1)
                    .withLoadingBayCapacity(2)
                    .withOutgoingPackages(2)
                    .build();

            var loadingBay = world.loadingBay();
            var truck = truck(world, 1, 0, 2);

            truck.tick(world);

            assertThat(loadingBay.outgoingPackages().size()).isEqualTo(1);
            assertThat(world.score()).isEqualTo(1);
        }

        @Test
        @DisplayName("Keeps a matching outbound order open until the truck departs")
        void should_KeepOutboundOrderOpen_when_PickupSucceedsButTruckHasNotDeparted() {
            var world = world()
                    .withShelves(3)
                    .withLoadingBayCapacity(2)
                    .withOutgoingPackages(1)
                    .build();

            var order = new OutboundOrder(
                    new OrderId(0),
                    PackageColor.RED,
                    100
            );
            world.startOutboundOrder(order);

            var truck = truck(world, 1, 0, 1);

            advance(truck, world, 2);

            assertThat(truck.isVisiting()).isTrue();
            assertThat(world.outboundOrders().size()).isEqualTo(1);
        }

        @Test
        @DisplayName("Completes a matching outbound order once the truck departs with it")
        void should_CompleteOutboundOrder_when_TruckDepartsWithMatchingPackage() {
            var world = world()
                    .withShelves(3)
                    .withLoadingBayCapacity(2)
                    .withOutgoingPackages(1)
                    .build();

            var order = new OutboundOrder(
                    new OrderId(0),
                    PackageColor.RED,
                    100
            );
            world.startOutboundOrder(order);

            var truck = truck(world, 1, 0, 1);

            advance(truck, world, 3);

            assertThat(truck.isVisiting()).isFalse();
            assertThat(world.outboundOrders().isEmpty()).isTrue();
        }

        @Test
        @DisplayName("Places a cargo package and creates its putaway job after a drop-off")
        void should_PlacePackageAndCreatePutawayJob_when_DropoffSucceeds() {
            var world = world()
                    .withShelves(2)
                    .withLoadingBayCapacity(2)
                    .withOutgoingPackages(1)
                    .build();

            var truck = truck(world, 1, 0, 1);

            truck.tick(world);

            var placements = world.loadingBay().incomingPackagePlacements();
            var jobs = world.jobs();

            assertThat(placements.size()).isEqualTo(1);
            assertThat(jobs.size()).isEqualTo(1);

            var job = jobs.first();
            assertThat(job.id()).isEqualTo(new JobId("putaway-1"));
            assertThat(job.type()).isEqualTo(JobType.PUTAWAY);
            assertThat(job.shelfId()).isIn(
                    world.shelves().get(0).id(),
                    world.shelves().get(1).id()
            );
            assertThat(job.pkg()).isEqualTo(placements.first().pkg());
            assertThat(job.arrivalTick()).isEqualTo(world.currentTick());
        }

        @Test
        @DisplayName("Alternates successful pickups and drop-offs")
        void should_AlternateOperations_when_PickupsAndDropoffsAreAvailable() {
            var packages = List.of(
                    PackageColor.RED,
                    PackageColor.GREEN,
                    PackageColor.NONE
            );
            var world = world()
                    .withShelfPackages(packages)
                    .withLoadingBayCapacity(4)
                    .withOutgoingPackages(2)
                    .build();

            var loadingBay = world.loadingBay();
            var truck = truck(world, 1, 0, 2);

            truck.tick(world);
            assertThat(loadingBay.outgoingPackages().size()).isEqualTo(1);
            assertThat(loadingBay.incomingPackages().isEmpty()).isTrue();

            truck.tick(world);

            assertThat(loadingBay.outgoingPackages().size()).isEqualTo(1);
            assertThat(loadingBay.incomingPackages().size()).isEqualTo(1);

            truck.tick(world);

            assertThat(loadingBay.outgoingPackages().isEmpty()).isTrue();
            assertThat(loadingBay.incomingPackages().size()).isEqualTo(1);
        }

        @Test
        @DisplayName("Keeps picking up when the cargo is exhausted before visit capacity")
        void should_ContinuePickingUp_when_CargoIsExhaustedBeforeVisitCapacityIsReached() {
            var world = world()
                    .withShelfPackages(List.of(PackageColor.RED, PackageColor.GREEN, PackageColor.NONE))
                    .withLoadingBayCapacity(3)
                    .withOutgoingPackages(3)
                    .build();

            var loadingBay = world.loadingBay();
            var truck = truck(world, 1, 0, 3);

            advance(truck, world, 4);

            assertThat(loadingBay.outgoingPackages().size()).isZero();
            assertThat(loadingBay.incomingPackages().size()).isEqualTo(1);
            assertThat(world.score()).isEqualTo(3);
        }

        @Test
        @DisplayName("Falls back to unloading when no outbound packages are available")
        void should_UnloadCargo_when_PickupIsUnavailable() {
            var world = world()
                    .withShelves(3)
                    .withLoadingBayCapacity(3)
                    .build();

            var loadingBay = world.loadingBay();
            var truck = truck(world, 1, 0, 3);
            advance(truck, world, 3);

            assertThat(loadingBay.incomingPackages().size()).isEqualTo(3);
            assertThat(loadingBay.outgoingPackages().isEmpty()).isTrue();
            assertThat(world.jobs().size()).isEqualTo(3);
            assertThat(world.score()).isZero();
        }

        @Test
        @DisplayName("Retries a blocked drop-off without switching to pickup")
        void should_RetryDropoff_when_BaySpaceBecomesAvailable() {
            var world = world()
                    .withShelfPackages(List.of(PackageColor.RED, PackageColor.GREEN, PackageColor.NONE))
                    .withOutgoingPackages(1)
                    .build();

            var loadingBay = world.loadingBay();
            var truck = truck(world, 1, 0, 2);

            truck.tick(world);
            var blocker = packageWithId(10);
            loadingBay.tryPlaceIncoming(blocker);

            truck.tick(world);

            var placements = loadingBay.incomingPackagePlacements();
            assertThat(placements.first().pkg()).isEqualTo(blocker);
            assertThat(world.jobs().isEmpty()).isTrue();

            loadingBay.remove(blocker);
            truck.tick(world);

            assertThat(loadingBay.incomingPackages().size()).isEqualTo(1);
            assertThat(world.jobs().size()).isEqualTo(1);
        }

        @Test
        @DisplayName("Waits the configured number of full ticks between successful operations")
        void should_WaitOperationDelay_when_PreviousOperationSucceeded() {
            var world = world()
                    .withShelfPackages(List.of(PackageColor.RED, PackageColor.GREEN, PackageColor.NONE))
                    .withOutgoingPackages(1)
                    .build();

            var loadingBay = world.loadingBay();
            var truck = truck(world, 1, 2, 2);

            truck.tick(world);

            advance(truck, world, 2);
            assertThat(loadingBay.incomingPackages().isEmpty()).isTrue();
            assertThat(world.jobs().isEmpty()).isTrue();

            truck.tick(world);
            assertThat(loadingBay.incomingPackages().size()).isEqualTo(1);
            assertThat(world.jobs().size()).isEqualTo(1);
        }

        @Test
        @DisplayName("Departs after completing both operations and prepares next cargo")
        void should_PrepareFreshCargo_when_VisitIsComplete() {
            var world = world()
                    .withShelves(3)
                    .withLoadingBayCapacity(2)
                    .withOutgoingPackages(1)
                    .build();

            var loadingBay = world.loadingBay();
            var truck = truck(world, 1, 0, 1);

            advance(truck, world, 3);
            var placements = loadingBay.incomingPackagePlacements();
            var firstDelivery = placements.first().pkg();

            truck.tick(world);
            loadingBay.remove(firstDelivery);
            loadingBay.tryPlaceOutgoing(packageWithId(10));

            advance(truck, world, 2);

            var secondDelivery = loadingBay.incomingPackagePlacements().first().pkg();
            assertThat(firstDelivery.id()).isEqualTo(new PackageId(0));
            assertThat(secondDelivery.id()).isEqualTo(new PackageId(1));
            assertThat(world.jobs().size()).isEqualTo(2);
            assertThat(world.jobs().get(0).id()).isEqualTo(new JobId("putaway-1"));
            assertThat(world.jobs().get(1).id()).isEqualTo(new JobId("putaway-2"));
        }

        @Test
        @DisplayName("Uses the truck seed to choose repeatable shelf suggestions")
        void should_ChooseSameShelf_when_SeedAndWorldAreTheSame() {
            var firstWorld = world()
                    .withShelves(3)
                    .withLoadingBayCapacity(2)
                    .withOutgoingPackages(1)
                    .build();

            var secondWorld = world()
                    .withShelves(3)
                    .withLoadingBayCapacity(2)
                    .withOutgoingPackages(1)
                    .build();

            var firstTruck = truck(firstWorld, 1, 0, 1);
            var secondTruck = truck(secondWorld, 1, 0, 1);

            advance(firstTruck, firstWorld, 2);
            advance(secondTruck, secondWorld, 2);

            var actual = firstWorld.jobs().first().shelfId();
            var expected = secondWorld.jobs().first().shelfId();

            assertThat(actual).isEqualTo(expected);
        }
    }

    @Nested
    @DisplayName("cargo")
    class CargoMethodTests {

        @Test
        @DisplayName("Returns the current cargo")
        void should_ReturnCurrentCargo_when_Queried() {
            var world = world()
                    .withShelves(3)
                    .withLoadingBayCapacity(4)
                    .build();

            var truck = truck(world, 1, 0, 2);

            assertThat(truck.cargo().outboundTotal()).isEqualTo(2);
        }
    }

    @Nested
    @DisplayName("isVisiting")
    class IsVisitingMethodTests {

        @Test
        @DisplayName("Starts false before any visit begins")
        void should_BeFalse_when_NoVisitHasBegun() {
            var world = world().withShelves(1).build();
            var truck = truck(world, 2, 0, 1);

            assertThat(truck.isVisiting()).isFalse();
        }

        @Test
        @DisplayName("Becomes true once a visit begins")
        void should_BeTrue_when_VisitBegins() {
            var world = world()
                    .withShelves(1)
                    .withOutgoingPackages(1)
                    .build();

            var truck = truck(world, 1, 0, 1);

            truck.tick(world);

            assertThat(truck.isVisiting()).isTrue();
        }
    }

    @Nested
    @DisplayName("ticksUntilNextVisit")
    class TicksUntilNextVisitMethodTests {

        @Test
        @DisplayName("Starts at the full visit interval")
        void should_StartAtFullInterval_when_NoVisitHasBegun() {
            var world = world().withShelves(1).build();
            var truck = truck(world, 3, 0, 1);

            assertThat(truck.ticksUntilNextVisit()).isEqualTo(3);
        }

        @Test
        @DisplayName("Decreases as ticks elapse before a visit begins")
        void should_Decrease_when_TicksElapseBeforeVisitBegins() {
            var world = world().withShelves(1).build();
            var truck = truck(world, 3, 0, 1);

            truck.tick(world);

            assertThat(truck.ticksUntilNextVisit()).isEqualTo(2);
        }
    }

    private static Truck truck(
            World world,
            int visitIntervalTicks,
            int operationDelayTicks,
            int capacity
    ) {
        var planner = new SupplyPlanner(
                new ColorDemand(DEMAND_SEED),
                new SupplyConfig(2400, 0.35, 0.15)
        );
        return new Truck(
                TRUCK_SEED,
                planner,
                world,
                visitIntervalTicks,
                operationDelayTicks,
                capacity
        );
    }

    private static void advance(Truck truck, World world, int ticks) {
        for (int i = 0; i < ticks; i++) {
            truck.tick(world);
        }
    }

    private static void fuelPickups(World world, int count) {
        for (int i = 0; i < count; i++) {
            world.loadingBay().tryPlaceOutgoing(packageWithId(1000 + i));
        }
    }

    private static int countColor(
            ArrayView<LoadingBay.PackagePlacement> placements,
            PackageColor color
    ) {
        int count = 0;
        for (int i = 0; i < placements.size(); i++) {
            if (placements.get(i).pkg().color() == color) {
                count++;
            }
        }
        return count;
    }
}
