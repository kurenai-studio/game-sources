package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.spatial.grid.Direction;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static dev.meowpow.boxbot.engine.entity.PackageFixtures.packageWithId;
import static dev.meowpow.boxbot.engine.robot.RobotFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class RobotTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null starting position")
        void should_RejectPosition_when_PositionIsNull() {
            assertThatNullPointerException().isThrownBy(() ->
                    new Robot(null, 100)
            );
        }
    }

    @Nested
    @DisplayName("tick")
    class TickMethodTests {

        @Test
        @DisplayName("Does not advance when there is no route")
        void should_NotAdvance_when_RouteIsEmpty() {
            var start = new GridPos(0, 0);
            var robot = robotAt();

            robot.tickMovement(1);

            assertThat(robot.position()).isEqualTo(start);
            assertThat(robot.isMoving()).isFalse();
        }

        @Test
        @DisplayName("Advances one cell per tick when already facing the route")
        void should_AdvanceOneCellPerTick_when_FollowingRoute() {
            var robot = robotAt();
            var route = routeOf(
                    new GridPos(0, 1),
                    new GridPos(0, 2)
            );
            robot.followRoute(route);
            robot.tickMovement(1);

            assertThat(robot.position()).isEqualTo(new GridPos(0, 1));
            assertThat(robot.isMoving()).isTrue();
        }

        @Test
        @DisplayName("Consumes the entire route when ticked once per cell")
        void should_ConsumeEntireRoute_when_TickedForEachCell() {
            var robot = robotAt();
            var route = routeOf(
                    new GridPos(0, 1),
                    new GridPos(0, 2)
            );
            robot.followRoute(route);
            robot.tickMovement(1);
            robot.tickMovement(1);

            assertThat(robot.position()).isEqualTo(new GridPos(0, 2));
            assertThat(robot.isMoving()).isFalse();
        }

        @Test
        @DisplayName("Updates the previous position when it advances")
        void should_UpdatePreviousPosition_when_ItAdvances() {
            var start = new GridPos(0, 0);
            var robot = robotAt();
            var route = routeOf(new GridPos(0, 1));

            robot.followRoute(route);
            robot.tickMovement(1);

            assertThat(robot.previousPosition()).isEqualTo(start);
            assertThat(robot.position()).isEqualTo(new GridPos(0, 1));
        }

        @Test
        @DisplayName("Keeps the previous position in sync once movement stops")
        void should_KeepPreviousPositionInSync_when_MovementStops() {
            var robot = robotAt();
            var route = routeOf(new GridPos(0, 1));

            robot.followRoute(route);
            robot.tickMovement(1);
            robot.tickMovement(1);

            assertThat(robot.previousPosition()).isEqualTo(robot.position());
        }

        @Test
        @DisplayName("Turns to face the next cell before moving when the direction changes")
        void should_TurnBeforeMoving_when_DirectionChanges() {
            var start = new GridPos(0, 0);
            var robot = robotAt();
            var route = routeOf(new GridPos(1, 0));

            robot.followRoute(route);
            robot.tickMovement(1);

            assertThat(robot.position()).isEqualTo(start);
            assertThat(robot.facing()).isEqualTo(Direction.EAST);
            assertThat(robot.isMoving()).isTrue();
        }

        @Test
        @DisplayName("Moves once it is facing the required direction")
        void should_Move_when_FacingRequiredDirection() {
            var robot = robotAt();
            var route = routeOf(new GridPos(1, 0));

            robot.followRoute(route);
            robot.tickMovement(1);
            robot.tickMovement(1);

            assertThat(robot.position()).isEqualTo(new GridPos(1, 0));
            assertThat(robot.isMoving()).isFalse();
        }

        @Test
        @DisplayName("Does not turn again when continuing in the same direction")
        void should_NotTurnAgain_when_ContinuingInSameDirection() {
            var robot = robotAt();
            var route = routeOf(
                    new GridPos(1, 0),
                    new GridPos(2, 0)
            );
            robot.followRoute(route);
            robot.tickMovement(1);
            robot.tickMovement(1);
            robot.tickMovement(1);

            assertThat(robot.position()).isEqualTo(new GridPos(2, 0));
            assertThat(robot.isMoving()).isFalse();
        }

        @Test
        @DisplayName("Keeps the previous facing in sync once it stops turning")
        void should_KeepPreviousFacingInSync_when_NotTurning() {
            var robot = robotAt();
            var route = routeOf(new GridPos(1, 0));

            robot.followRoute(route);
            robot.tickMovement(1);
            robot.tickMovement(1);
            robot.tickMovement(1);

            assertThat(robot.previousFacing()).isEqualTo(robot.facing());
        }

        @Test
        @DisplayName("Remains busy when ticked before the action duration elapses")
        void should_RemainBusy_when_TickedBeforeActionDurationElapses() {
            var robot = robotAt();

            robot.beginPickup(3);
            robot.tickAction();
            robot.tickAction();

            assertThat(robot.isBusy()).isTrue();
            assertThat(robot.action()).isEqualTo(RobotAction.PICKING_UP);
        }

        @Test
        @DisplayName("Becomes idle when the action duration elapses")
        void should_BecomeIdle_when_ActionDurationElapses() {
            var robot = robotAt();

            robot.beginDropoff(2);
            robot.tickAction();
            robot.tickAction();

            assertThat(robot.isBusy()).isFalse();
            assertThat(robot.action()).isEqualTo(RobotAction.IDLE);
        }

        @Test
        @DisplayName("Advances the route independently of an in-progress action")
        void should_AdvanceRoute_when_ActionIsAlsoInProgress() {
            var robot = robotAt();
            var route = routeOf(new GridPos(0, 1));

            robot.followRoute(route);
            robot.beginPickup(1);
            robot.tickMovement(1);

            assertThat(robot.position()).isEqualTo(new GridPos(0, 1));
            assertThat(robot.isBusy()).isTrue();
        }

        @Test
        @DisplayName("Progresses an in-progress action independently of a pending route")
        void should_ProgressAction_when_RouteIsAlsoPending() {
            var robot = robotAt();
            var route = routeOf(new GridPos(0, 1));

            robot.followRoute(route);
            robot.beginPickup(1);
            robot.tickAction();

            assertThat(robot.isBusy()).isFalse();
            assertThat(robot.isMoving()).isTrue();
        }

        @Test
        @DisplayName("Starts fully charged")
        void should_StartFullyCharged_when_Constructed() {
            var robot = robotAt();

            assertThat(robot.battery().level()).isEqualTo(100);
            assertThat(robot.battery().capacity()).isEqualTo(100);
        }

        @Test
        @DisplayName("Drains battery when advancing into a new cell")
        void should_DrainBattery_when_AdvancingIntoNewCell() {
            var robot = robotAt();
            var route = routeOf(new GridPos(0, 1));

            robot.followRoute(route);
            robot.tickMovement(1);

            assertThat(robot.position()).isEqualTo(new GridPos(0, 1));
            assertThat(robot.battery().level()).isEqualTo(99);
        }

        @Test
        @DisplayName("Accumulates fractional drain across cells instead of dropping it")
        void should_AccumulateFractionalDrain_when_DrainPerCellIsFractional() {
            var robot = robotAt();
            var route = routeOf(
                    new GridPos(0, 1),
                    new GridPos(0, 2)
            );
            robot.followRoute(route);
            robot.tickMovement(0.5);

            assertThat(robot.battery().level()).isEqualTo(100);

            robot.tickMovement(0.5);

            assertThat(robot.battery().level()).isEqualTo(99);
        }

        @Test
        @DisplayName("Does not drain battery while turning in place")
        void should_NotDrainBattery_when_TurningInPlace() {
            var robot = robotAt();
            var route = routeOf(new GridPos(1, 0));

            robot.followRoute(route);
            robot.tickMovement(1);

            assertThat(robot.facing()).isEqualTo(Direction.EAST);
            assertThat(robot.battery().level()).isEqualTo(100);
        }

        @Test
        @DisplayName("Clamps battery at zero instead of going negative")
        void should_ClampBatteryAtZero_when_DrainExceedsRemainingBattery() {
            var robot = robotAt(1);
            var route = routeOf(new GridPos(0, 1));

            robot.followRoute(route);
            robot.tickMovement(5);

            assertThat(robot.battery().level()).isEqualTo(0);
        }

        @Test
        @DisplayName("Stops the robot from advancing once battery is depleted")
        void should_NotAdvance_when_BatteryIsDepleted() {
            var robot = robotAt(0);
            var route = routeOf(new GridPos(1, 0));

            robot.followRoute(route);
            robot.tickMovement(1);

            assertThat(robot.position()).isEqualTo(new GridPos(0, 0));
            assertThat(robot.facing()).isEqualTo(Direction.NORTH);
            assertThat(robot.isMoving()).isTrue();
        }

        @Test
        @DisplayName("Increases battery by the charge rate each tick while charging")
        void should_IncreaseBattery_when_ChargingTicks() {
            var robot = robotAt(5);

            driveNorth(robot, 3);
            robot.beginCharging(1);

            robot.tickCharging();

            assertThat(robot.battery().level()).isEqualTo(3);
            assertThat(robot.isBusy()).isTrue();
            assertThat(robot.action()).isEqualTo(RobotAction.CHARGING);
        }

        @Test
        @DisplayName("Takes as many ticks to reach full as the deficit requires")
        void should_TakeTicksProportionalToDeficit_when_Charging() {
            var robot = robotAt(5);

            driveNorth(robot, 3);
            robot.beginCharging(1);

            robot.tickCharging();
            robot.tickCharging();

            assertThat(robot.battery().level()).isEqualTo(4);
            assertThat(robot.isBusy()).isTrue();

            robot.tickCharging();

            assertThat(robot.battery().level()).isEqualTo(5);
            assertThat(robot.isBusy()).isFalse();
            assertThat(robot.action()).isEqualTo(RobotAction.IDLE);
        }

        @Test
        @DisplayName("Accumulates fractional charge across ticks instead of dropping it")
        void should_AccumulateFractionalCharge_when_ChargeRateIsFractional() {
            var robot = robotAt();

            driveNorth(robot, 4);

            robot.beginCharging(1.5);
            robot.tickCharging();

            assertThat(robot.battery().level()).isEqualTo(97);

            robot.tickCharging();

            assertThat(robot.battery().level()).isEqualTo(99);
        }

        @Test
        @DisplayName("Clamps battery at max instead of overshooting")
        void should_ClampBatteryAtMax_when_ChargeRateExceedsDeficit() {
            var robot = robotAt();
            var route = routeOf(new GridPos(0, 1));

            robot.followRoute(route);
            robot.tickMovement(1);
            robot.beginCharging(10);
            robot.tickCharging();

            assertThat(robot.battery().level()).isEqualTo(100);
            assertThat(robot.isBusy()).isFalse();
        }
    }

    @Nested
    @DisplayName("beginPickup")
    class BeginPickupMethodTests {

        @Test
        @DisplayName("Becomes busy picking up when a pickup begins")
        void should_BecomeBusyPickingUp_when_PickupBegins() {
            var robot = robotAt();

            robot.beginPickup(3);

            assertThat(robot.isBusy()).isTrue();
            assertThat(robot.action()).isEqualTo(RobotAction.PICKING_UP);
        }
    }

    @Nested
    @DisplayName("beginDropoff")
    class BeginDropoffMethodTests {

        @Test
        @DisplayName("Becomes busy dropping off when a dropoff begins")
        void should_BecomeBusyDroppingOff_when_DropoffBegins() {
            var robot = robotAt();

            robot.beginDropoff(2);

            assertThat(robot.isBusy()).isTrue();
            assertThat(robot.action()).isEqualTo(RobotAction.DROPPING_OFF);
        }
    }

    @Nested
    @DisplayName("beginCharging")
    class BeginChargingMethodTests {

        @Test
        @DisplayName("Becomes busy charging when charging begins")
        void should_BecomeBusyCharging_when_ChargingBegins() {
            var robot = robotAt();

            robot.beginCharging(1);

            assertThat(robot.isBusy()).isTrue();
            assertThat(robot.action()).isEqualTo(RobotAction.CHARGING);
        }
    }

    @Nested
    @DisplayName("carriedPackage")
    class CarriedPackageMethodTests {

        @Test
        @DisplayName("Returns null when the robot is empty-handed")
        void should_ReturnNull_when_RobotIsEmptyHanded() {
            assertThat(robotAt().carriedPackage()).isNull();
        }
    }

    @Nested
    @DisplayName("pickUp")
    class PickUpMethodTests {

        @Test
        @DisplayName("Carries the supplied package")
        void should_CarryPackage_when_PackageIsSupplied() {
            var robot = robotAt();
            var pkg = packageWithId(1);

            robot.pickUp(pkg);

            assertThat(robot.carriedPackage()).isEqualTo(pkg);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null package")
        void should_RejectPackage_when_PackageIsNull() {
            assertThatNullPointerException().isThrownBy(() -> robotAt().pickUp(null));
        }
    }

    @Nested
    @DisplayName("dropOff")
    class DropOffMethodTests {

        @Test
        @DisplayName("Clears the carried package")
        void should_ClearCarriedPackage_when_PackageIsDroppedOff() {
            var robot = robotAt();

            robot.pickUp(packageWithId(1));
            robot.dropOff();

            assertThat(robot.carriedPackage()).isNull();
        }
    }

    @Nested
    @DisplayName("setPosition")
    class SetPositionMethodTests {

        @Test
        @DisplayName("Resets the previous position when the position is set directly")
        void should_ResetPreviousPosition_when_PositionIsSetDirectly() {
            var robot = robotAt();
            var route = routeOf(new GridPos(1, 0));

            robot.followRoute(route);
            robot.tickMovement(1);

            robot.setPosition(new GridPos(5, 5));

            assertThat(robot.previousPosition()).isEqualTo(new GridPos(5, 5));
            assertThat(robot.position()).isEqualTo(new GridPos(5, 5));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null position")
        void should_RejectPosition_when_PositionIsNull() {
            assertThatNullPointerException().isThrownBy(() -> robotAt().setPosition(null));
        }
    }

    @Nested
    @DisplayName("followRoute")
    class FollowRouteMethodTests {

        @Test
        @DisplayName("Replaces the current route when called again")
        void should_ReplaceExistingRoute_when_FollowRouteCalledAgain() {
            var robot = robotAt();
            var route = routeOf(
                    new GridPos(1, 0),
                    new GridPos(2, 0)
            );
            robot.followRoute(route);
            robot.followRoute(routeOf(new GridPos(0, 1)));
            robot.tickMovement(1);

            assertThat(robot.position()).isEqualTo(new GridPos(0, 1));
            assertThat(robot.isMoving()).isFalse();
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null route")
        void should_RejectRoute_when_RouteIsNull() {
            assertThatNullPointerException().isThrownBy(() -> robotAt().followRoute(null));
        }
    }
}
