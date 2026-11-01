package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.math.Rectangle;

/**
 * Divides the HUD's overall screen
 * bounds into a vertical stack of panels.
 */
@HotPath
public final class HudLayout {

    private final Rectangle[] panelBounds;
    private final float gap;

    /**
     * Creates a layout with the
     * given number of panel slots and gap.
     *
     * @param panelCount the number of panel slots to divide bounds into
     * @param gap the vertical spacing between adjacent panels, in pixels
     *
     * @throws IllegalArgumentException if {@code panelCount}
     * is not positive, or {@code gap} is negative
     */
    public HudLayout(int panelCount, float gap) {
        if (panelCount <= 0) {
            var message = "panelCount must be positive: " + panelCount;
            throw new IllegalArgumentException(message);
        }
        if (gap < 0f) {
            var message = "gap must not be negative: " + gap;
            throw new IllegalArgumentException(message);
        }
        this.gap = gap;
        this.panelBounds = new Rectangle[panelCount];
        for (int i = 0; i < panelCount; i++) {
            panelBounds[i] = new Rectangle();
        }
    }

    /**
     * Recomputes every panel slot to stack
     * evenly within the given bounds, top to bottom.
     *
     * @param bounds the overall screen bounds to divide, in pixels
     */
    public void update(Rectangle bounds) {
        int count = panelBounds.length;
        float totalGap = gap * (count - 1);
        float panelHeight = (bounds.height - totalGap) / count;

        for (int i = 0; i < count; i++) {
            float y = bounds.y + bounds.height - (i + 1) * panelHeight - i * gap;
            panelBounds[i].set(bounds.x, y, bounds.width, panelHeight);
        }
    }

    /**
     * Returns the screen bounds of the panel slot
     * at the given index, counting top to bottom from zero.
     *
     * @param index the panel slot's index
     */
    public Rectangle panelBounds(int index) {
        return panelBounds[index];
    }
}
