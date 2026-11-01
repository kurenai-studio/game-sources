package dev.meowpow.boxbot.config;

/**
 * Player input constraints.
 *
 * @param selectionQueueLimit maximum pairs the player can queue at once
 */
public record InputConfig(int selectionQueueLimit) {

    /**
     * @throws IllegalArgumentException if {@code selectionQueueLimit} is not positive
     */
    public InputConfig {
        if (selectionQueueLimit <= 0) {
            var message = "selectionQueueLimit must be > 0, got ";
            throw new IllegalArgumentException(message + selectionQueueLimit);
        }
    }
}
