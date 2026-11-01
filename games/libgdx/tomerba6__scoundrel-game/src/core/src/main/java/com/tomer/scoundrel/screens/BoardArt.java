package com.tomer.scoundrel.screens;

/**
 * Everything on the board that is not the card frame or the top HUD: the card's
 * own header and value numeral, the trophy rail along the bottom left, the
 * potion marker opposite it, and the event feed down the right.
 *
 * <p>Coordinates are 1280×720 with y measured downward, as the art is
 * specified; {@link CardArt#toWorldY} converts when drawing. This is the one
 * place these numbers live.
 */
final class BoardArt {

    /** The 2px recess every widget on the board sits in. */
    static final int FRAME = 2;

    // --- the card's header and value --------------------------------------

    /** The 6px padding inside the plate, which is itself inset by the frame. */
    private static final int HEADER_PAD = 6;
    /** The suit pip beside the rank, 12px square. */
    static final int PIP = 12;
    /** Between the rank and its pip. */
    static final int PIP_GAP = 4;
    /**
     * The numeral's baseline, measured down from the top of the card: with the
     * row at 214, the glyph's foot sits at y=432.
     */
    static final int VALUE_BOTTOM = 218;
    /** A hard offset, not a blur: the shadow is the glyph moved down four. */
    static final int VALUE_SHADOW_DY = 4;
    /** The numeral's shadow colour, drawn at {@link #VALUE_SHADOW_ALPHA}. */
    static final int VALUE_SHADOW = 0x0a0806;
    /** The shadow's alpha. */
    static final float VALUE_SHADOW_ALPHA = 0.7f;
    /** The numeral, rank and pip colour: bone. */
    static final int VALUE_COLOUR = 0xe8ddc7;

    // --- the trophy rail ---------------------------------------------------

    /** The rail well's left edge, frame included, in design pixels. */
    static final int RAIL_X = 24;
    /** The rail well's top edge, frame included, in design pixels measured downward. */
    static final int RAIL_Y = 610;
    /** The rail well's size, square, frame included, in design pixels. */
    static final int RAIL_BOX = 80;
    /**
     * The card sprite at ×1, centred in the {@link #RAIL_BOX} well. Anything
     * between ×1 and ×2 is an uneven scale — at 72px, ×1.125, some source pixels
     * would take two screen pixels and their neighbours one — so the well keeps
     * its size and only the icon shrinks.
     */
    static final int RAIL_ICON = Sprites.SIZE;
    /** The recess the icon sits in. */
    static final int RAIL_WELL = 0x12161a;

    /** The label, chips and plate stack up in a column to the right of the well. */
    static final int COLUMN_X = 116;
    /**
     * Text is placed by its top, not its baseline: that is what a Batch draw
     * takes, and pretending otherwise puts every label a font's ascent out.
     */
    static final int NAME_TOP = 628;
    /** The weapon's name. */
    static final int NAME_COLOUR = 0x74838f;

    /** The slain chips' top edge, in design pixels measured downward. */
    static final int CHIP_Y = 646;
    /** A chip's width, frame included, in design pixels. */
    static final int CHIP_W = 22;
    /** A chip's height, frame included, in design pixels. */
    static final int CHIP_H = 30;
    /** From one chip's left edge to the next, in design pixels. */
    static final int CHIP_PITCH = 26;
    /** A chip's face. */
    static final int CHIP_FACE = 0x4e2620;
    /** The slain monster's value on its chip. */
    static final int CHIP_LABEL = 0xa35543;

    /** The bite plate's top edge, in design pixels measured downward. */
    static final int PLATE_Y = 649;
    /** The bite plate's height, in design pixels. */
    static final int PLATE_H = 24;
    /** Padding either side of the bite plate's text, in design pixels. */
    static final int PLATE_PAD_X = 11;
    /** Clear of the last chip's own trailing gap. */
    private static final int PLATE_GAP = 8;

    // --- the potion marker -------------------------------------------------

    /** The potion marker's left edge, in design pixels. */
    static final int MARKER_X = 1108;
    /** The potion marker's top edge, in design pixels measured downward. */
    static final int MARKER_Y = 632;
    /** The potion marker's size, square, frame included, in design pixels. */
    static final int MARKER_BOX = 36;
    /**
     * The sprite halved — every 2×2 source block becomes one pixel, which is
     * the gentlest shrink that keeps the grid even.
     */
    static final int MARKER_ICON = Sprites.SIZE / 2;
    /** The marker label's left edge, in design pixels. */
    static final int MARKER_LABEL_X = 1152;
    /** The marker label's top edge, in design pixels measured downward. */
    static final int MARKER_LABEL_TOP = 645;
    /** The POTION READY label. */
    static final int MARKER_READY = 0x4a3524;
    /** The POTION USED label: gold. */
    static final int MARKER_USED = 0xd9a441;

    // --- the event feed ----------------------------------------------------

    /** Right-aligned against the same margin the Avoid button keeps. */
    static final int FEED_RIGHT = 1256;
    /** The first feed line's top edge, in design pixels measured downward. */
    static final int FEED_TOP = 96;
    /** From one feed line to the next, in design pixels. */
    static final int FEED_PITCH = 20;
    /** The feed's text colour, before its fade. */
    static final int FEED_COLOUR = 0x9a8b70;

    // --- the depth line under the ticker -----------------------------------

    /** The depth line's top edge, in design pixels measured downward. */
    static final int DEPTH_TOP = 54;
    /** The depth line's colour. */
    static final int DEPTH_COLOUR = 0x9a8b70;
    /** The dim tail on the health readout: "/20 HP". */
    static final int HP_SUFFIX_COLOUR = 0x6b5f4c;
    /** Between the health number and its tail, in design pixels. */
    static final int HP_SUFFIX_GAP = 8;

    /**
     * The line YOU DIED grows outward from, above the middle of the screen.
     * Drawing it by the top of its line instead — which is what a Batch draw
     * takes — would make it grow downward, so it would read as being pushed
     * rather than as arriving.
     */
    static final int DEATH_TITLE_CENTRE_Y = 300;

    private BoardArt() {
    }

    /**
     * Where the rank starts, inside the frame and the header's padding.
     *
     * @param slotX the card's left edge, in design pixels
     * @return the rank's left edge, in design pixels
     */
    static int rankX(int slotX) {
        return slotX + CardArt.FRAME + HEADER_PAD;
    }

    /**
     * The type label is right-aligned; this is the edge it ends on.
     *
     * @param slotX the card's left edge, in design pixels
     * @return the type label's right edge, in design pixels
     */
    static int typeRightX(int slotX) {
        return slotX + CardArt.CARD_W - CardArt.FRAME - HEADER_PAD;
    }

    /**
     * The pip's top edge, centred in the header band of a card in the room row.
     *
     * @return the top edge, in design pixels measured downward
     */
    static int pipY() {
        return CardArt.SLOT_Y + CardArt.FRAME + (CardArt.HEADER_H - PIP) / 2;
    }

    /**
     * The value numeral's centre line, the card's middle.
     *
     * @param slotX the card's left edge, in design pixels
     * @return the centre, in design pixels
     */
    static int valueCentreX(int slotX) {
        return slotX + CardArt.CARD_W / 2;
    }

    /**
     * The rail icon's left edge, centred in its well.
     *
     * @return the left edge, in design pixels
     */
    static int railIconX() {
        return RAIL_X + (RAIL_BOX - RAIL_ICON) / 2;
    }

    /**
     * The rail icon's top edge, centred in its well.
     *
     * @return the top edge, in design pixels measured downward
     */
    static int railIconY() {
        return RAIL_Y + (RAIL_BOX - RAIL_ICON) / 2;
    }

    /**
     * The i-th slain chip, marching right from the column.
     *
     * @param index the chip, from 0 for the first kill
     * @return its left edge, in design pixels
     */
    static int chipX(int index) {
        return COLUMN_X + index * CHIP_PITCH;
    }

    /**
     * The degradation plate sits past the last chip, so it moves as kills mount.
     *
     * @param slainCount how many chips are on the rail
     * @return the plate's left edge, in design pixels
     */
    static int slaysPlateX(int slainCount) {
        return COLUMN_X + Math.max(0, slainCount) * CHIP_PITCH + PLATE_GAP;
    }

    /**
     * The marker icon's left edge, centred in its box.
     *
     * @return the left edge, in design pixels
     */
    static int markerIconX() {
        return MARKER_X + (MARKER_BOX - MARKER_ICON) / 2;
    }

    /**
     * The marker icon's top edge, centred in its box.
     *
     * @return the top edge, in design pixels measured downward
     */
    static int markerIconY() {
        return MARKER_Y + (MARKER_BOX - MARKER_ICON) / 2;
    }

    /**
     * Feed lines stack downward, newest last, under the Avoid button.
     *
     * @param index the line, from 0 (the oldest, at the top)
     * @return its top edge, in design pixels measured downward
     */
    static int feedLineY(int index) {
        return FEED_TOP + index * FEED_PITCH;
    }
}
