package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.utils.Align;

import java.util.Objects;

/**
 * A right-aligned line of text with fixed-width digit slots.
 * <p>
 * <strong>Implementation Note:</strong>
 * The purpose of this class is so that a changing value
 * (e.g., {@code mm:ss} countdown) doesn't shift horizontally
 * as its digits change width under a proportional font.
 */
@HotPath
public final class HudTimeText {

    private static final char[] DIGITS = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};

    private final GlyphLayout layout = new GlyphLayout();
    private final StringBuilder content = new StringBuilder();
    private final BitmapFont font;
    private final Color color;
    private final float digitSlotWidth;

    /**
     * Creates a time text drawn with the given font and color.
     *
     * @param font the font to draw with
     * @param color the draw color
     *
     * @throws NullPointerException if {@code font} or {@code color} is null
     */
    HudTimeText(BitmapFont font, Color color) {
        Objects.requireNonNull(font, "font must not be null");
        Objects.requireNonNull(color, "color must not be null");

        this.font = font;
        this.color = new Color(color);
        this.digitSlotWidth = maxDigitAdvance(font);
    }

    /**
     * Returns the widest digit's natural advance width.
     * <p>
     * <strong>Implementation Note:</strong>
     * Reads {@link BitmapFont.Glyph#xadvance} directly rather than
     * measuring a one-character {@link GlyphLayout}: {@code GlyphLayout}
     * treats a run's last character as the string's end and uses its tight
     * visual width instead of its advance, which would under-measure
     * every character here since each is laid out alone.
     */
    private static float maxDigitAdvance(BitmapFont font) {
        var data = font.getData();
        float max = 0f;
        for (char digit : DIGITS) {
            max = Math.max(max, data.getGlyph(digit).xadvance * data.scaleX);
        }
        return max;
    }

    /**
     * Returns the mutable buffer backing this text's content.
     */
    StringBuilder content() {
        return content;
    }

    /**
     * Changes the color this text draws with.
     *
     * @param color the new draw color
     *
     * @throws NullPointerException if {@code color} is null
     */
    void setColor(Color color) {
        Objects.requireNonNull(color, "color must not be null");
        this.color.set(color);
    }

    /**
     * Draws the current content, right-aligned
     * so its right edge lands at {@code rightX}.
     * <p>
     * <strong>API Note:</strong>
     * Every character is centered within its own advance width;
     * digits share one fixed-width slot, and other characters
     * use their own natural advance as their slot, so
     * spacing stays even between neighboring digits.
     *
     * @param batch the batch to draw into
     * @param rightX the text's right edge, in world units
     * @param y the top draw position, in world units
     */
    void render(SpriteBatch batch, float rightX, float y) {
        font.setColor(color);

        int length = content.length();
        float totalWidth = 0f;
        for (int i = 0; i < length; i++) {
            totalWidth += advanceWidth(content.charAt(i));
        }

        float x = rightX - totalWidth;
        for (int i = 0; i < length; i++) {
            char c = content.charAt(i);
            float slot = advanceWidth(c);

            layout.setText(
                    font,
                    content, i,
                    i + 1, color,
                    0f,
                    Align.left,
                    false,
                    null
            );
            float charX = x + (slot - layout.width) / 2f;
            font.draw(batch, layout, charX, y);

            x += slot;
        }
    }

    private float advanceWidth(char c) {
        if (Character.isDigit(c)) {
            return digitSlotWidth;
        }
        var data = font.getData();
        var glyph = data.getGlyph(c);
        return glyph == null ? 0f : glyph.xadvance * data.scaleX;
    }
}
