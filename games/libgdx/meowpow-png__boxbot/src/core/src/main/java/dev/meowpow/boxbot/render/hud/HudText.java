package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

import java.util.Objects;

/**
 * Draws a single line of HUD text.
 */
@HotPath
public final class HudText {

    /**
     * Horizontal alignment relative to the draw position.
     */
    public enum Alignment {LEFT, RIGHT, CENTER}

    private final GlyphLayout layout = new GlyphLayout();
    private final StringBuilder content = new StringBuilder();
    private final Color color;

    private final BitmapFont font;
    private final Alignment align;

    /**
     * Creates a text primitive drawn
     * with the given font, alignment, and color.
     * <p>
     * <strong>Implementation Note:</strong>
     * The font must be generated with a neutral, white baked
     * color for {@code color} to reproduce accurately; a font
     * baked with its own color multiplies against it instead.
     *
     * @param font the font to draw with
     * @param align the horizontal alignment relative to draw position
     * @param color the draw color
     *
     * @throws NullPointerException if any argument is null
     */
    public HudText(BitmapFont font, Alignment align, Color color) {
        this.font = Objects.requireNonNull(font, "font must not be null");
        this.align = Objects.requireNonNull(align, "align must not be null");
        this.color = new Color(Objects.requireNonNull(color, "color must not be null"));
    }

    /**
     * Returns the mutable buffer backing this text's content.
     */
    public StringBuilder content() {
        return content;
    }

    /**
     * Replaces this text's content.
     *
     * @param text the new content
     *
     * @throws NullPointerException if {@code text} is null
     */
    public void setText(CharSequence text) {
        Objects.requireNonNull(text, "text must not be null");
        content.setLength(0);
        content.append(text);
    }

    /**
     * Returns this text's rendered width
     * for its current content, in world units.
     */
    public float width() {
        layout.setText(font, content);
        return layout.width;
    }

    /**
     * Returns this text's rendered height
     * for its current content, in world units.
     */
    public float height() {
        layout.setText(font, content);
        return layout.height;
    }

    /**
     * Draws the current content at the given position.
     *
     * @param batch the batch to draw into
     * @param x the horizontal draw position, in world units
     * @param y the top draw position, in world units
     */
    public void render(SpriteBatch batch, float x, float y) {
        font.setColor(color);
        layout.setText(font, content);

        float drawX = switch (align) {
            case LEFT -> x;
            case RIGHT -> x - layout.width;
            case CENTER -> x - layout.width / 2f;
        };
        font.draw(batch, layout, drawX, y);
    }
}
