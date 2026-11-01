package dev.meowpow.boxbot.engine.robot;

/**
 * Represents the job type.
 */
public enum JobType {
    /**
     * Store a newly arrived package on a shelf.
     */
    PUTAWAY,
    /**
     * Fetch a stored package and deliver it to the loading bay.
     */
    RETRIEVAL
}
