package dev.meowpow.boxbot.engine;

import dev.meowpow.boxbot.engine.entity.OrderId;
import dev.meowpow.boxbot.engine.entity.OutboundOrder;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.robot.JobType;
import dev.meowpow.boxbot.engine.time.SimulationClock;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;

import static dev.meowpow.boxbot.engine.TestWorldBuilder.world;
import static dev.meowpow.boxbot.engine.entity.PackageFixtures.packageWithId;
import static dev.meowpow.boxbot.engine.robot.RobotFixtures.robotJob;
import static org.assertj.core.api.Assertions.*;

class WorldTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null robot")
        void should_RejectRobot_when_RobotIsNull() {
            var existingWorld = world().build();

            assertThatNullPointerException().isThrownBy(() -> new World(
                    null,
                    existingWorld.shelves(),
                    existingWorld.loadingBay(),
                    existingWorld.chargingStation(),
                    existingWorld.grid(),
                    new SimulationClock()
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects null shelves")
        void should_RejectShelves_when_ShelvesAreNull() {
            var existingWorld = world().build();

            assertThatNullPointerException().isThrownBy(() -> new World(
                    existingWorld.robot(),
                    null,
                    existingWorld.loadingBay(),
                    existingWorld.chargingStation(),
                    existingWorld.grid(),
                    new SimulationClock()
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null loading bay")
        void should_RejectLoadingBay_when_LoadingBayIsNull() {
            var existingWorld = world().build();

            assertThatNullPointerException().isThrownBy(() -> new World(
                    existingWorld.robot(),
                    existingWorld.shelves(),
                    null,
                    existingWorld.chargingStation(),
                    existingWorld.grid(),
                    new SimulationClock()
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null charging station")
        void should_RejectChargingStation_when_ChargingStationIsNull() {
            var existingWorld = world().build();

            assertThatNullPointerException().isThrownBy(() -> new World(
                    existingWorld.robot(),
                    existingWorld.shelves(),
                    existingWorld.loadingBay(),
                    null,
                    existingWorld.grid(),
                    new SimulationClock()
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null grid")
        void should_RejectGrid_when_GridIsNull() {
            var existingWorld = world().build();

            assertThatNullPointerException().isThrownBy(() -> new World(
                    existingWorld.robot(),
                    existingWorld.shelves(),
                    existingWorld.loadingBay(),
                    existingWorld.chargingStation(),
                    null,
                    new SimulationClock()
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null clock")
        void should_RejectClock_when_ClockIsNull() {
            var existingWorld = world().build();

            assertThatNullPointerException().isThrownBy(() -> new World(
                    existingWorld.robot(),
                    existingWorld.shelves(),
                    existingWorld.loadingBay(),
                    existingWorld.chargingStation(),
                    existingWorld.grid(),
                    null
            ));
        }
    }

    @Nested
    @DisplayName("nextPackageId")
    class NextPackageIdMethodTests {

        @Test
        @DisplayName("Starts at zero")
        void should_StartAtZero_when_NoIdsIssuedYet() {
            var world = world().build();
            var packageId = world.nextPackageId();

            assertThat(packageId).isEqualTo(new PackageId(0));
        }

        @Test
        @DisplayName("Increases by one on each call")
        void should_IncreaseByOne_when_CalledRepeatedly() {
            var world = world().build();

            var first = world.nextPackageId();
            var second = world.nextPackageId();
            var third = world.nextPackageId();

            assertThat(List.of(first, second, third)).containsExactly(
                    new PackageId(0),
                    new PackageId(1),
                    new PackageId(2)
            );
        }
    }

    @Nested
    @DisplayName("jobs")
    class JobsMethodTests {

        @Test
        @DisplayName("Returns a live read-only view of pending jobs")
        void should_ReturnLiveReadOnlyView_when_JobIsAdded() {
            var world = world().withShelves(1).build();
            var job = robotJob(world, "job-1", JobType.PUTAWAY, packageWithId(1));
            var jobs = world.jobs();

            world.addJob(job);

            assertThat(jobs.size()).isEqualTo(1);
            assertThat(jobs.first()).isEqualTo(job);
            assertThat(world.jobs()).isSameAs(jobs);
        }

        @Test
        @DisplayName("Removes a pending job")
        void should_RemoveJob_when_JobIsPending() {
            var world = world().withShelves(1).build();
            var job = robotJob(world, "job-1", JobType.PUTAWAY, packageWithId(1));

            world.addJob(job);
            world.removeJob(job);

            assertThat(world.jobs().isEmpty()).isTrue();
        }

        @Test
        @DisplayName("Reports job changes until they are consumed")
        void should_ReportJobChanges_when_JobIsAddedOrRemoved() {
            var world = world().withShelves(1).build();
            var job = robotJob(world, "job-1", JobType.PUTAWAY, packageWithId(1));

            assertThat(world.consumeJobChanges()).isFalse();

            world.addJob(job);
            assertThat(world.consumeJobChanges()).isTrue();
            assertThat(world.consumeJobChanges()).isFalse();

            world.removeJob(job);
            assertThat(world.consumeJobChanges()).isTrue();
        }
    }

    @Nested
    @DisplayName("shelf packages")
    class ShelfPackagesTests {

        @Test
        @DisplayName("Reports occupancy changes until they are consumed")
        void should_ReportShelfChanges_when_PackageOccupancyChanges() {
            var world = world().withShelves(1).build();
            var shelfId = world.shelves().first().id();

            assertThat(world.consumeShelfChanges()).isFalse();

            world.setShelfPackage(shelfId, packageWithId(1));
            assertThat(world.consumeShelfChanges()).isTrue();
            assertThat(world.consumeShelfChanges()).isFalse();
        }
    }

    @Nested
    @DisplayName("shelf reservations")
    class ShelfReservationsTests {

        @Test
        @DisplayName("Marks and releases a shelf reservation")
        void should_ReleaseReservation_when_ShelfWasReserved() {
            var world = world().withShelves(1).build();
            var shelfId = world.shelves().first().id();

            world.reserveShelf(shelfId);
            assertThat(world.isShelfReserved(shelfId)).isTrue();

            world.releaseShelf(shelfId);
            assertThat(world.isShelfReserved(shelfId)).isFalse();
        }
    }

    @Nested
    @DisplayName("carriedJobType")
    class CarriedJobTypeMethodTests {

        @Test
        @SuppressWarnings("ConstantValue")
        @DisplayName("Retains and clears the carried job type")
        void should_ClearCarriedJobType_when_SetToNull() {
            var world = world().build();
            world.setCarriedJobType(JobType.RETRIEVAL);

            assertThat(world.carriedJobType()).isEqualTo(JobType.RETRIEVAL);

            world.setCarriedJobType(null);
            assertThat(world.carriedJobType()).isNull();
        }
    }

    @Nested
    @DisplayName("outboundOrders")
    class OutboundOrdersMethodTests {

        @Test
        @DisplayName("Returns a live read-only view of tracked orders")
        void should_ReturnLiveReadOnlyView_when_OrderIsStarted() {
            var world = world().build();
            var order = outboundOrder(0, PackageColor.BLUE, 5);
            var orders = world.outboundOrders();

            world.startOutboundOrder(order);

            assertThat(orders.size()).isEqualTo(1);
            assertThat(orders.first()).isEqualTo(order);
            assertThat(world.outboundOrders()).isSameAs(orders);
        }
    }

    @Nested
    @DisplayName("completeOutboundOrder")
    class CompleteOutboundOrderMethodTests {

        @Test
        @DisplayName("Completes the earliest order for the requested color")
        void should_RemoveEarliestOrder_when_OrdersHaveMatchingColor() {
            var world = world().build();
            var firstOrder = outboundOrder(0, PackageColor.BLUE, 5);
            var secondOrder = outboundOrder(1, PackageColor.BLUE, 6);

            world.startOutboundOrder(firstOrder);
            world.startOutboundOrder(secondOrder);

            world.completeOutboundOrder(PackageColor.BLUE);

            assertThat(world.outboundOrders().size()).isEqualTo(1);
            assertThat(world.outboundOrders().first()).isEqualTo(secondOrder);
        }

        @Test
        @DisplayName("Leaves orders unchanged when no color matches")
        void should_NotRemoveOrder_when_NoOrderHasRequestedColor() {
            var world = world().build();
            var order = outboundOrder(0, PackageColor.BLUE, 5);

            world.startOutboundOrder(order);
            world.completeOutboundOrder(PackageColor.RED);

            assertThat(world.outboundOrders().size()).isEqualTo(1);
            assertThat(world.outboundOrders().first()).isEqualTo(order);
        }
    }

    @Nested
    @DisplayName("expireOutboundOrder")
    class ExpireOutboundOrderMethodTests {

        @Test
        @DisplayName("Rejects an order that is not tracked")
        void should_RejectOrder_when_OrderIsNotTracked() {
            var world = world().build();
            var order = outboundOrder(0, PackageColor.BLUE, 5);

            assertThatIllegalArgumentException().isThrownBy(() ->
                    world.expireOutboundOrder(order)
            );
        }

        @Test
        @DisplayName("Stops tracking the order and records a failure")
        void should_RecordFailure_when_TrackedOrderExpires() {
            var world = world().build();
            var order = outboundOrder(0, PackageColor.BLUE, 5);

            world.startOutboundOrder(order);
            world.expireOutboundOrder(order);

            assertThat(world.outboundOrders().isEmpty()).isTrue();
            assertThat(world.shipmentFailures()).isEqualTo(1);
        }

        @Test
        @DisplayName("Leaves a matching package carried for retrieval untouched")
        void should_NotAffectCarriedPackage_when_CarriedPackageMatchesOrder() {
            var world = world().build();
            var pkg = packageWithId(1, PackageColor.BLUE);
            var order = outboundOrder(0, PackageColor.BLUE, 5);

            world.robot().pickUp(pkg);
            world.setCarriedJobType(JobType.RETRIEVAL);
            world.startOutboundOrder(order);
            world.expireOutboundOrder(order);

            var actual = world.robot().carriedPackage();

            assertThat(actual).isEqualTo(pkg);
        }

        @Test
        @DisplayName("Leaves a matching package on a reserved shelf untouched")
        void should_NotAffectReservedShelfPackage_when_ShelfPackageMatchesOrder() {
            var world = world().withShelfPackage(PackageColor.BLUE).build();
            var shelf = world.shelves().first();
            var order = outboundOrder(0, PackageColor.BLUE, 5);

            world.reserveShelf(shelf.id());
            world.startOutboundOrder(order);
            world.expireOutboundOrder(order);

            var actual = shelf.occupyingPackage();
            var expected = packageWithId(0, PackageColor.BLUE);

            assertThat(actual).isEqualTo(expected);
        }
    }

    @Nested
    @DisplayName("elapsedSeconds")
    class ElapsedSecondsMethodTests {

        @Test
        @DisplayName("Starts at zero")
        void should_StartAtZero_when_NewlyBuilt() {
            assertThat(world().build().elapsedSeconds()).isZero();
        }
    }

    @Nested
    @DisplayName("tick")
    class TickMethodTests {

        @Test
        @DisplayName("Advances the current tick")
        void should_AdvanceCurrentTick_when_Ticked() {
            var world = world().build();

            world.tick();

            assertThat(world.currentTick()).isEqualTo(1);
        }

        @Test
        @DisplayName("Expires orders at their delivery deadline")
        void should_ExpireOrder_when_DeadlineIsReached() {
            var world = world().build();
            var order = outboundOrder(0, PackageColor.BLUE, 1);

            world.startOutboundOrder(order);
            world.tick();

            assertThat(world.outboundOrders().isEmpty()).isTrue();
            assertThat(world.shipmentFailures()).isEqualTo(1);
        }

        @Test
        @DisplayName("Does not expire a completed order")
        void should_NotExpireOrder_when_OrderWasCompleted() {
            var world = world().build();
            var order = outboundOrder(0, PackageColor.BLUE, 1);

            world.startOutboundOrder(order);
            world.completeOutboundOrder(PackageColor.BLUE);

            world.tick();

            assertThat(world.shipmentFailures()).isZero();
        }
    }

    @Nested
    @DisplayName("score and failures")
    class ScoreAndFailuresTests {

        @Test
        @DisplayName("Reports failure once the configured limit is reached")
        void should_ReportFailure_when_FailureLimitIsReached() {
            var world = world().build();
            var order = outboundOrder(0, PackageColor.BLUE, 5);

            world.startOutboundOrder(order);
            world.expireOutboundOrder(order);

            assertThat(world.hasFailed(2)).isFalse();
            assertThat(world.hasFailed(1)).isTrue();
        }

        @Test
        @DisplayName("Accumulates completed shipments")
        void should_AccumulateScore_when_ShipmentsAreRecorded() {
            var world = world().build();

            world.recordShipment(2);
            world.recordShipment(3);

            assertThat(world.score()).isEqualTo(5);
        }
    }

    @SuppressWarnings("SameParameterValue")
    private static OutboundOrder outboundOrder(int id, PackageColor color, int deadlineTick) {
        return new OutboundOrder(new OrderId(id), color, deadlineTick);
    }
}
