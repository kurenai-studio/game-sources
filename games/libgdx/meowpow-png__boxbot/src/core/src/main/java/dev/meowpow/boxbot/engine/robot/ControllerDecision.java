package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.entity.ShelfId;

import java.util.Objects;

/**
 * The decision returned by the robot
 * controller for a given observation.
 */
public sealed interface ControllerDecision {

    ControllerDecision CHARGE = new Charge();
    ControllerDecision GO_TO_BAY = new GoToBay();
    ControllerDecision IDLE = new Idle();

    /**
     * Commit to processing a pending job.
     *
     * @param jobId the pending job to commit to
     */
    record TakeJob(JobId jobId) implements ControllerDecision {

        /**
         * @param jobId the pending job to commit to
         *
         * @throws NullPointerException if jobId is null
         */
        public TakeJob {
            Objects.requireNonNull(jobId, "jobId must not be null");
        }
    }

    /**
     * Commit to retrieving whatever package
     * currently occupies the given shelf.
     *
     * @param shelfId the shelf to retrieve from
     */
    record Retrieve(ShelfId shelfId) implements ControllerDecision {

        /**
         * @param shelfId the shelf to retrieve from
         *
         * @throws NullPointerException if shelfId is null
         */
        public Retrieve {
            Objects.requireNonNull(shelfId, "shelfId must not be null");
        }
    }

    /**
     * Choose a shelf to store the currently
     * carried package on, for a putaway job.
     *
     * @param shelfId the chosen destination shelf
     */
    record StoreAt(ShelfId shelfId) implements ControllerDecision {

        /**
         * @param shelfId the chosen destination shelf
         *
         * @throws NullPointerException if shelfId is null
         */
        public StoreAt {
            Objects.requireNonNull(shelfId, "shelfId must not be null");
        }
    }

    /**
     * Go charge instead of taking a job.
     */
    record Charge() implements ControllerDecision {}

    /**
     * Head to the loading bay to deliver
     * the package currently being carried.
     */
    record GoToBay() implements ControllerDecision {}

    /**
     * No-op for this decision.
     */
    record Idle() implements ControllerDecision {}
}
