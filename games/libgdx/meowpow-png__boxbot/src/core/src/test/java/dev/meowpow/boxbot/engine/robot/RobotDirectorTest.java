package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.OrderId;
import dev.meowpow.boxbot.engine.entity.OutboundOrder;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.function.Function;

import static dev.meowpow.boxbot.engine.TestWorldBuilder.world;
import static dev.meowpow.boxbot.engine.entity.PackageFixtures.packageWithId;
import static dev.meowpow.boxbot.engine.robot.RobotFixtures.robotJob;
import static org.assertj.core.api.Assertions.*;

class RobotDirectorTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null world")
        void should_RejectWorld_when_WorldIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new RobotDirector(
                    null,
                    new AiRobotController(0),
                    0
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null controller")
        void should_RejectController_when_ControllerIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new RobotDirector(
                    world().build(),
                    null,
                    0
            ));
        }

        @Test
        @DisplayName("Rejects a negative failure limit")
        void should_RejectFailureLimit_when_FailureLimitIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() -> new RobotDirector(
                    world().build(),
                    new AiRobotController(0),
                    -1
            ));
        }
    }

    @Nested
    @DisplayName("tickMovement")
    class TickMovementMethodTests {

        @Test
        @DisplayName("Travels to a job source before beginning pickup")
        void should_TravelToSourceBeforePickup_when_JobIsAccepted() {
            var pkg = packageWithId(1, PackageColor.RED);
            var world = world()
                    .withShelves(1)
                    .withIncomingPackage(pkg)
                    .withJob("putaway-1", JobType.PUTAWAY, pkg)
                    .withWalkableGrid(3, 1)
                    .build();

            var director = new RobotDirector(world, new AiRobotController(0), 1);

            director.tickMovement();
            director.tickMovement();

            assertThat(world.robot().position()).isEqualTo(new GridPos(0, 0));
            assertThat(world.robot().action()).isEqualTo(RobotAction.MOVING);

            director.tickMovement();

            assertThat(world.robot().position()).isEqualTo(new GridPos(1, 0));
            assertThat(world.robot().action()).isEqualTo(RobotAction.PICKING_UP);
        }

        @Test
        @DisplayName("Removes a pending job as soon as it is accepted")
        void should_RemovePendingJob_when_JobIsAccepted() {
            var pkg = packageWithId(1, PackageColor.RED);
            var world = world()
                    .withShelves(1)
                    .withIncomingPackage(pkg)
                    .withJob("putaway-1", JobType.PUTAWAY, pkg)
                    .build();

            var director = new RobotDirector(world, new AiRobotController(0), 1);

            director.tickMovement();

            assertThat(world.jobs().isEmpty()).isTrue();
            assertThat(world.loadingBay().incomingPackagePlacements().first().pkg()).isEqualTo(pkg);
        }

        @Test
        @DisplayName("Travels to the selected shelf before beginning drop-off")
        void should_TravelToDestinationBeforeDropoff_when_ShelfIsSelected() {
            var pkg = packageWithId(2, PackageColor.RED);
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(2)
                    .withIncomingPackage(pkg)
                    .withJob("putaway-1", JobType.PUTAWAY, pkg)
                    .withWalkableGrid(4, 1)
                    .build();

            var destination = world.shelves().get(1);
            var director = new RobotDirector(world, new AiRobotController(0), 1);

            director.tickMovement();
            director.tickMovement();
            director.tickMovement();
            director.tickAction();
            director.tickAction();
            director.tickAction();

            assertThat(world.robot().isMoving()).isTrue();
            assertThat(world.robot().action()).isEqualTo(RobotAction.IDLE);

            while (world.robot().isMoving()) {
                director.tickMovement();
            }
            int distanceToDestination = Math.abs(
                    world.robot().position().x() - destination.position().x()
            );
            assertThat(distanceToDestination).isEqualTo(1);
            assertThat(world.robot().action()).isEqualTo(RobotAction.DROPPING_OFF);
        }

        @Test
        @DisplayName("Reserves a wanted shelf before retrieving its package")
        void should_ReserveShelf_when_RetrievalIsSelectedForAnOutboundOrder() {
            var world = world().withShelfPackage(PackageColor.BLUE).build();
            var shelf = world.shelves().first();
            var order = new OutboundOrder(new OrderId(0), PackageColor.BLUE, 10);
            var director = new RobotDirector(world, new AiRobotController(0), 1);

            world.startOutboundOrder(order);
            director.tickMovement();

            assertThat(world.isShelfReserved(shelf.id())).isTrue();
        }

        @Test
        @DisplayName("Stores an incoming package and clears its putaway job")
        void should_StoreIncomingPackage_when_PutawayJobIsPending() {
            var pkg = packageWithId(1, PackageColor.RED);
            var world = world()
                    .withShelves(1)
                    .withIncomingPackage(pkg)
                    .withJob("putaway-1", JobType.PUTAWAY, pkg)
                    .build();

            var director = new RobotDirector(
                    world,
                    new AiRobotController(0),
                    1
            );
            completePendingWork(director, world);

            assertThat(world.jobs().isEmpty()).isTrue();
            assertThat(world.loadingBay().incomingPackages().isEmpty()).isTrue();
            assertThat(world.shelves().first().occupyingPackage()).isEqualTo(pkg);
            assertThat(world.robot().carriedPackage()).isNull();
            assertThat(world.carriedJobType()).isNull();
        }

        @Test
        @DisplayName("Retains a package until storage becomes available")
        void should_RetainPackage_when_NoStorageDestinationIsAvailable() {
            var incomingPackage = packageWithId(2, PackageColor.RED);
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withIncomingPackage(incomingPackage)
                    .withJob("putaway-1", JobType.PUTAWAY, incomingPackage)
                    .build();

            var director = new RobotDirector(world, new AiRobotController(0), 1);

            director.tickMovement();
            director.tickMovement();
            director.tickAction();
            director.tickAction();
            director.tickAction();

            assertThat(world.robot().carriedPackage()).isEqualTo(incomingPackage);
            assertThat(world.shelves().first().occupyingPackage()).isNotNull();

            world.setShelfPackage(world.shelves().first().id(), null);
            director.tickMovement();
            director.tickMovement();
            director.tickAction();
            director.tickAction();
            director.tickAction();

            assertThat(world.robot().carriedPackage()).isNull();
            assertThat(world.shelves().first().occupyingPackage()).isEqualTo(incomingPackage);
        }

        @Test
        @DisplayName("Travels to the charging station when the battery is low")
        void should_TravelToChargingStation_when_BatteryIsLow() {
            var chargingPosition = new GridPos(2, 0);
            var world = world()
                    .withWalkableGrid(3, 1)
                    .withChargingStationAt(chargingPosition)
                    .build();

            world.robot().battery().drain(80);
            var director = new RobotDirector(world, new AiRobotController(0), 1);

            director.tickMovement();
            director.tickMovement();
            director.tickMovement();
            director.tickMovement();

            assertThat(world.robot().position()).isEqualTo(chargingPosition);
            assertThat(world.robot().action()).isEqualTo(RobotAction.CHARGING);
        }

        @Test
        @DisplayName("Detours to the charging station mid-delivery when charging is requested while carrying")
        void should_DetourToChargingStation_when_ChargeRequestedWhileCarryingEnRouteToDestination() {
            var chargingPosition = new GridPos(5, 0);
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(3)
                    .withWalkableGrid(6, 1)
                    .withChargingStationAt(chargingPosition)
                    .build();

            var sourceShelf = world.shelves().get(0);
            var pkg = sourceShelf.occupyingPackage();
            var destinationShelf = world.shelves().get(1);

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRetrieveFromShelf(sourceShelf.id());
            controller.setDestination(new RelocationDestination.Shelf(
                    destinationShelf.id())
            );
            driveUntilCarryingAndMoving(director, world);

            robot.battery().drain(20);
            controller.commitCharge();

            for (var tick = 0; tick < 40 && robot.action() != RobotAction.CHARGING; tick++) {
                director.tickMovement();
                director.tickAction();
            }
            assertThat(robot.action()).isEqualTo(RobotAction.CHARGING);
            assertThat(robot.position()).isEqualTo(chargingPosition);
            assertThat(robot.carriedPackage()).isEqualTo(pkg);
            assertThat(destinationShelf.occupyingPackage()).isNull();
        }

        @Test
        @DisplayName("Resumes toward the original destination once a mid-delivery charge completes")
        void should_ResumeToOriginalDestination_when_ChargeCompletesMidTransit() {
            var chargingPosition = new GridPos(5, 0);
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(3)
                    .withWalkableGrid(6, 1)
                    .withChargingStationAt(chargingPosition)
                    .build();

            var sourceShelf = world.shelves().get(0);
            var pkg = sourceShelf.occupyingPackage();
            var destinationShelf = world.shelves().get(1);

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRetrieveFromShelf(sourceShelf.id());
            controller.setDestination(new RelocationDestination.Shelf(
                    destinationShelf.id())
            );
            driveUntilCarryingAndMoving(director, world);

            robot.battery().drain(20);
            controller.commitCharge();

            for (var tick = 0; tick < 40 && robot.action() != RobotAction.CHARGING; tick++) {
                director.tickMovement();
                director.tickAction();
            }
            assertThat(robot.action()).isEqualTo(RobotAction.CHARGING);

            while (robot.isBusy()) {
                director.tickCharging();
            }
            assertThat(robot.battery().isFull()).isTrue();

            completePendingWork(director, world);

            assertThat(destinationShelf.occupyingPackage()).isEqualTo(pkg);
            assertThat(robot.carriedPackage()).isNull();
        }

        @Test
        @DisplayName("Charges while carrying with no destination chosen, holding the package throughout")
        void should_Charge_when_CarryingWithNoDestinationChosen() {
            var chargingPosition = new GridPos(2, 0);
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withWalkableGrid(3, 1)
                    .withChargingStationAt(chargingPosition)
                    .build();

            var sourceShelf = world.shelves().first();
            var pkg = sourceShelf.occupyingPackage();

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRetrieveFromShelf(sourceShelf.id());
            for (var tick = 0; tick < 20; tick++) {
                director.tickMovement();
                director.tickAction();
            }
            assertThat(robot.carriedPackage()).isEqualTo(pkg);
            assertThat(robot.action()).isEqualTo(RobotAction.IDLE);

            robot.battery().drain(20);
            controller.commitCharge();

            for (var tick = 0; tick < 40 && robot.action() != RobotAction.CHARGING; tick++) {
                director.tickMovement();
                director.tickAction();
            }
            assertThat(robot.action()).isEqualTo(RobotAction.CHARGING);
            assertThat(robot.carriedPackage()).isEqualTo(pkg);

            for (int tick = 0; tick < 40 && robot.isBusy(); tick++) {
                director.tickCharging();
            }
            assertThat(robot.battery().isFull()).isTrue();
            assertThat(robot.action()).isEqualTo(RobotAction.IDLE);
            assertThat(robot.carriedPackage()).isEqualTo(pkg);
        }

        @Test
        @DisplayName("Reroutes to a new shelf when redirected while en route to a shelf")
        void should_RerouteToNewShelf_when_RedirectedWhileEnRouteToShelf() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(3)
                    .withWalkableGrid(6, 1)
                    .build();

            var sourceShelf = world.shelves().get(0);
            var pkg = sourceShelf.occupyingPackage();
            var initialDestination = world.shelves().get(1);
            var redirectedDestination = world.shelves().get(2);

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var destination = new RelocationDestination.Shelf(initialDestination.id());

            controller.commitRetrieveFromShelf(sourceShelf.id());
            controller.setDestination(destination);

            driveUntilCarryingAndMoving(director, world);

            destination = new RelocationDestination.Shelf(redirectedDestination.id());
            controller.setDestination(destination);
            completePendingWork(director, world);

            assertThat(redirectedDestination.occupyingPackage()).isEqualTo(pkg);
            assertThat(initialDestination.occupyingPackage()).isNull();
        }

        @Test
        @DisplayName("Reroutes to a shelf when redirected away from the loading bay")
        void should_RerouteToShelf_when_RedirectedWhileEnRouteToLoadingBay() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(2)
                    .withLoadingBayCapacity(3)
                    .withWalkableGrid(6, 1)
                    .build();

            var sourceShelf = world.shelves().get(0);
            var pkg = sourceShelf.occupyingPackage();
            var redirectedDestination = world.shelves().get(1);
            world.startOutboundOrder(new OutboundOrder(
                    new OrderId(0),
                    PackageColor.BLUE, 100
            ));
            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var loadingBay = world.loadingBay();

            controller.commitRetrieveFromShelf(sourceShelf.id());
            controller.setDestination(new RelocationDestination.Bay());
            driveUntilCarryingAndMoving(director, world);

            controller.setDestination(new RelocationDestination.Shelf(
                    redirectedDestination.id())
            );
            completePendingWork(director, world);

            assertThat(redirectedDestination.occupyingPackage()).isEqualTo(pkg);
            assertThat(loadingBay.freeTiles()).isEqualTo(3);
            assertThat(loadingBay.outgoingPackages().isEmpty()).isTrue();
        }

        @Test
        @DisplayName("Reroutes to closest empty shelf when matching order expires en route to bay")
        void should_RerouteToClosestEmptyShelf_when_MatchingOrderExpiresWhileCarryingToBay() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(2)
                    .withLoadingBayCapacity(3)
                    .withWalkableGrid(6, 1)
                    .build();

            var sourceShelf = world.shelves().get(0);
            var destinationShelf = world.shelves().get(1);
            var pkg = sourceShelf.occupyingPackage();
            var order = new OutboundOrder(
                    new OrderId(0),
                    PackageColor.BLUE, 100
            );
            world.startOutboundOrder(order);

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);

            controller.commitRetrieveFromShelf(sourceShelf.id());
            controller.setDestination(new RelocationDestination.Bay());

            driveUntilCarryingAndMoving(director, world);
            world.expireOutboundOrder(order);
            completePendingWork(director, world);

            assertThat(destinationShelf.occupyingPackage()).isEqualTo(pkg);
            assertThat(world.loadingBay().outgoingPackages().isEmpty()).isTrue();
        }

        @Test
        @DisplayName("Stops the robot in place when redirected to an occupied shelf")
        void should_StopRobot_when_RedirectedToOccupiedShelf() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(3)
                    .withWalkableGrid(6, 1)
                    .build();

            var sourceShelf = world.shelves().get(0);
            var initialDestination = world.shelves().get(1);
            var occupiedShelf = world.shelves().get(2);

            world.setShelfPackage(occupiedShelf.id(), packageWithId(2, PackageColor.RED));

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRetrieveFromShelf(sourceShelf.id());
            controller.setDestination(new RelocationDestination.Shelf(
                    initialDestination.id())
            );
            driveUntilCarryingAndMoving(director, world);

            controller.setDestination(new RelocationDestination.Shelf(
                    occupiedShelf.id())
            );
            director.tickMovement();

            var positionAfterStop = robot.position();
            director.tickMovement();

            assertThat(robot.isMoving()).isFalse();
            assertThat(robot.position()).isEqualTo(positionAfterStop);
            assertThat(robot.carriedPackage()).isNotNull();

            for (var tick = 0; tick < 10; tick++) {
                director.tickMovement();
                director.tickAction();
            }

            assertThat(robot.carriedPackage()).isNotNull();
            assertThat(initialDestination.occupyingPackage()).isNull();
        }

        @Test
        @DisplayName("Reroutes to the bay when redirected while en route to a shelf")
        void should_RerouteToBay_when_RedirectedWhileEnRouteToShelf() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(2)
                    .withWalkableGrid(6, 1)
                    .build();

            var sourceShelf = world.shelves().get(0);
            var pkg = sourceShelf.occupyingPackage();
            var initialDestination = world.shelves().get(1);
            var order = new OutboundOrder(
                    new OrderId(0),
                    PackageColor.BLUE,
                    100
            );
            world.startOutboundOrder(order);

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var loadingBay = world.loadingBay();

            controller.commitRetrieveFromShelf(sourceShelf.id());
            controller.setDestination(new RelocationDestination.Shelf(
                    initialDestination.id())
            );
            driveUntilCarryingAndMoving(director, world);

            controller.setDestination(new RelocationDestination.Bay());
            completePendingWork(director, world);

            assertThat(initialDestination.occupyingPackage()).isNull();
            assertThat(loadingBay.outgoingPackagePlacements().first().pkg()).isEqualTo(pkg);
        }

        @Test
        @DisplayName("Stops the robot in place when redirected to a full bay")
        void should_StopRobot_when_RedirectedToFullBay() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(2)
                    .withLoadingBayCapacity(1)
                    .withOutgoingPackages(1)
                    .withWalkableGrid(6, 1)
                    .build();

            var sourceShelf = world.shelves().get(0);
            var initialDestination = world.shelves().get(1);
            var order = new OutboundOrder(
                    new OrderId(0),
                    PackageColor.BLUE,
                    100
            );
            world.startOutboundOrder(order);

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRetrieveFromShelf(sourceShelf.id());
            controller.setDestination(new RelocationDestination.Shelf(
                    initialDestination.id())
            );
            driveUntilCarryingAndMoving(director, world);

            controller.setDestination(new RelocationDestination.Bay());
            director.tickMovement();

            var positionAfterStop = world.robot().position();
            director.tickMovement();

            assertThat(robot.isMoving()).isFalse();
            assertThat(robot.position()).isEqualTo(positionAfterStop);
            assertThat(robot.carriedPackage()).isNotNull();

            for (var tick = 0; tick < 10; tick++) {
                director.tickMovement();
                director.tickAction();
            }
            assertThat(robot.carriedPackage()).isNotNull();
            assertThat(initialDestination.occupyingPackage()).isNull();
        }

        @Test
        @DisplayName("Holds the package in place once picked up with no destination chosen")
        void should_HoldPackageInPlace_when_PickedUpWithNoDestinationChosen() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withWalkableGrid(3, 1)
                    .build();

            var sourceShelf = world.shelves().first();
            var pkg = sourceShelf.occupyingPackage();

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRetrieveFromShelf(sourceShelf.id());

            for (var tick = 0; tick < 20; tick++) {
                director.tickMovement();
                director.tickAction();
            }
            assertThat(robot.carriedPackage()).isEqualTo(pkg);
            assertThat(robot.isMoving()).isFalse();
            assertThat(robot.action()).isEqualTo(RobotAction.IDLE);
        }

        @Test
        @DisplayName("Holds the package when told to go to a bay that's already full")
        void should_HoldPackage_when_GoingToBayThatIsAlreadyFull() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withLoadingBayCapacity(1)
                    .withOutgoingPackages(1)
                    .withWalkableGrid(3, 1)
                    .build();

            var sourceShelf = world.shelves().first();
            var pkg = sourceShelf.occupyingPackage();

            world.startOutboundOrder(new OutboundOrder(
                    new OrderId(0),
                    PackageColor.BLUE,
                    100
            ));
            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRetrieveFromShelf(sourceShelf.id());
            controller.setDestination(new RelocationDestination.Bay());

            for (var tick = 0; tick < 20; tick++) {
                director.tickMovement();
                director.tickAction();
            }
            assertThat(robot.carriedPackage()).isEqualTo(pkg);
            assertThat(robot.isMoving()).isFalse();
        }

        @Test
        @DisplayName("Idles in place when the delivery is cancelled while en route to a shelf")
        void should_IdleInPlace_when_CancelledWhileEnRouteToShelf() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(2)
                    .withWalkableGrid(6, 1)
                    .build();

            var sourceShelf = world.shelves().get(0);
            var initialDestination = world.shelves().get(1);

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRetrieveFromShelf(sourceShelf.id());
            controller.setDestination(new RelocationDestination.Shelf(initialDestination.id()));
            driveUntilCarryingAndMoving(director, world);

            controller.cancelDestination();
            director.tickMovement();

            var positionAfterCancel = robot.position();

            for (var tick = 0; tick < 10; tick++) {
                director.tickMovement();
                director.tickAction();
            }
            assertThat(robot.isMoving()).isFalse();
            assertThat(robot.position()).isEqualTo(positionAfterCancel);
            assertThat(robot.carriedPackage()).isNotNull();
            assertThat(initialDestination.occupyingPackage()).isNull();
        }

        @Test
        @DisplayName("Resumes toward a new destination after being stopped at an occupied shelf")
        void should_Resume_when_RedirectedAfterBeingStoppedAtOccupiedShelf() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(3)
                    .withWalkableGrid(6, 1)
                    .build();

            var sourceShelf = world.shelves().get(0);
            var pkg = sourceShelf.occupyingPackage();
            var initialDestination = world.shelves().get(1);
            var occupiedShelf = world.shelves().get(2);
            world.setShelfPackage(occupiedShelf.id(), packageWithId(2, PackageColor.RED));

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);

            controller.commitRetrieveFromShelf(sourceShelf.id());
            controller.setDestination(new RelocationDestination.Shelf(
                    initialDestination.id())
            );
            driveUntilCarryingAndMoving(director, world);

            controller.setDestination(new RelocationDestination.Shelf(
                    occupiedShelf.id())
            );
            director.tickMovement();
            director.tickMovement();

            assertThat(world.robot().isMoving()).isFalse();

            controller.setDestination(new RelocationDestination.Shelf(
                    initialDestination.id())
            );
            completePendingWork(director, world);

            assertThat(initialDestination.occupyingPackage()).isEqualTo(pkg);
        }

        @Test
        @DisplayName("Idles in place when cancelled after being stopped at an occupied shelf")
        void should_IdleInPlace_when_CancelledAfterBeingStoppedAtOccupiedShelf() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(3)
                    .withWalkableGrid(6, 1)
                    .build();

            var sourceShelf = world.shelves().get(0);
            var initialDestination = world.shelves().get(1);
            var occupiedShelf = world.shelves().get(2);
            world.setShelfPackage(occupiedShelf.id(), packageWithId(2, PackageColor.RED));

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRetrieveFromShelf(sourceShelf.id());
            controller.setDestination(new RelocationDestination.Shelf(
                    initialDestination.id())
            );
            driveUntilCarryingAndMoving(director, world);

            controller.setDestination(new RelocationDestination.Shelf(
                    occupiedShelf.id())
            );
            director.tickMovement();
            director.tickMovement();

            assertThat(robot.isMoving()).isFalse();

            controller.cancelDestination();

            for (var tick = 0; tick < 10; tick++) {
                director.tickMovement();
                director.tickAction();
            }

            assertThat(robot.carriedPackage()).isNotNull();
            assertThat(initialDestination.occupyingPackage()).isNull();
            assertThat(occupiedShelf.occupyingPackage()).isNotNull();
        }

        @Test
        @DisplayName("Cancels a trip to retrieve a package and releases its shelf")
        void should_CancelRetrieval_when_PickupIsCancelledBeforeCarrying() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withWalkableGrid(3, 1)
                    .build();

            var sourceShelf = world.shelves().first();
            var pkg = sourceShelf.occupyingPackage();

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRetrieveFromShelf(sourceShelf.id());
            director.tickMovement();

            assertThat(world.isShelfReserved(sourceShelf.id())).isTrue();

            controller.cancelPickup();

            for (var tick = 0; tick < 10; tick++) {
                director.tickMovement();
                director.tickAction();
            }
            assertThat(world.isShelfReserved(sourceShelf.id())).isFalse();
            assertThat(sourceShelf.occupyingPackage()).isEqualTo(pkg);
            assertThat(robot.carriedPackage()).isNull();
            assertThat(robot.isMoving()).isFalse();
        }

        @Test
        @DisplayName("Cancels a trip to collect an incoming package and requeues its job")
        void should_RequeueJob_when_PickupIsCancelledBeforeCarrying() {
            var pkg = packageWithId(1, PackageColor.RED);
            var world = world()
                    .withShelves(1)
                    .withIncomingPackage(pkg)
                    .withJob("putaway-1", JobType.PUTAWAY, pkg)
                    .withWalkableGrid(3, 1)
                    .build();

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRelocateFromBay(pkg.id(), world.shelves().first().id());
            director.tickMovement();

            assertThat(world.jobs().isEmpty()).isTrue();

            controller.cancelPickup();

            for (var tick = 0; tick < 10; tick++) {
                director.tickMovement();
                director.tickAction();
            }
            assertThat(world.jobs().size()).isEqualTo(1);
            assertThat(world.jobs().first().pkg()).isEqualTo(pkg);
            assertThat(robot.carriedPackage()).isNull();
        }

        @Test
        @DisplayName("Retargets pickup to a new shelf immediately when reselected before carrying")
        void should_RetargetPickup_when_NewShelfSelectedBeforeCarrying() {
            var world = world()
                    .withShelfPackages(List.of(PackageColor.BLUE, PackageColor.RED))
                    .withWalkableGrid(6, 1)
                    .build();

            var originalShelf = world.shelves().get(0);
            var newShelf = world.shelves().get(1);
            var newPkg = newShelf.occupyingPackage();

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRetrieveFromShelf(originalShelf.id());
            director.tickMovement();

            assertThat(world.isShelfReserved(originalShelf.id())).isTrue();

            controller.commitRetrieveFromShelf(newShelf.id());
            director.tickMovement();

            assertThat(world.isShelfReserved(originalShelf.id())).isFalse();
            assertThat(world.isShelfReserved(newShelf.id())).isTrue();

            for (var tick = 0; tick < 40 && robot.carriedPackage() == null; tick++) {
                director.tickMovement();
                director.tickAction();
            }
            assertThat(robot.carriedPackage()).isEqualTo(newPkg);
            assertThat(newShelf.occupyingPackage()).isNull();
            assertThat(originalShelf.occupyingPackage()).isNotNull();
        }

        @Test
        @DisplayName("Still allows redirecting the package after cancelling mid pickup animation")
        void should_StillAllowRedirect_when_PickupCancelledWhileAnimationInProgress() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(2)
                    .withWalkableGrid(6, 1)
                    .build();

            var sourceShelf = world.shelves().get(0);
            var pkg = sourceShelf.occupyingPackage();
            var redirectedDestination = world.shelves().get(1);

            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);
            var robot = world.robot();

            controller.commitRetrieveFromShelf(sourceShelf.id());

            for (var tick = 0; tick < 40 && robot.action() != RobotAction.PICKING_UP; tick++) {
                director.tickMovement();
                director.tickAction();
            }
            assertThat(robot.action()).isEqualTo(RobotAction.PICKING_UP);

            controller.cancelPickup();

            for (var tick = 0; tick < 10; tick++) {
                director.tickMovement();
                director.tickAction();
            }

            assertThat(robot.carriedPackage()).isEqualTo(pkg);
            assertThat(controller.isRelocating()).isTrue();

            controller.setDestination(new RelocationDestination.Shelf(
                    redirectedDestination.id())
            );
            completePendingWork(director, world);

            assertThat(redirectedDestination.occupyingPackage()).isEqualTo(pkg);
        }
    }

    @Nested
    @DisplayName("tickAction")
    class TickActionMethodTests {

        @Test
        @DisplayName("Keeps an incoming package in the bay until pickup completes")
        void should_RemoveIncomingPackage_when_PickupDurationElapses() {
            var pkg = packageWithId(1, PackageColor.RED);
            var world = world()
                    .withShelves(1)
                    .withIncomingPackage(pkg)
                    .withJob("putaway-1", JobType.PUTAWAY, pkg)
                    .build();

            var robot = world.robot();
            var loadingBay = world.loadingBay();

            var aiController = new AiRobotController(0);
            var director = new RobotDirector(world, aiController, 1);
            var incomingPlacements = loadingBay.incomingPackagePlacements();

            director.tickMovement();
            director.tickMovement();
            director.tickAction();
            director.tickAction();

            assertThat(incomingPlacements.first().pkg()).isEqualTo(pkg);
            assertThat(robot.carriedPackage()).isNull();

            director.tickAction();

            assertThat(incomingPlacements.isEmpty()).isTrue();
            assertThat(robot.carriedPackage()).isEqualTo(pkg);
        }

        @Test
        @DisplayName("Waits for the pickup duration before collecting a retrieved package")
        void should_CollectPackage_when_PickupDurationElapses() {
            Function<World, RobotJob> job = builtWorld -> robotJob(
                    builtWorld,
                    "retrieval-1",
                    JobType.RETRIEVAL,
                    builtWorld.shelves().first().occupyingPackage()
            );
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withJob(job)
                    .build();

            var robot = world.robot();
            var shelf = world.shelves().first();
            var order = new OutboundOrder(
                    new OrderId(0),
                    PackageColor.BLUE,
                    10
            );
            var aiController = new AiRobotController(0);
            var director = new RobotDirector(world, aiController, 1);

            world.startOutboundOrder(order);
            director.tickMovement();
            director.tickMovement();
            director.tickMovement();
            director.tickAction();
            director.tickAction();

            assertThat(robot.action()).isEqualTo(RobotAction.PICKING_UP);
            assertThat(shelf.occupyingPackage()).isNotNull();

            director.tickAction();

            assertThat(robot.carriedPackage()).isNotNull();
            assertThat(shelf.occupyingPackage()).isNull();
        }

        @Test
        @DisplayName("Waits for the drop-off duration before delivering a retrieved package")
        void should_DeliverPackage_when_DropoffDurationElapses() {
            var world = world().withShelfPackage(PackageColor.BLUE).build();
            var order = new OutboundOrder(
                    new OrderId(0),
                    PackageColor.BLUE,
                    10
            );
            var aiController = new AiRobotController(0);
            var director = new RobotDirector(world, aiController, 1);

            world.startOutboundOrder(order);
            director.tickMovement();
            director.tickMovement();
            director.tickMovement();
            director.tickAction();
            director.tickAction();
            director.tickAction();
            director.tickMovement();
            director.tickAction();
            director.tickAction();

            var robot = world.robot();
            var loadingBay = world.loadingBay();

            assertThat(robot.action()).isEqualTo(RobotAction.DROPPING_OFF);
            assertThat(loadingBay.outgoingPackages().isEmpty()).isTrue();

            director.tickAction();

            assertThat(robot.carriedPackage()).isNull();
            assertThat(loadingBay.outgoingPackages().size()).isEqualTo(1);
        }

        @Test
        @DisplayName("Keeps the matching outbound order open until the truck ships it")
        void should_KeepOutboundOrderOpen_when_RetrievedPackageOnlyReachesBay() {
            var world = world().withShelfPackage(PackageColor.BLUE).build();
            var shelf = world.shelves().first();
            var pkg = shelf.occupyingPackage();
            var order = new OutboundOrder(
                    new OrderId(0),
                    PackageColor.BLUE,
                    100
            );
            var aiController = new AiRobotController(0);
            var director = new RobotDirector(world, aiController, 1);

            world.startOutboundOrder(order);
            completePendingWork(director, world);

            var loadingBay = world.loadingBay();

            assertThat(world.outboundOrders().size()).isEqualTo(1);
            assertThat(world.outboundOrders().first()).isEqualTo(order);
            assertThat(world.shipmentFailures()).isZero();
            assertThat(loadingBay.freeTiles()).isZero();
            assertThat(loadingBay.outgoingPackagePlacements().first().pkg()).isEqualTo(pkg);
        }

        @Test
        @DisplayName("Delivers a retrieved package to the loading bay and releases its shelf")
        void should_DeliverRetrievedPackage_when_RetrievalJobIsPending() {
            Function<World, RobotJob> job = builtWorld -> robotJob(
                    builtWorld,
                    "retrieval-1",
                    JobType.RETRIEVAL,
                    builtWorld.shelves().first().occupyingPackage()
            );
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withJob(job)
                    .build();

            var shelf = world.shelves().first();
            var pkg = shelf.occupyingPackage();
            var aiController = new AiRobotController(0);
            var director = new RobotDirector(world, aiController, 1);

            completePendingWork(director, world);

            var loadingBay = world.loadingBay();

            assertThat(world.jobs().isEmpty()).isTrue();
            assertThat(world.isShelfReserved(shelf.id())).isFalse();
            assertThat(shelf.occupyingPackage()).isNull();
            assertThat(loadingBay.outgoingPackagePlacements().first().pkg()).isEqualTo(pkg);
            assertThat(loadingBay.freeTiles()).isZero();
            assertThat(world.robot().carriedPackage()).isNull();
            assertThat(world.carriedJobType()).isNull();
        }

        @Test
        @DisplayName("Stores a retrieved package when the loading bay is full")
        void should_StoreRetrievedPackage_when_LoadingBayIsFull() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(2)
                    .withOutgoingPackages(1)
                    .build();

            var sourceShelf = world.shelves().first();
            var pkg = sourceShelf.occupyingPackage();
            var order = new OutboundOrder(
                    new OrderId(0),
                    PackageColor.BLUE,
                    100
            );
            var aiController = new AiRobotController(0);
            var director = new RobotDirector(world, aiController, 1);

            world.startOutboundOrder(order);
            completePendingWork(director, world);

            var loadingBay = world.loadingBay();
            var outboundOrders = world.outboundOrders();

            assertThat(sourceShelf.occupyingPackage()).isEqualTo(pkg);
            assertThat(world.shelves().get(1).occupyingPackage()).isNull();
            assertThat(loadingBay.outgoingPackages().size()).isEqualTo(1);
            assertThat(outboundOrders.size()).isEqualTo(1);
            assertThat(outboundOrders.first()).isEqualTo(order);
        }

        @Test
        @DisplayName("Keeps a destination shelf empty until drop-off completes")
        void should_StorePackageOnShelf_when_DropoffDurationElapses() {
            var incomingPackage = packageWithId(2, PackageColor.RED);
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withShelves(2)
                    .withIncomingPackage(incomingPackage)
                    .withJob("putaway-1", JobType.PUTAWAY, incomingPackage)
                    .build();

            var robot = world.robot();
            var destination = world.shelves().get(1);
            var aiController = new AiRobotController(0);
            var director = new RobotDirector(world, aiController, 1);

            director.tickMovement();
            director.tickMovement();
            director.tickAction();
            director.tickAction();
            director.tickAction();
            director.tickMovement();
            director.tickAction();
            director.tickAction();

            assertThat(destination.occupyingPackage()).isNull();
            assertThat(robot.carriedPackage()).isEqualTo(incomingPackage);

            director.tickAction();

            assertThat(destination.occupyingPackage()).isEqualTo(incomingPackage);
            assertThat(robot.carriedPackage()).isNull();
        }

        @Test
        @DisplayName("Charges to full before becoming idle")
        void should_ChargeToFull_when_ChargingIsInProgress() {
            var world = world().build();
            var aiController = new AiRobotController(0);
            var director = new RobotDirector(world, aiController, 1);
            var robot = world.robot();

            robot.battery().drain(80);
            director.tickMovement();
            director.tickMovement();

            while (world.robot().isBusy()) {
                director.tickCharging();
            }
            assertThat(robot.battery().level()).isEqualTo(100);
            assertThat(robot.action()).isEqualTo(RobotAction.IDLE);
        }
    }

    @Nested
    @DisplayName("wakeIfIdle")
    class WakeIfIdleMethodTests {

        @Test
        @DisplayName("Starts routing immediately once a command becomes available while idle")
        void should_StartRouting_when_IdleAndCommandBecomesAvailable() {
            var world = world().withShelfPackage(PackageColor.BLUE).build();
            var shelf = world.shelves().first();
            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);

            controller.commitRetrieveFromShelf(shelf.id());
            director.wakeIfIdle();

            assertThat(world.isShelfReserved(shelf.id())).isTrue();
        }

        @Test
        @DisplayName("No-ops when the controller has nothing to decide")
        void should_NoOp_when_ControllerHasNoDecision() {
            var world = world().withShelfPackage(PackageColor.BLUE).build();
            var shelf = world.shelves().first();
            var director = new RobotDirector(world, new PlayerRobotController(), 1);

            director.wakeIfIdle();

            assertThat(world.isShelfReserved(shelf.id())).isFalse();
            assertThat(world.robot().isMoving()).isFalse();
        }

        @Test
        @DisplayName("No-ops while the robot is already en route")
        void should_NoOp_when_RobotIsAlreadyMoving() {
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withWalkableGrid(3, 1)
                    .build();

            var shelf = world.shelves().first();
            var controller = new PlayerRobotController();
            var director = new RobotDirector(world, controller, 1);

            controller.commitRetrieveFromShelf(shelf.id());
            director.tickMovement();

            assertThat(world.robot().isMoving()).isTrue();
            var positionBeforeWake = world.robot().position();

            director.wakeIfIdle();

            assertThat(world.robot().position()).isEqualTo(positionBeforeWake);
            assertThat(world.robot().isMoving()).isTrue();
        }

        @Test
        @DisplayName("No-ops while the robot is mid-action")
        void should_NoOp_when_RobotIsBusy() {
            var pkg = packageWithId(1, PackageColor.RED);
            var world = world()
                    .withShelves(1)
                    .withIncomingPackage(pkg)
                    .withJob("putaway-1", JobType.PUTAWAY, pkg)
                    .withWalkableGrid(3, 1)
                    .build();

            var aiController = new AiRobotController(0);
            var director = new RobotDirector(
                    world,
                    aiController,
                    1
            );
            director.tickMovement();
            director.tickMovement();
            director.tickMovement();

            assertThat(world.robot().action()).isEqualTo(RobotAction.PICKING_UP);

            director.wakeIfIdle();

            assertThat(world.robot().action()).isEqualTo(RobotAction.PICKING_UP);
            assertThat(world.robot().carriedPackage()).isNull();
        }
    }

    private static void driveUntilCarryingAndMoving(RobotDirector director, World world) {
        for (var tick = 0; tick < 40; tick++) {
            director.tickMovement();
            director.tickAction();

            if (world.robot().carriedPackage() != null && world.robot().isMoving()) {
                return;
            }
        }
        var message = "Robot never became en route to a destination within 40 ticks";
        throw new AssertionError(message);
    }

    private static void completePendingWork(RobotDirector director, World world) {
        for (var tick = 0; tick < 40; tick++) {
            director.tickMovement();
            director.tickAction();

            boolean isRobotMovingOrBusy = world.robot().isMoving() || world.robot().isBusy();
            boolean isRobotCarryingPackage = world.robot().carriedPackage() != null;

            if (world.jobs().isEmpty() && !isRobotMovingOrBusy && !isRobotCarryingPackage) {
                return;
            }
        }
        var message = "Robot did not complete pending work within 40 ticks";
        throw new AssertionError(message);
    }
}
