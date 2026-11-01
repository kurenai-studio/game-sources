package dev.meowpow.boxbot.render;

import dev.meowpow.boxbot.render.assets.FontFamily;
import dev.meowpow.boxbot.render.assets.FontSpec;

/**
 * Builds font specs for labels drawn in world space.
 */
public final class WorldLabelFontFactory {

    private static final FontFamily FONT_FAMILY = FontFamily.ALLERTA_STENCIL;

    private static final int SHELF_LABEL_SIZE = 10;
    private static final int LOADING_BAY_LABEL_SIZE = 18;
    private static final int QUEUE_NUMBER_LABEL_SIZE = 8;

    private WorldLabelFontFactory() {}

    /**
     * Returns the spec for a shelf label.
     */
    public static FontSpec shelfFontSpec() {
        return FontSpec.of(FONT_FAMILY, SHELF_LABEL_SIZE, RenderColors.ACCENT);
    }

    /**
     * Returns the spec for the loading bay label.
     */
    public static FontSpec loadingBayFontSpec() {
        return FontSpec.of(FONT_FAMILY, LOADING_BAY_LABEL_SIZE, RenderColors.ACCENT);
    }

    /**
     * Returns the spec for a queued-selection order number label.
     */
    public static FontSpec queueNumberFontSpec() {
        return FontSpec.of(FONT_FAMILY, QUEUE_NUMBER_LABEL_SIZE, RenderColors.ACCENT);
    }
}
