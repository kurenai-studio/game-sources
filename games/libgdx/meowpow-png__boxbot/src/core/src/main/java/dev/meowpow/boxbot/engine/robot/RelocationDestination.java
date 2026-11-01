package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.entity.ShelfId;

import java.util.Objects;

/**
 * Where a carried package should be delivered.
 */
public sealed interface RelocationDestination {

    /**
     * Deliver to a specific shelf.
     *
     * @param shelfId the destination shelf
     */
    record Shelf(ShelfId shelfId) implements RelocationDestination {

        /**
         * @throws NullPointerException if {@code shelfId} is null
         */
        public Shelf {
            Objects.requireNonNull(shelfId, "shelfId must not be null");
        }
    }

    /**
     * Deliver to the loading bay.
     */
    record Bay() implements RelocationDestination {}
}
