package dev.meowpow.boxbot.render.assets;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator;
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator.FreeTypeFontParameter;
import com.badlogic.gdx.utils.Disposable;

/**
 * Represents a baked bitmap font.
 */
public final class BakedFont implements Disposable {

    private final BitmapFont font;

    /**
     * Bakes a font from the given generator,
     * following the given specifications.
     *
     * @param generator the font source to render glyphs with
     * @param spec how the font should look
     */
    BakedFont(FreeTypeFontGenerator generator, FontSpec spec) {
        var parameter = new FreeTypeFontParameter();

        parameter.size = spec.size();
        parameter.color = spec.color();
        parameter.minFilter = Texture.TextureFilter.Nearest;
        parameter.magFilter = Texture.TextureFilter.Nearest;
        parameter.spaceX = (int) spec.letterSpacing();

        if (spec.borderWidth() > 0f) {
            parameter.borderWidth = spec.borderWidth();
            parameter.borderColor = spec.color();
        }
        font = generator.generateFont(parameter);
    }

    /**
     * Returns the baked font.
     */
    public BitmapFont font() {
        return font;
    }

    @Override
    public void dispose() {
        font.dispose();
    }
}
