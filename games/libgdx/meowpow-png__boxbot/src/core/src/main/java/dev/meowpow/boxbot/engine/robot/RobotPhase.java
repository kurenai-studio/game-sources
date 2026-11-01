package dev.meowpow.boxbot.engine.robot;

import java.util.Objects;

/**
 * The stage of a job's lifecycle
 * the robot is currently executing
 */
sealed interface RobotPhase {

    RobotPhase TO_SOURCE = new ToSource();
    RobotPhase PICKING_UP = new PickingUp();
    RobotPhase TO_CHARGING_STATION = new ToChargingStation();
    RobotPhase CHARGING = new Charging();
    RobotPhase STOPPED = new Stopped();

    record ToSource() implements RobotPhase {}

    record PickingUp() implements RobotPhase {}

    record ToDestination(RelocationDestination destination) implements RobotPhase {

        public ToDestination {
            Objects.requireNonNull(destination, "destination must not be null");
        }
    }

    record DroppingOff(RelocationDestination destination) implements RobotPhase {

        public DroppingOff {
            Objects.requireNonNull(destination, "destination must not be null");
        }
    }

    record ToChargingStation() implements RobotPhase {}

    record Charging() implements RobotPhase {}

    record Stopped() implements RobotPhase {}
}
