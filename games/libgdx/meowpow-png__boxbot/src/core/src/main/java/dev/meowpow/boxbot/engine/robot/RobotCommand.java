package dev.meowpow.boxbot.engine.robot;

import org.jspecify.annotations.Nullable;

import java.util.Objects;

/**
 * The player-issued command the robot is currently carrying out.
 */
sealed interface RobotCommand {

    record Relocating(
            JobSource source,
            @Nullable RelocationDestination destination,
            boolean retrieved,
            JobRequest request
    ) implements RobotCommand {

        public Relocating {
            Objects.requireNonNull(source, "source must not be null");
            Objects.requireNonNull(request, "request must not be null");
        }

        Relocating(JobSource source, @Nullable RelocationDestination destination, boolean retrieved) {
            this(source, destination, retrieved, JobRequest.NONE);
        }

        Relocating withDestination(@Nullable RelocationDestination destination) {
            return new Relocating(source, destination, retrieved, request);
        }

        Relocating withRetrieved() {
            return new Relocating(source, destination, true, request);
        }

        Relocating withPickupCancelRequested() {
            return new Relocating(
                    source,
                    destination,
                    retrieved,
                    request.withPickupCancelRequested()
            );
        }

        Relocating withChargingRequested(boolean chargingRequested) {
            return new Relocating(
                    source,
                    destination,
                    retrieved,
                    request.withChargingRequested(chargingRequested)
            );
        }

        boolean pickupCancelRequested() {
            return request.pickupCancelRequested();
        }

        boolean chargingRequested() {
            return request.chargingRequested();
        }
    }

    record Charging() implements RobotCommand {}
}
