package dev.meowpow.boxbot.engine.robot;

/**
 * Snapshot of shipment failures at decision time.
 *
 * @param count shipment failures so far
 * @param limit configured failure limit
 */
public record Failures(int count, int limit) {

    /**
     * @throws IllegalArgumentException if any argument is negative
     */
    public Failures {
        if (count < 0) {
            throw new IllegalArgumentException("count must be >= 0, got " + count);
        }
        if (limit < 0) {
            throw new IllegalArgumentException("limit must be >= 0, got " + limit);
        }
    }
}
