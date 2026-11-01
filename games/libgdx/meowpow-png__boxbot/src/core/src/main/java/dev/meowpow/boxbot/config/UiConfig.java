package dev.meowpow.boxbot.config;

/**
 * UI display tuning.
 *
 * @param orderWarningThresholdPercent percent threshold at which orders are emitting warning
 * @param orderCriticalThresholdPercent percent threshold at which orders are emitting critical warning
 */
public record UiConfig(
        double orderWarningThresholdPercent,
        double orderCriticalThresholdPercent
) {

    /**
     * @throws IllegalArgumentException if an order threshold is invalid
     */
    public UiConfig {
        if (Double.isNaN(orderWarningThresholdPercent)) {
            throw new IllegalArgumentException("orderWarningThresholdPercent must not be NaN");
        }
        if (orderWarningThresholdPercent < 0) {
            var message = "orderWarningThresholdPercent must not be negative, got ";
            throw new IllegalArgumentException(message + orderWarningThresholdPercent);
        }
        if (orderWarningThresholdPercent > 1) {
            var message = "orderWarningThresholdPercent must not exceed 1, got ";
            throw new IllegalArgumentException(message + orderWarningThresholdPercent);
        }
        if (Double.isNaN(orderCriticalThresholdPercent)) {
            throw new IllegalArgumentException("orderCriticalThresholdPercent must not be NaN");
        }
        if (orderCriticalThresholdPercent < 0) {
            var message = "orderCriticalThresholdPercent must not be negative, got ";
            throw new IllegalArgumentException(message + orderCriticalThresholdPercent);
        }
        if (orderCriticalThresholdPercent > orderWarningThresholdPercent) {
            var m1 = "orderCriticalThresholdPercent must not exceed ";
            var m2 = "orderWarningThresholdPercent, got " + orderCriticalThresholdPercent;
            throw new IllegalArgumentException(m1 + m2);
        }
    }
}
