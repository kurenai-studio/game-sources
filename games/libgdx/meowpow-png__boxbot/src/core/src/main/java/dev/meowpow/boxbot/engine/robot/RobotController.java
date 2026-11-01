package dev.meowpow.boxbot.engine.robot;

import org.jspecify.annotations.Nullable;

/**
 * Decides the robot's next action.
 */
public interface RobotController {

    /**
     * Decides the next action given the current observation.
     *
     * @param observation immutable snapshot of the world at the moment of the call
     *
     * @return the action to take
     */
    ControllerDecision decide(Observation observation);

    /**
     * Returns the destination an in-progress delivery
     * should be redirected to, or null to keep its current one.
     */
    default @Nullable RelocationDestination requestedRedirect() {
        return null;
    }

    /**
     * Returns the destination an in-progress delivery
     * should be redirected to, or null to keep its current one.
     *
     * @param observation immutable snapshot of the world at the moment of the call
     */
    default @Nullable RelocationDestination requestedRedirect(Observation observation) {
        return requestedRedirect();
    }

    /**
     * Returns whether the in-progress delivery should
     * be abandoned, leaving the robot idle with its package.
     */
    default boolean cancelRequested() {
        return false;
    }

    /**
     * Returns whether the in-progress delivery
     * should be abandoned using the current observation.
     *
     * @param observation immutable snapshot of the world at the moment of the call
     */
    default boolean cancelRequested(Observation observation) {
        return cancelRequested();
    }

    /**
     * Returns whether the robot should give up on
     * its current job's package before it's been picked up.
     */
    default boolean pickupCancelled() {
        return false;
    }

    /**
     * Returns the source an in-progress trip to pick up
     * a package should be redirected to, or null to keep its current one.
     */
    default @Nullable JobSource requestedSource() {
        return null;
    }

    /**
     * Returns whether the robot should detour to
     * charge, carrying its in-progress delivery along.
     */
    default boolean chargingRequested() {
        return false;
    }
}
