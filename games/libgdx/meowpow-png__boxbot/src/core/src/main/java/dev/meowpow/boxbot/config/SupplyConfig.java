package dev.meowpow.boxbot.config;

/**
 * Rules that shape inbound supply over time.
 *
 * @param cycleLengthTicks ticks in one complete supply cycle
 * @param minimumFactor lowest fraction of truck drop-off capacity used during a cycle
 * @param floorFraction fraction of a color's quota that activates floor protection
 */
public record SupplyConfig(
        int cycleLengthTicks,
        double minimumFactor,
        double floorFraction
) {

    /**
     * @throws IllegalArgumentException if a value is outside its supported range
     */
    public SupplyConfig {
        if (cycleLengthTicks <= 0 || cycleLengthTicks % 2 != 0) {
            var message = "cycleLengthTicks must be positive and even, got ";
            throw new IllegalArgumentException(message + cycleLengthTicks);
        }
        if (!Double.isFinite(minimumFactor) || minimumFactor <= 0 || minimumFactor > 1) {
            var message = "minimumFactor must be greater than 0 and at most 1, got ";
            throw new IllegalArgumentException(message + minimumFactor);
        }
        if (!Double.isFinite(floorFraction) || floorFraction < 0 || floorFraction > 1) {
            var message = "floorFraction must be between 0 and 1, got ";
            throw new IllegalArgumentException(message + floorFraction);
        }
    }
}
