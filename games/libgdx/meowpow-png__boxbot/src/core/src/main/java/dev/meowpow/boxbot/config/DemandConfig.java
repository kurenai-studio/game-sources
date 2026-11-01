package dev.meowpow.boxbot.config;

import java.util.Objects;

/**
 * Inbound stock and outbound shipment demand for a simulation run.
 *
 * @param preseedFraction fraction of shelves to stock before the run begins, between 0 and 1
 * @param baseOrderIntervalTicks baseline ticks between outbound-order arrivals
 * @param deliveryTimerTicks ticks allotted to ship a started outbound order
 * @param urgentThresholdTicks ticks before an order is considered urgent enough
 * @param truckVisitIntervalTicks ticks between loading-bay truck visits
 * @param truckOperationDelayTicks ticks paused between each truck pickup or drop-off
 * @param truckCapacity packages picked up and dropped off by the truck per visit
 * @param supply cyclical inbound-supply tuning
 * @param demandCycle cyclical outbound-order demand tuning
 */
public record DemandConfig(
        double preseedFraction,
        int baseOrderIntervalTicks,
        int deliveryTimerTicks,
        int urgentThresholdTicks,
        int truckVisitIntervalTicks,
        int truckOperationDelayTicks,
        int truckCapacity,
        SupplyConfig supply,
        DemandCycleConfig demandCycle
) {

    /**
     * @throws IllegalArgumentException if any value is outside its supported range
     * @throws NullPointerException if {@code supply} or {@code demandCycle} is null
     */
    public DemandConfig {
        Objects.requireNonNull(supply, "supply must not be null");
        Objects.requireNonNull(demandCycle, "demandCycle must not be null");
        if (Double.isNaN(preseedFraction) || preseedFraction < 0 || preseedFraction > 1) {
            var message = "preseedFraction must be between 0 and 1, got ";
            throw new IllegalArgumentException(message + preseedFraction);
        }
        if (baseOrderIntervalTicks <= 0) {
            var message = "baseOrderIntervalTicks must be > 0, got ";
            throw new IllegalArgumentException(message + baseOrderIntervalTicks);
        }
        if (deliveryTimerTicks <= 0) {
            var message = "deliveryTimerTicks must be > 0, got ";
            throw new IllegalArgumentException(message + deliveryTimerTicks);
        }
        if (urgentThresholdTicks < 0) {
            var message = "urgentThresholdTicks must be >= 0, got ";
            throw new IllegalArgumentException(message + urgentThresholdTicks);
        }
        if (truckVisitIntervalTicks <= 0) {
            var message = "truckVisitIntervalTicks must be > 0, got ";
            throw new IllegalArgumentException(message + truckVisitIntervalTicks);
        }
        if (truckOperationDelayTicks <= 0) {
            var message = "truckOperationDelayTicks must be > 0, got ";
            throw new IllegalArgumentException(message + truckOperationDelayTicks);
        }
        if (truckCapacity <= 0) {
            var message = "truckCapacity must be > 0, got " + truckCapacity;
            throw new IllegalArgumentException(message);
        }
    }
}
