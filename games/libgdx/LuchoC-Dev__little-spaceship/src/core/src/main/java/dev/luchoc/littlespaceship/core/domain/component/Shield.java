package dev.luchoc.littlespaceship.core.domain.component;

/**
 * An active shield: the defensive layer that absorbs a hit before the attachment or a life.
 *
 * <p>A marker and nothing else. Unlike the attachment, a shield carries no durability: whatever hit
 * it absorbs removes it entirely, which is the confirmed rule in {@code 03-game-systems.md}.
 */
public final class Shield {

    /**
     * Creates an active shield.
     */
    public Shield() {
    }
}
