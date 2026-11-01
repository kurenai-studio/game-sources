package dev.meowpow.boxbot.engine.robot;

import java.util.Objects;

/**
 * A job's identifier.
 *
 * @param value the underlying identifier
 */
public record JobId(String value) {

    /**
     * @throws NullPointerException if {@code value} is null
     * @throws IllegalArgumentException if {@code value} is blank
     */
    public JobId {
        Objects.requireNonNull(value, "value must not be null");
        if (value.isBlank()) {
            throw new IllegalArgumentException("value must not be blank");
        }
    }

    @Override
    public String toString() {
        return value;
    }
}
