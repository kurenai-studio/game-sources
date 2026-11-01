package com.tomer.scoundrel.screens;

/**
 * Where the move chooser's plates go. It opens on the card you pressed when
 * that card has more than one legal move — an armed monster, most often — and
 * offers one plate per move.
 *
 * <p>The plates are the Avoid button's plate, not a popup's buttons: the board
 * has exactly one button shape, and a chooser in its own style would read as a
 * dialog arriving over the game rather than as part of it. There is no panel
 * behind them and no shadow under them; the stack is the whole widget.
 *
 * <p>Coordinates are 1280×720 with y measured downward, as the art is
 * specified; {@link CardArt#toWorldY} converts when drawing and when hit-testing
 * a pointer, which arrives the other way up.
 */
final class ChooserArt {

    /** The Avoid button's plate, exactly — one button shape on the board. */
    static final int PLATE_H = HudArt.AVOID_H;
    /** Breathing room either side of the label inside the plate. */
    static final int PAD_X = 16;
    /** Between one plate and the next. */
    static final int GAP = 6;

    private ChooserArt() {
    }

    /**
     * A plate wide enough for its label. Every plate in a stack takes the
     * widest label's width — a ragged stack reads as two unrelated buttons
     * rather than as a choice between two things.
     *
     * @param labelWidth the widest label in the stack, in pixels
     * @return the plate width, in design pixels
     */
    static int plateW(int labelWidth) {
        return labelWidth + 2 * PAD_X;
    }

    /**
     * How tall a stack of plates is, gaps included.
     *
     * @param count how many plates, 0 or more
     * @return the stack's height, in design pixels
     */
    static int stackH(int count) {
        return count * PLATE_H + Math.max(0, count - 1) * GAP;
    }

    /**
     * The top of the i-th plate. The stack straddles the card's middle, so the
     * choice appears over the thing it is about and the card stays readable
     * above and below it.
     *
     * @param index which plate, from 0 at the top
     * @param count how many plates the stack has
     * @return the plate's top edge, in design pixels measured downward
     */
    static int plateY(int index, int count) {
        int top = CardArt.SLOT_Y + (CardArt.CARD_H - stackH(count)) / 2;
        return top + index * (PLATE_H + GAP);
    }

    /**
     * The left edge of every plate in the stack, centred on the card.
     *
     * @param slotX  the card's left edge, in design pixels
     * @param plateW the plates' width, from {@link #plateW}
     * @return the plates' left edge, in design pixels
     */
    static int plateX(int slotX, int plateW) {
        return slotX + (CardArt.CARD_W - plateW) / 2;
    }

    /**
     * Which plate a point in <b>world</b> coordinates is on, or -1 for none —
     * including the gaps between them, which must not resolve anything.
     *
     * @param slotX  the card's left edge, in design pixels
     * @param plateW the plates' width
     * @param count  how many plates the stack has
     * @param worldX the point's x, in world space
     * @param worldY the point's y, in world space (y up)
     * @return the plate's index from 0 at the top, or -1
     */
    static int indexAt(int slotX, int plateW, int count, float worldX, float worldY) {
        int left = plateX(slotX, plateW);
        if (worldX < left || worldX >= left + plateW) {
            return -1;
        }
        for (int i = 0; i < count; i++) {
            float bottom = CardArt.toWorldY(plateY(i, count), PLATE_H);
            if (worldY >= bottom && worldY < bottom + PLATE_H) {
                return i;
            }
        }
        return -1;
    }
}
