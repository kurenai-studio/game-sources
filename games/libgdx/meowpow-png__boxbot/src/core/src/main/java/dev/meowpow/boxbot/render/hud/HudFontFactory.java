package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.render.assets.FontFamily;
import dev.meowpow.boxbot.render.assets.FontSpec;

import com.badlogic.gdx.graphics.Color;

/**
 * Builds font specs for HUD panel text.
 */
public final class HudFontFactory {

    private static final FontFamily FONT_FAMILY = FontFamily.OXANIUM;

    private static final int HUD_HEADER_LABEL_SIZE = 12;
    private static final int HUD_BODY_LABEL_SIZE = 9;

    private static final float HEADER_FONT_BORDER_WIDTH = 0.3f;
    private static final float BODY_FONT_BORDER_WIDTH = 0.3f;

    private static final float HEADER_LETTER_SPACING = 0.5f;
    private static final float BODY_LETTER_SPACING = 0.2f;

    private HudFontFactory() {}

    /**
     * Returns the spec for HUD
     * panel header text at the given scale.
     *
     * @param scale the integer pixel scale for HUD geometry
     */
    public static FontSpec headerFontSpec(int scale) {
        return new FontSpec(
                FONT_FAMILY,
                HUD_HEADER_LABEL_SIZE * scale,
                Color.WHITE,
                HEADER_FONT_BORDER_WIDTH * scale,
                HEADER_LETTER_SPACING * scale
        );
    }

    /**
     * Returns the spec for HUD
     * panel body text at the given scale.
     *
     * @param scale the integer pixel scale for HUD geometry
     */
    public static FontSpec bodyFontSpec(int scale) {
        return new FontSpec(
                FONT_FAMILY,
                HUD_BODY_LABEL_SIZE * scale,
                Color.WHITE,
                BODY_FONT_BORDER_WIDTH * scale,
                BODY_LETTER_SPACING * scale
        );
    }
}
