package com.tomer.scoundrel.screens;

/**
 * Where the tutorial's callout goes, and where its notch points.
 *
 * <p>Design space, y measured downward. The callout prefers to sit above the
 * card it is talking about and drops below when there is no room; the notch
 * always points back at the card, so the two have to agree. A callout that moved
 * below its target while its notch kept pointing down is the bug this exists to
 * make impossible, and it is invisible in a still frame.
 */
final class CalloutPlacement {

    /** Clearance from the stage edge, and from the panel's own edge for the notch. */
    static final int MARGIN = 12;
    /** The notch's width, in design pixels. */
    static final int NOTCH_W = 20;
    /** The notch's height, in design pixels. */
    static final int NOTCH_H = 14;

    /**
     * The NEXT button's rectangle inside a callout. A record rather than an
     * {@code int[4]}: four numbers in an array is four chances to read w where
     * y was meant.
     *
     * @param x the plate's left edge, in design pixels
     * @param y the plate's top edge, in design pixels measured downward
     * @param w the plate's width
     * @param h the plate's height
     */
    record Plate(int x, int y, int w, int h) {
    }

    /**
     * Where NEXT goes in a callout: right-aligned one pad in from the edge, and
     * <b>below</b> the last line of narration rather than over it.
     *
     * @param calloutX   the callout's left edge, in design pixels
     * @param calloutY   the callout's top edge, in design pixels measured downward
     * @param calloutH   the callout's height
     * @param labelWidth the measured label, without its padding
     * @return the plate's rectangle
     */
    static Plate nextPlate(int calloutX, int calloutY, int calloutH, int labelWidth) {
        int w = labelWidth + 2 * ScreenArt.END_BUTTON_PAD_X;
        return new Plate(
                calloutX + ScreenArt.CALLOUT_W - ScreenArt.CALLOUT_PAD_X - w,
                calloutY + calloutH - ScreenArt.CALLOUT_BOTTOM_PAD - ScreenArt.SKIP_H,
                w, ScreenArt.SKIP_H);
    }

    /**
     * Where a callout sits, and its notch.
     *
     * @param x        the callout's left edge, in design pixels
     * @param y        the callout's top edge, in design pixels measured downward
     * @param below    which way the notch points: down at the card when the callout
     *                 is above it, up at it when below
     * @param notchX   the notch's left edge, or -1 when there is no notch
     */
    record Placement(int x, int y, boolean below, int notchX) {
        /**
         * Whether to draw a notch at all.
         *
         * @return false for an explanation beat, which points at nothing
         */
        boolean hasNotch() {
            return notchX >= 0;
        }
    }

    private CalloutPlacement() {
    }

    /**
     * Under the room row and centred across the stage, with no notch — an
     * explanation beat points at nothing in particular.
     *
     * <p>Two placings were rejected. Dead-centre covers the room, and a player
     * being told how cards work cannot see the cards while being told. Above the
     * row is where a <em>targeted</em> callout goes, but an explanation beat runs
     * to five lines and that pushes it into the HUD; the space under the room is
     * empty and deep enough for the tallest of them.
     *
     * @param rowY     the room row's top edge, in design pixels measured downward
     * @param rowH     the room row's height
     * @param calloutW the callout's width
     * @param calloutH the callout's height
     * @param gap      the space to leave under the row
     * @param worldW   the stage's width, 1280
     * @param worldH   the stage's height, 720
     * @return a notchless placement, kept {@link #MARGIN} inside the stage
     */
    static Placement belowRow(int rowY, int rowH, int calloutW, int calloutH,
                              int gap, int worldW, int worldH) {
        int y = Math.min(rowY + rowH + gap, worldH - calloutH - MARGIN);
        return new Placement((worldW - calloutW) / 2, Math.max(MARGIN, y), false, -1);
    }

    /**
     * Above the target if there is room, below it if not, centred on it but kept
     * {@link #MARGIN} inside the stage — with the notch over the target and never
     * off the panel's edge.
     *
     * @param targetX  the target's left edge, in design pixels
     * @param targetY  the target's top edge, in design pixels measured downward
     * @param targetW  the target's width
     * @param targetH  the target's height
     * @param calloutW the callout's width
     * @param calloutH the callout's height
     * @param gap      the space to leave between callout and target
     * @param worldW   the stage's width, 1280
     * @return the placement, notch included
     */
    static Placement place(int targetX, int targetY, int targetW, int targetH,
                           int calloutW, int calloutH, int gap, int worldW) {
        int above = targetY - gap - calloutH;
        boolean below = above < MARGIN;
        int y = below ? targetY + targetH + gap : above;

        int centre = targetX + targetW / 2;
        int x = clamp(centre - calloutW / 2, MARGIN, worldW - calloutW - MARGIN);
        // The notch tracks the card, not the panel — but once the panel has been
        // clamped away from the card the notch has to stay on it, or it detaches
        // and points at nothing.
        int notchX = clamp(centre - NOTCH_W / 2,
                x + MARGIN, x + calloutW - NOTCH_W - MARGIN);
        return new Placement(x, y, below, notchX);
    }

    private static int clamp(int value, int low, int high) {
        return Math.max(low, Math.min(high, value));
    }
}
