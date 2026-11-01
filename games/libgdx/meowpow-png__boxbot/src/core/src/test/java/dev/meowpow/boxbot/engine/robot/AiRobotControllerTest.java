package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.entity.OrderId;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.GdxCollections;

import com.badlogic.gdx.utils.Array;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.Set;

import static dev.meowpow.boxbot.engine.robot.RobotFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;

class AiRobotControllerTest {

    private static final int NON_URGENT_DEADLINE_TICK = 1_000;

    private final AiRobotController controller = new AiRobotController(0);

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Rejects a negative urgency threshold")
        void should_RejectUrgentThresholdTicks_when_Negative() {
            var thrown = catchThrowable(() -> new AiRobotController(-1));
            assertThat(thrown).isInstanceOf(IllegalArgumentException.class);
        }
    }

    @Nested
    @DisplayName("decide")
    class DecideMethodTests {

        @Test
        @DisplayName("Heads to the bay for a carried retrieval package when space is available")
        void should_GoToBay_when_CarryingRetrievalPackageAndBayHasSpace() {
            var robot = carryingRobot(JobType.RETRIEVAL, 0);
            var observation = new ObservationBuilder(robot)
                    .freeBayTiles(1)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.GoToBay();

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Stores a retrieved package at the nearest empty shelf when the bay is full")
        void should_StoreAtNearestFreeShelf_when_CarryingRetrievalPackageAndBayIsFull() {
            var robot = carryingRobot(JobType.RETRIEVAL, 100);
            var fartherShelf = emptyShelf(2, 5, 0);
            var nearestShelf = emptyShelf(3, 1, 0);
            var shelves = arrayViewOf(
                    occupiedShelf(1, 0, 0, PackageColor.BLUE),
                    fartherShelf,
                    nearestShelf
            );
            var observation = new ObservationBuilder(robot)
                    .shelves(shelves)
                    .freeBayTiles(0)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.StoreAt(nearestShelf.shelfId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Stores a putaway package at the first unoccupied shelf")
        void should_StoreAtFirstFreeShelf_when_CarryingPutawayPackage() {
            var robot = carryingRobot(JobType.PUTAWAY, 100);
            var firstFreeShelf = emptyShelf(2, 1, 0);
            var shelves = arrayViewOf(
                    occupiedShelf(1, 0, 0, PackageColor.BLUE),
                    firstFreeShelf,
                    emptyShelf(3, 2, 0)
            );
            var observation = new ObservationBuilder(robot)
                    .shelves(shelves)
                    .freeBayTiles(0)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.StoreAt(firstFreeShelf.shelfId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Stores a putaway package at a free shelf despite a low battery")
        void should_StoreAtShelf_when_CarryingPutawayPackageDespiteLowBattery() {
            var robot = carryingRobot(JobType.PUTAWAY, 0);
            var freeShelf = emptyShelf(2, 1, 0);
            var shelves = arrayViewOf(occupiedShelf(1, 0, 0, PackageColor.BLUE), freeShelf);
            var observation = new ObservationBuilder(robot)
                    .shelves(shelves)
                    .freeBayTiles(0)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.StoreAt(freeShelf.shelfId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Idles when carrying a package with no available shelf")
        void should_Idle_when_CarryingPackageAndNoShelfIsAvailable() {
            var robot = carryingRobot(JobType.PUTAWAY, 100);
            var shelves = arrayViewOf(occupiedShelf(1, 0, 0, PackageColor.BLUE));
            var observation = new ObservationBuilder(robot)
                    .shelves(shelves)
                    .freeBayTiles(1)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Idle();

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Charges when not carrying a package and the battery is low")
        void should_Charge_when_NotCarryingPackageAndBatteryIsLow() {
            var robot = idleRobot(20);
            var jobs = arrayViewOf(job("job-1"));
            var observation = new ObservationBuilder(robot)
                    .jobs(jobs)
                    .freeBayTiles(1)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Charge();

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Heads to the bay before charging or taking a job when carrying a retrieval package")
        void should_GoToBay_when_CarryingRetrievalPackageDespiteLowBatteryAndPendingJob() {
            var robot = carryingRobot(JobType.RETRIEVAL, 0);
            var jobs = arrayViewOf(job("job-1"));
            var observation = new ObservationBuilder(robot)
                    .jobs(jobs)
                    .freeBayTiles(1)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.GoToBay();

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Charges before retrieving when the battery is low")
        void should_Charge_when_BatteryIsLowAndRetrievalIsAvailable() {
            var robot = idleRobot(20);
            var shelves = arrayViewOf(occupiedShelf(1, 1, 0, PackageColor.RED));
            var orders = arrayViewOf(order(1, PackageColor.RED, NON_URGENT_DEADLINE_TICK));
            var observation = new ObservationBuilder(robot)
                    .shelves(shelves)
                    .orders(orders)
                    .freeBayTiles(0)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Charge();

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Retrieves an order at the urgency threshold before taking a job")
        void should_Retrieve_when_OrderIsAtUrgencyThresholdAndJobIsPending() {
            var controller = new AiRobotController(10);
            var robot = idleRobot(21);
            var urgentShelf = occupiedShelf(1, 1, 0, PackageColor.RED);
            var shelves = arrayViewOf(urgentShelf);
            var jobs = arrayViewOf(job("job-1"));
            var orders = arrayViewOf(order(1, PackageColor.RED, 110));
            var observation = new ObservationBuilder(robot)
                    .shelves(shelves)
                    .jobs(jobs)
                    .orders(orders)
                    .currentTick(100)
                    .freeBayTiles(0)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Retrieve(urgentShelf.shelfId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Retrieves the shelf for the earliest-deadline fulfillable order")
        void should_RetrieveEarliestFulfillableOrder_when_MultipleUrgentOrdersAreAvailable() {
            var controller = new AiRobotController(10);
            var robot = idleRobot(21);
            var earliestShelf = occupiedShelf(1, 1, 0, PackageColor.RED);
            var laterShelf = occupiedShelf(2, 2, 0, PackageColor.BLUE);
            var shelves = arrayViewOf(laterShelf, earliestShelf);
            var orders = arrayViewOf(
                    order(1, PackageColor.BLUE, 110),
                    order(2, PackageColor.RED, 109)
            );
            var observation = new ObservationBuilder(robot)
                    .shelves(shelves)
                    .orders(orders)
                    .currentTick(100)
                    .freeBayTiles(0)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Retrieve(earliestShelf.shelfId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Skips an unfulfillable order in favor of the next fulfillable order")
        void should_RetrieveNextFulfillableOrder_when_EarliestOrderHasNoMatchingShelf() {
            var controller = new AiRobotController(10);
            var robot = idleRobot(21);
            var fulfillableShelf = occupiedShelf(1, 1, 0, PackageColor.BLUE);
            var shelves = arrayViewOf(fulfillableShelf);
            var orders = arrayViewOf(
                    order(1, PackageColor.RED, 109),
                    order(2, PackageColor.BLUE, 110)
            );
            var observation = new ObservationBuilder(robot)
                    .shelves(shelves)
                    .orders(orders)
                    .currentTick(100)
                    .freeBayTiles(0)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Retrieve(fulfillableShelf.shelfId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Retrieves the nearest shelf with a wanted color")
        void should_RetrieveNearestWantedShelf_when_RetrievalIsAvailable() {
            var robot = idleRobot(21);
            var nearestShelf = occupiedShelf(2, 1, 0, PackageColor.RED);
            var shelves = arrayViewOf(occupiedShelf(1, 3, 0, PackageColor.RED), nearestShelf);
            var orders = ordersOf(Set.of(PackageColor.RED));
            var observation = new ObservationBuilder(robot)
                    .shelves(shelves)
                    .orders(orders)
                    .freeBayTiles(1)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Retrieve(nearestShelf.shelfId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Chooses the nearest shelf by Manhattan distance")
        void should_RetrieveClosestShelf_when_EuclideanDistanceWouldChooseAnotherShelf() {
            var robot = idleRobot(21);
            var fartherShelf = occupiedShelf(1, 3, 3, PackageColor.RED);
            var nearestShelf = occupiedShelf(2, 0, 4, PackageColor.RED);
            var shelves = arrayViewOf(fartherShelf, nearestShelf);
            var orders = ordersOf(Set.of(PackageColor.RED));
            var observation = new ObservationBuilder(robot)
                    .shelves(shelves)
                    .orders(orders)
                    .freeBayTiles(0)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Retrieve(nearestShelf.shelfId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Keeps the first shelf when matching shelves are equally near")
        void should_RetrieveFirstShelf_when_MatchingShelvesAreEquidistant() {
            var robot = idleRobot(21);
            var firstShelf = occupiedShelf(1, 1, 1, PackageColor.RED);
            var secondShelf = occupiedShelf(2, 2, 0, PackageColor.RED);
            var shelves = arrayViewOf(firstShelf, secondShelf);
            var orders = ordersOf(Set.of(PackageColor.RED));
            var observation = new ObservationBuilder(robot)
                    .shelves(shelves)
                    .orders(orders)
                    .freeBayTiles(0)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Retrieve(firstShelf.shelfId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Prioritizes a pending putaway job over retrieval")
        void should_TakePutawayJob_when_PutawayJobIsPending() {
            var robot = idleRobot(21);
            var retrievalShelf = occupiedShelf(1, 1, 0, PackageColor.RED);
            var putawayJob = job("job-1");
            var shelves = arrayViewOf(retrievalShelf);
            var jobs = arrayViewOf(putawayJob);
            var orders = ordersOf(Set.of(PackageColor.RED));
            var observation = new ObservationBuilder(robot)
                    .shelves(shelves)
                    .jobs(jobs)
                    .orders(orders)
                    .freeBayTiles(1)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.TakeJob(putawayJob.jobId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Takes the first pending job when ready to work")
        void should_TakeFirstJob_when_NoRetrievalIsAvailable() {
            var robot = idleRobot(21);
            var firstJob = job("job-1");
            var jobs = arrayViewOf(firstJob, job("job-2"));
            var observation = new ObservationBuilder(robot)
                    .jobs(jobs)
                    .freeBayTiles(1)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.TakeJob(firstJob.jobId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Idles when ready to work but no retrieval or job is available")
        void should_Idle_when_NoRetrievalOrJobIsAvailable() {
            var robot = idleRobot(21);
            var observation = new ObservationBuilder(robot)
                    .freeBayTiles(1)
                    .build();

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Idle();

            assertThat(actual).isEqualTo(expected);
        }
    }

    private static ArrayView<OrderView> ordersOf(Set<PackageColor> colors) {
        var orders = new Array<OrderView>();
        int id = 0;
        for (var color : colors) {
            var view = new OrderView(
                    new OrderId(id++),
                    color,
                    NON_URGENT_DEADLINE_TICK
            );
            orders.add(view);
        }
        return GdxCollections.viewOf(orders);
    }

    @SuppressWarnings("SameParameterValue")
    private static ShelfView emptyShelf(int id, int x, int y) {
        return new ShelfView(
                new ShelfId(id),
                new GridPos(x, y),
                false,
                null,
                null
        );
    }

    @SuppressWarnings("SameParameterValue")
    private static ShelfView occupiedShelf(int id, int x, int y, PackageColor color) {
        return new ShelfView(
                new ShelfId(id),
                new GridPos(x, y),
                true,
                new PackageId(id),
                color
        );
    }

    private static OrderView order(int id, PackageColor color, int deadlineTick) {
        return new OrderView(new OrderId(id), color, deadlineTick);
    }
}
