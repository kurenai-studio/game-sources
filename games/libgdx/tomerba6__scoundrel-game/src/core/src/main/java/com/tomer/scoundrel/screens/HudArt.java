package com.tomer.scoundrel.screens;

/**
 * The board HUD's measurements and colours — the health bar, the depth ticker
 * and the Avoid button. This is the one place they live.
 *
 * <p>Coordinates are 1280×720 with y measured downward, as the art is
 * specified; {@link CardArt#toWorldY} converts when drawing.
 *
 * <p>Note that the chrome colours are <b>not</b> all on the sprite ramps. The
 * frame and two of the bar's three bands sit between ramp steps, and are listed
 * in {@link UiPalette}. Sprites are strictly on-palette; the furniture around
 * them is matched exactly to the design instead.
 */
final class HudArt {

    // --- shared colours ----------------------------------------------------

    /** The 2px recess around every widget. */
    static final int FRAME = 0x0f1410;
    /** The gold of a live plate, the lit ticks and the bite plate: the accent ramp's torch. */
    static final int GOLD = 0xd9a441;
    /** A gold plate's light top bevel. */
    static final int GOLD_LIGHT = 0xf2cf7a;
    /** A gold plate's dark bottom bevel. */
    static final int GOLD_DARK = 0xb5651f;
    /** Label colour on a gold plate. */
    static final int LABEL_DARK = 0x12101c;

    // --- health bar --------------------------------------------------------

    /** The health bar's left edge, frame included, in design pixels. */
    static final int BAR_X = 24;
    /** The health bar's top edge, frame included, in design pixels measured downward. */
    static final int BAR_Y = 34;
    /** The health bar's width, frame included, in design pixels. */
    static final int BAR_W = 216;
    /** The health bar's height, frame included, in design pixels. */
    static final int BAR_H = 24;

    /**
     * Three bands, lightest at the top, so the bar reads as a lit surface
     * rather than a flat rectangle.
     */
    static final int BAND_TOP = 6;
    /** The middle band's height, in design pixels. */
    static final int BAND_MID = 8;
    /** The lowest band's height, in design pixels. */
    static final int BAND_LOW = 6;
    /** The fill's top band, at rest: bone. */
    static final int FILL_TOP = 0xe8ddc7;
    /** The fill's middle band, at rest. */
    static final int FILL_MID = 0x9a8b70;
    /** The fill's lowest band, at rest. */
    static final int FILL_LOW = 0x6b5f4c;
    /**
     * What is left when health has gone: a flat body under a 2px lip, rather
     * than the three bands the filled part carries. The spent track reads as a
     * recess that way, not as an unlit copy of the bar.
     */
    static final int BAR_EMPTY = 0x1e2a1c;
    /** The spent track's lip, along its top. */
    static final int BAR_EMPTY_LIP = 0x3b4334;
    /** The lip's height, in design pixels. */
    static final int BAR_LIP_H = 2;
    /** Heal repaints the fill in this before settling back. */
    static final int FILL_HEAL = 0x71b45c;
    /** And damage repaints it in dried blood as it drains. */
    static final int FILL_BLOOD = 0x8c2f22;

    /** The health readout beside the bar, and where it sits. */
    static final int NUMBER_X = BAR_X + BAR_W + 10;
    /** The readout's baseline, in design pixels measured downward: it sits beside the bar rather than under it. */
    static final int NUMBER_BASELINE = 44;
    /** The number's colour when nothing is happening to the bar: bone. */
    static final int NUMBER_REST = 0xe8ddc7;

    /**
     * Separators are an overlay on a continuous bar, not one cell per point of
     * health — the fill is proportional and these are drawn on top of it.
     */
    static final int SEGMENT_PITCH = 10;
    /** A separator's width, in design pixels. */
    static final int SEGMENT_GAP = 2;
    /** A separator's colour, drawn at {@link #SEGMENT_ALPHA}. */
    static final int SEGMENT_LINE = 0x2d3029;
    /**
     * The separators are translucent, so each takes the tone of the band it
     * crosses rather than cutting a flat grey line through all three. This
     * colour at 0.798 blends to #535349 over the fill's top band and to #30342b
     * over the spent track's lip, which are the two tones it has to hit.
     */
    static final float SEGMENT_ALPHA = 0.798f;

    // --- depth ticker ------------------------------------------------------

    /** The ticker strip's top edge, in design pixels measured downward. */
    static final int TICKER_Y = 26;
    /** A tick's height, in design pixels. */
    static final int TICKER_H = 20;
    /** A tick's width, in design pixels. */
    static final int TICK_W = 2;
    /** From one tick's left edge to the next, in design pixels. */
    static final int TICK_PITCH = 4;
    /** A tick for a card already out of the dungeon. */
    static final int TICK_DIM = 0x20180e;

    // --- avoid button ------------------------------------------------------

    /**
     * The whole button, <b>frame included</b>: the 2px recess, with the plate
     * and its bevel inside it, like every other widget.
     */
    static final int AVOID_X = 1141;
    /** The Avoid button's top edge, in design pixels measured downward. */
    static final int AVOID_Y = 24;
    /** The Avoid button's width, in design pixels. */
    static final int AVOID_W = 115;
    /** The Avoid button's height, in design pixels; every board plate shares it. */
    static final int AVOID_H = 45;

    private HudArt() {
    }

    /**
     * The bar inside its 2px frame, across.
     *
     * @return the fillable width, in design pixels
     */
    static int barInteriorWidth() {
        return BAR_W - 2 * 2;
    }

    /**
     * The bar inside its 2px frame, down.
     *
     * @return the fillable height, in design pixels
     */
    static int barInteriorHeight() {
        return BAR_H - 2 * 2;
    }

    /**
     * How much of the bar is filled, clamped so a negative score draws nothing.
     *
     * @param health    current health, any value
     * @param maxHealth the ruleset's cap, which a full bar stands for
     * @return the filled width, 0 to {@link #barInteriorWidth()}, in design pixels
     */
    static int barFillWidth(int health, int maxHealth) {
        if (health <= 0 || maxHealth <= 0) {
            return 0;
        }
        int clamped = Math.min(health, maxHealth);
        return Math.round(barInteriorWidth() * clamped / (float) maxHealth);
    }

    /**
     * One tick per card still face-down, so the ticker is a real gauge.
     *
     * @param depth cards still face-down
     * @return how many ticks are lit, 0 or more
     */
    static int ticksLit(int depth) {
        return Math.max(0, depth);
    }

    /**
     * How wide a strip of ticks is, first tick's left edge to last tick's right.
     *
     * @param deckSize how many ticks
     * @return the width, in design pixels; 0 for none
     */
    static int tickerWidth(int deckSize) {
        return deckSize <= 0 ? 0 : deckSize * TICK_PITCH - (TICK_PITCH - TICK_W);
    }

    /**
     * Where the ticker's first tick goes, for a dungeon this deep. The
     * <b>lit</b> block is centred on the board rather than the whole strip: the
     * gold is what you actually read, and keeping it in the middle means the eye
     * never has to follow it. The cost is that the strip walks right as the
     * dungeon drains, taking its dim tail with it.
     *
     * @param depth cards still face-down
     * @return the first tick's left edge, in design pixels
     */
    static int tickerX(int depth) {
        return Math.round((Theme.WORLD_WIDTH - tickerWidth(depth)) / 2f);
    }

    /**
     * Whether a point in <b>world</b> coordinates — y upward, as the pointer
     * arrives — is on the Avoid plate. The plate is drawn from design-space
     * numbers, so the conversion happens here rather than at every call.
     *
     * @param worldX the point's x, in world space
     * @param worldY the point's y, in world space
     * @return true if the point is on the plate, frame included
     */
    static boolean avoidContains(float worldX, float worldY) {
        float bottom = CardArt.toWorldY(AVOID_Y, AVOID_H);
        return worldX >= AVOID_X && worldX < AVOID_X + AVOID_W
                && worldY >= bottom && worldY < bottom + AVOID_H;
    }
}
