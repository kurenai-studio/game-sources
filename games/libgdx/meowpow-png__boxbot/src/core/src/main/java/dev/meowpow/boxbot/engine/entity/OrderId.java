package dev.meowpow.boxbot.engine.entity;

/**
 * An outbound order's identifier.
 *
 * @param value the underlying identifier
 */
public record OrderId(int value) {

    /**
     * @throws IllegalArgumentException if {@code value} is negative
     */
    public OrderId {
        if (value < 0) {
            throw new IllegalArgumentException("value must be >= 0, got " + value);
        }
    }

    @Override
    public String toString() {
        return String.valueOf(value);
    }
}
