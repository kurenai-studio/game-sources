package dev.meowpow.boxbot.config;

/**
 * Fixed-step pacing for the simulation.
 *
 * @param robotMovementTickDuration seconds per robot movement tick
 * @param robotActionTickDuration seconds per robot action tick
 * @param robotChargingTickDuration seconds per robot charging tick
 * @param simulationTickDuration seconds per world simulation tick
 */
public record TimingConfig(
        float robotMovementTickDuration,
        float robotActionTickDuration,
        float robotChargingTickDuration,
        float simulationTickDuration
) {

    /**
     * @throws IllegalArgumentException if any argument is not positive
     */
    public TimingConfig {
        if (Float.isNaN(robotMovementTickDuration) || robotMovementTickDuration <= 0) {
            var message = "robotMovementTickDuration must be > 0, got ";
            throw new IllegalArgumentException(message + robotMovementTickDuration);
        }
        if (Float.isNaN(robotActionTickDuration) || robotActionTickDuration <= 0) {
            var message = "robotActionTickDuration must be > 0, got ";
            throw new IllegalArgumentException(message + robotActionTickDuration);
        }
        if (Float.isNaN(robotChargingTickDuration) || robotChargingTickDuration <= 0) {
            var message = "robotChargingTickDuration must be > 0, got ";
            throw new IllegalArgumentException(message + robotChargingTickDuration);
        }
        if (Float.isNaN(simulationTickDuration) || simulationTickDuration <= 0) {
            var message = "simulationTickDuration must be > 0, got ";
            throw new IllegalArgumentException(message + simulationTickDuration);
        }
    }
}
