package dev.meowpow.boxbot.input.selection;

import java.util.Objects;

/**
 * Represents a queued selection pair.
 *
 * @param primary the source package to act on
 * @param secondary the chosen destination
 */
public record SelectionPair(SelectionTarget primary, SelectionTarget secondary) {

    /**
     * @throws NullPointerException if {@code primary} or {@code secondary} is null
     */
    public SelectionPair {
        Objects.requireNonNull(primary, "primary must not be null");
        Objects.requireNonNull(secondary, "secondary must not be null");
    }
}
