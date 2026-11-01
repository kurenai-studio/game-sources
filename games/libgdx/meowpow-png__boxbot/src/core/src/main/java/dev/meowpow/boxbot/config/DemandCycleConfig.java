package dev.meowpow.boxbot.config;

/**
 * Tuning for cyclical outbound order demand.
 *
 * @param cycleLengthTicks ticks in one complete demand cycle
 * @param minimumRateFactor lowest fraction of the base order rate used during a cycle
 * @param maximumRateFactor highest fraction of the base order rate used during a cycle
 */
public record DemandCycleConfig(
        int cycleLengthTicks,
        double minimumRateFactor,
        double maximumRateFactor
) {

    /**
     * @throws IllegalArgumentException if any value is outside its supported range
     */
    public DemandCycleConfig {
        if (cycleLengthTicks <= 0 || cycleLengthTicks % 2 != 0) {
            var message = "cycleLengthTicks must be positive and even, got ";
            throw new IllegalArgumentException(message + cycleLengthTicks);
        }
        if (!Double.isFinite(minimumRateFactor) || minimumRateFactor <= 0) {
            var message = "minimumRateFactor must be greater than 0, got ";
            throw new IllegalArgumentException(message + minimumRateFactor);
        }
        if (!Double.isFinite(maximumRateFactor) || maximumRateFactor < minimumRateFactor) {
            var message = "maximumRateFactor must be at least minimumRateFactor, got ";
            throw new IllegalArgumentException(message + maximumRateFactor);
        }
    }
}
