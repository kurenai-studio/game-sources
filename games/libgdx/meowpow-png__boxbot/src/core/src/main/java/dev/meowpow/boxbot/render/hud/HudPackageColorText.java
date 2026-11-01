package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.RenderColors;

import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

/**
 * A single line of text, tinted
 * according to which package color it names.
 */
@HotPath
public final class HudPackageColorText {

    private final HudText none;
    private final HudText red;
    private final HudText green;
    private final HudText blue;

    private HudText current;

    /**
     * Creates a package color text drawn
     * with the given font and alignment.
     *
     * @param font the font to draw with
     * @param align the horizontal alignment relative to draw position
     */
    HudPackageColorText(BitmapFont font, HudText.Alignment align) {
        none = new HudText(font, align, RenderColors.HUD_PANEL_BODY_FONT);
        red = new HudText(font, align, RenderColors.PACKAGE_RED);
        green = new HudText(font, align, RenderColors.PACKAGE_GREEN);
        blue = new HudText(font, align, RenderColors.PACKAGE_BLUE);
        current = none;
    }

    /**
     * Replaces this text's content,
     * tinting it according to given color.
     *
     * @param color the package color to tint the text with
     * @param text the new content
     */
    void setText(PackageColor color, CharSequence text) {
        current = switch (color) {
            case RED -> red;
            case GREEN -> green;
            case BLUE -> blue;
            case NONE -> none;
        };
        current.setText(text);
    }

    /**
     * Returns this text's rendered height
     * for its current content, in world units.
     */
    float height() {
        return current.height();
    }

    /**
     * Draws the current content at the given position.
     *
     * @param batch the batch to draw into
     * @param x the horizontal draw position, in world units
     * @param y the top draw position, in world units
     */
    void render(SpriteBatch batch, float x, float y) {
        current.render(batch, x, y);
    }
}
