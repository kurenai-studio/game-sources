package com.tomer.scoundrel.screens;

import java.util.List;

/**
 * The eight marks that ring the card the tutorial is talking about.
 *
 * <p>Eight 24×4 ticks that leave the edges <b>open</b> —
 * corners only, never a closed box. That is not decoration: a closed outline
 * reads as a second card border and fights the one already printed on the card,
 * where four corner brackets read as a viewfinder over it.
 *
 * <p>They sit just outside the card so none of them covers its art, and each
 * corner's two arms share their corner square so the L is solid.
 */
final class CornerTicks {

    /** How long each arm of a corner is, in design pixels. */
    static final int LENGTH = 24;
    /** How thick each arm is, in design pixels; also the gap outside the card. */
    static final int THICK = 4;

    /**
     * One mark, in design space with y measured downward.
     *
     * @param x the mark's left edge
     * @param y the mark's top edge
     * @param w its width: {@link #LENGTH} for a horizontal arm, {@link #THICK} for a vertical one
     * @param h its height, the other way round
     */
    record Tick(int x, int y, int w, int h) {
    }

    private CornerTicks() {
    }

    /**
     * The eight ticks around a rect, clockwise from the top left.
     *
     * @param x the card's left edge, in design pixels
     * @param y the card's top edge, in design pixels measured downward
     * @param w the card's width
     * @param h the card's height
     * @return eight ticks, two per corner, just outside the rect
     */
    static List<Tick> around(int x, int y, int w, int h) {
        int left = x - THICK;
        int top = y - THICK;
        int right = x + w;
        int bottom = y + h;
        return List.of(
                // top left
                new Tick(left, top, LENGTH, THICK),
                new Tick(left, top, THICK, LENGTH),
                // top right
                new Tick(right + THICK - LENGTH, top, LENGTH, THICK),
                new Tick(right, top, THICK, LENGTH),
                // bottom left
                new Tick(left, bottom, LENGTH, THICK),
                new Tick(left, bottom + THICK - LENGTH, THICK, LENGTH),
                // bottom right
                new Tick(right + THICK - LENGTH, bottom, LENGTH, THICK),
                new Tick(right, bottom + THICK - LENGTH, THICK, LENGTH));
    }
}
