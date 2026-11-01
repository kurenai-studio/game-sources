package dev.meowpow.boxbot.render.menu;

import dev.meowpow.boxbot.render.assets.FontFamily;
import dev.meowpow.boxbot.render.assets.FontSpec;

import com.badlogic.gdx.graphics.Color;

public final class MenuFontFactory {

    /**
     * Base font size for menu title.
     */
    public static final int TITLE_FONT_SIZE = 32;

    /**
     * Base font size for menu button labels.
     */
    public static final int BUTTON_FONT_SIZE = 16;

    /**
     * Base border thickness for menu title font.
     */
    public static final float TITLE_FONT_BORDER_WIDTH = 0.6f;

    /**
     * Base border thickness for menu button font.
     */
    public static final float BUTTON_FONT_BORDER_WIDTH = 0.6f;

    /**
     * Base extra horizontal space between title font letters.
     */
    public static final float TITLE_LETTER_SPACING = 5f;

    /**
     * Base extra horizontal space between button font's letters.
     */
    public static final float BUTTON_LETTER_SPACING = 3f;

    private static final FontFamily FONT_FAMILY = FontFamily.OXANIUM;

    private MenuFontFactory() {}

    /**
     * Returns the spec for menu
     * title font at the given scale.
     *
     * @param scale the integer pixel scale for menu geometry
     */
    public static FontSpec titleFontSpec(int scale) {
        return new FontSpec(
                FONT_FAMILY,
                TITLE_FONT_SIZE * scale,
                Color.WHITE,
                TITLE_FONT_BORDER_WIDTH * scale,
                TITLE_LETTER_SPACING * scale
        );
    }

    /**
     * Returns the spec for menu
     * button font at the given scale.
     *
     * @param scale the integer pixel scale for menu geometry
     */
    public static FontSpec buttonFontSpec(int scale) {
        return new FontSpec(
                FONT_FAMILY,
                BUTTON_FONT_SIZE * scale,
                Color.WHITE,
                BUTTON_FONT_BORDER_WIDTH * scale,
                BUTTON_LETTER_SPACING * scale
        );
    }
}
