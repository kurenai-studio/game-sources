package dev.meowpow.boxbot.config;

/**
 * Warehouse constraints for a simulation run.
 *
 * @param batteryMaxCapacity maximum battery level of each robot
 * @param backlogLimit shipment-failure backlog limit before a run ends
 */
public record WarehouseConfig(int batteryMaxCapacity, int backlogLimit) {

    /**
     * @throws IllegalArgumentException if {@code batteryMaxCapacity}
     * is not positive or {@code backlogLimit} is negative
     */
    public WarehouseConfig {
        if (batteryMaxCapacity <= 0) {
            var message = "batteryMaxCapacity must be > 0, got ";
            throw new IllegalArgumentException(message + batteryMaxCapacity);
        }
        if (backlogLimit < 0) {
            var message = "backlogLimit must be >= 0, got ";
            throw new IllegalArgumentException(message + backlogLimit);
        }
    }
}
