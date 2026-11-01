package dev.meowpow.boxbot.render.menu;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

import java.util.Objects;

/**
 * Represents a single line of centered text.
 */
@HotPath
public final class TextComponent implements MenuComponent {

    private final BitmapFont font;
    private final Color color;
    private final GlyphLayout glyphLayout = new GlyphLayout();

    private String text;

    /**
     * @throws NullPointerException if any argument is null
     */
    public TextComponent(BitmapFont font, Color color, String text) {
        this.font = Objects.requireNonNull(font, "font must not be null");
        this.color = Objects.requireNonNull(color, "color must not be null");
        this.text = Objects.requireNonNull(text, "text must not be null");
    }

    /**
     * Updates this component's text.
     *
     * @throws NullPointerException if {@code text} is null
     */
    public void setText(String text) {
        this.text = Objects.requireNonNull(text, "text must not be null");
    }

    @Override
    public float height() {
        return font.getLineHeight();
    }

    @Override
    public void renderText(SpriteBatch batch, float x, float y, float width) {
        font.setColor(color);
        glyphLayout.setText(font, text);

        float textX = x + (width - glyphLayout.width) / 2f;
        float textY = y + height();

        font.draw(batch, glyphLayout, textX, textY);
    }
}
