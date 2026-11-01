package dev.meowpow.boxbot.engine.robot;

/**
 * Creates controllers for newly built simulations.
 */
@FunctionalInterface
public interface RobotControllerFactory {

    /**
     * Creates a controller using the configured urgency threshold.
     *
     * @param urgentThresholdTicks ticks before an outbound order becomes urgent
     *
     * @return a new controller for the simulation
     */
    RobotController create(int urgentThresholdTicks);
}
