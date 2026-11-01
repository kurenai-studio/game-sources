package dev.meowpow.boxbot.engine.robot;

/**
 * Snapshot of the loading bay's capacity at decision time.
 * <p>
 * It is shared between inbound-awaiting-putaway
 * and outbound-awaiting-shipment packages.
 *
 * @param freeTiles tiles neither occupied nor reserved
 * @param totalTiles the bay's total tile capacity
 */
public record LoadingBayView(int freeTiles, int totalTiles) {

    /**
     * @throws IllegalArgumentException if {@code totalTiles} is negative,
     * or {@code freeTiles} is negative or exceeds {@code totalTiles}
     */
    public LoadingBayView {
        if (totalTiles < 0) {
            throw new IllegalArgumentException("totalTiles must be >= 0, got " + totalTiles);
        }
        if (freeTiles < 0 || freeTiles > totalTiles) {
            var message = "freeTiles must be between 0 and totalTiles (" + totalTiles + "), got ";
            throw new IllegalArgumentException(message + freeTiles);
        }
    }
}
