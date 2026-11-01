package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.CardType;

/**
 * How a card is built: its measurements and the ramp its type is drawn from.
 * The one place these numbers live.
 *
 * <p>Pure, so the arithmetic is testable and {@link CardFrame} is left with
 * nothing but draw calls.
 *
 * <p>Coordinates are 1280×720 with <b>y measured downward</b> from the top of
 * the screen, which is how the art is specified. The viewport measures y
 * upward, so {@link #toWorldY} converts, in one place.
 */
final class CardArt {

    /**
     * The five colours a card type is drawn from, each {@code 0xRRGGBB}.
     *
     * @param plate the card's face
     * @param light the top and left bevel
     * @param dark  the bottom and right bevel
     * @param well  the recess the sprite sits in
     * @param label the type stamped in the header
     */
    record Palette(int plate, int light, int dark, int well, int label) {
    }

    private static final Palette MONSTER = new Palette(0x230d16, 0x4f1d1e, 0x12060f, 0x0e050c, 0xa85338);
    private static final Palette WEAPON = new Palette(0x141a24, 0x333f4c, 0x090c14, 0x070a10, 0x8a9ea8);
    private static final Palette POTION = new Palette(0x17281a, 0x325a31, 0x0e1a12, 0x0a1310, 0x71b45c);

    /** The bezel around every card, whatever its type. */
    static final int OUTER = 0x0f1410;
    /** Stage background. */
    static final int BACKDROP = 0x100c09;

    /** A card's width, in design pixels. */
    static final int CARD_W = 176;
    /** A card's height, in design pixels. */
    static final int CARD_H = 256;
    /**
     * The card row's top bezel, in design pixels measured downward: 145 below
     * the HUD strip and 140 above the rail.
     */
    static final int SLOT_Y = 214;
    private static final int SLOT_X0 = 252;
    private static final int SLOT_PITCH = 200;

    /** The outer frame the plate is inset by, and the bevel drawn inside it. */
    static final int FRAME = 2;
    /** Each bevel's thickness, in design pixels. */
    static final int BEVEL = 2;
    /** Rank and type sit here; the well begins below it. */
    static final int HEADER_H = 26;
    /** The well's height, in design pixels; the sprite is centred in it. */
    static final int WELL_H = 140;
    private static final int WELL_MARGIN = 6;
    /** 64×64 drawn at ×2. */
    static final int SPRITE = 128;

    private CardArt() {
    }

    /**
     * The colours a card of this type is drawn in: flesh, iron or rot.
     *
     * @param type the card's type
     * @return its palette, drawn mostly from that ramp
     */
    static Palette paletteFor(CardType type) {
        return switch (type) {
            case MONSTER -> MONSTER;
            case WEAPON -> WEAPON;
            case POTION -> POTION;
        };
    }

    /**
     * Left edge of the i-th of four slots; the row is centred in the world.
     *
     * @param index the slot, from 0 on the left to 3
     * @return the slot's left edge, in design pixels
     */
    static int slotX(int index) {
        return SLOT_X0 + index * SLOT_PITCH;
    }

    /**
     * Top of the well. The plate is inset by the frame, so the 26px header runs
     * from {@code SLOT_Y + FRAME} and the well starts {@code FRAME} lower than
     * {@code SLOT_Y + 26}.
     *
     * @return the well's top edge, in design pixels measured downward
     */
    static int wellTop() {
        return SLOT_Y + FRAME + HEADER_H;
    }

    /**
     * The well's left edge, inside the frame and a margin.
     *
     * @param slotX the card's left edge, in design pixels
     * @return the well's left edge, in design pixels
     */
    static int wellLeft(int slotX) {
        return slotX + FRAME + WELL_MARGIN;
    }

    /**
     * The well's width, the same on every card.
     *
     * @return the width, in design pixels
     */
    static int wellWidth() {
        return CARD_W - 2 * (FRAME + WELL_MARGIN);
    }

    /**
     * Where the ×2 sprite's left edge goes, centred in the well.
     *
     * @param slotX the card's left edge, in design pixels
     * @return the sprite's left edge, in design pixels
     */
    static int spriteLeft(int slotX) {
        return wellLeft(slotX) + (wellWidth() - SPRITE) / 2;
    }

    /**
     * Where the ×2 sprite's top edge goes, centred in the well.
     *
     * @return the sprite's top edge, in design pixels measured downward
     */
    static int spriteTop() {
        return wellTop() + (WELL_H - SPRITE) / 2;
    }

    /**
     * Design-space y (down from the top) to world y (up from the bottom), for
     * an element {@code height} tall.
     *
     * @param designY the element's top edge, measured down from the top of the stage
     * @param height  the element's height
     * @return the element's bottom edge, measured up from the bottom
     */
    static int toWorldY(int designY, int height) {
        return (int) Theme.WORLD_HEIGHT - designY - height;
    }
}
