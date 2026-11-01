package dev.meowpow.boxbot.engine.entity;

/**
 * A package's identifier.
 *
 * @param value the underlying identifier
 */
public record PackageId(int value) {

    /**
     * @throws IllegalArgumentException if {@code value} is negative
     */
    public PackageId {
        if (value < 0) {
            throw new IllegalArgumentException("value must be >= 0, got " + value);
        }
    }

    @Override
    public String toString() {
        return String.valueOf(value);
    }
}
