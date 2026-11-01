package dev.meowpow.boxbot.engine.robot;

/**
 * Player-issued requests for an in-progress relocation job.
 */
record JobRequest(boolean pickupCancelRequested, boolean chargingRequested) {

    static final JobRequest NONE = new JobRequest(false, false);

    JobRequest withPickupCancelRequested() {
        return new JobRequest(true, chargingRequested);
    }

    JobRequest withChargingRequested(boolean chargingRequested) {
        return new JobRequest(pickupCancelRequested, chargingRequested);
    }
}
