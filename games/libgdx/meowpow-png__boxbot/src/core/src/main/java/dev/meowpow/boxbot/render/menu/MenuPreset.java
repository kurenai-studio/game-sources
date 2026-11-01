package dev.meowpow.boxbot.render.menu;

/**
 * A named menu geometry: panel width and button sizing.
 *
 * @param panelWidth the panel's width, before scaling
 * @param buttonHeight the height of one button, before scaling
 * @param buttonGap the vertical gap between buttons, before scaling
 */
public record MenuPreset(float panelWidth, float buttonHeight, float buttonGap) {

    /**
     * @throws IllegalArgumentException if {@code panelWidth}
     * or {@code buttonHeight} is not positive, or if {@code buttonGap} is negative
     */
    public MenuPreset {
        if (panelWidth <= 0f) {
            throw new IllegalArgumentException("panelWidth must be positive");
        }
        if (buttonHeight <= 0f) {
            throw new IllegalArgumentException("buttonHeight must be positive");
        }
        if (buttonGap < 0f) {
            throw new IllegalArgumentException("buttonGap must not be negative");
        }
    }
}
