package com.tomer.scoundrel.screens;

/**
 * The weapon kill's timeline: the creature holds its struck frame — brightened
 * up its ramp with the cream outline over it — and then the blade lands: the
 * card is picked up 10px, a bone slash bar crosses top-right to bottom-left,
 * and the two halves part and keep rising as they fade.
 *
 * <p>The struck frame is shared with the bare-handed exchange on purpose, so a
 * creature reads the same however it is being killed and only the outcome
 * differs. Holding the full struck frame, rather than an outline alone over an
 * untouched sprite, reads as one blow rather than two unrelated effects.
 *
 * <p>The ordering is the effect. The flash has to finish before anything is
 * drawn over the card, and the trap is subtle: an element that exists early and
 * is merely transparent still occludes the creature. So this class answers
 * <em>whether a thing may be drawn at all</em> rather than handing out an alpha,
 * and callers draw nothing while it says no.
 *
 * <p>Everything steps on a 12fps grid and every offset is a whole pixel. There
 * is deliberately no rotation anywhere in this API — the halves slide apart
 * instead of turning, because a turned pixel is a blurred pixel.
 */
final class WeaponKill {

    /** One effect frame. Effects run at 12fps; the grid itself is {@link Frames}. */
    static final float FRAME = 1f / Frames.EFFECT_FPS;

    /**
     * The flash holds this long before the blade lands: one frame. A flash is
     * what a blade landing actually is; any longer and the creature stands lit
     * while nothing happens.
     */
    static final float RIM_TIME = FRAME;

    /**
     * The bar crosses as the halves come apart, not a frame before them. The
     * ordering that matters is that the card is lifted <em>whole</em> for one
     * frame first — nothing may cover it until the flash has finished.
     * Separating the slash from the parting would only add a frame in which a
     * blade hangs over an uncut card.
     */
    static final float SLASH_START = RIM_TIME + FRAME;
    private static final float SLASH_TIME = 2 * FRAME;
    private static final float HALVES_START = RIM_TIME + FRAME;
    private static final float HALVES_STEPS = 2;

    /** Lift, then two frames of slash and parting together: 3 after the flash. */
    static final float TOTAL = RIM_TIME + 3 * FRAME;

    private static final int LIFT_PX = 10;
    // Where each half has drifted to by the end.
    private static final int UPPER_END_X = -24;
    private static final int UPPER_END_Y = -34;
    private static final int LOWER_END_X = 24;
    private static final int LOWER_END_Y = -18;
    private static final int SLASH_TRAVEL = 28;

    private WeaponKill() {
    }

    /**
     * Floors a time onto the effect grid, so every segment holds on a frame.
     *
     * @param elapsed seconds on the kill's clock
     * @return the start of the frame it falls in, in seconds
     */
    static float quantise(float elapsed) {
        return Frames.snap(elapsed, Frames.EFFECT_FPS);
    }

    /**
     * The creature is holding its struck frame, still whole.
     *
     * @param elapsed seconds on the kill's clock
     * @return true for the flash's one frame
     */
    static boolean rimShowing(float elapsed) {
        return elapsed < RIM_TIME;
    }

    /**
     * Whether the blade has landed. Nothing may cover the card before this.
     *
     * @param elapsed seconds on the kill's clock
     * @return true from the end of the flash on
     */
    static boolean cardCut(float elapsed) {
        return elapsed >= RIM_TIME;
    }

    /**
     * The blow picks the card up on its first frame, and it stays up.
     *
     * @param elapsed seconds on the kill's clock
     * @return how far the card is lifted, in design pixels: 0 or 10
     */
    static int cardLift(float elapsed) {
        return cardCut(elapsed) ? LIFT_PX : 0;
    }

    /**
     * Whether the bone bar is crossing the card.
     *
     * @param elapsed seconds on the kill's clock
     * @return true for the slash's two frames, from {@link #SLASH_START}
     */
    static boolean slashShowing(float elapsed) {
        return elapsed >= SLASH_START && elapsed < SLASH_START + SLASH_TIME;
    }

    /**
     * The bar's travel along its own diagonal, in whole pixels.
     *
     * @param elapsed seconds on the kill's clock
     * @return -28 on the slash's first frame, 0 on its second, 0 when it is not showing
     */
    static int slashOffset(float elapsed) {
        if (!slashShowing(elapsed)) {
            return 0;
        }
        int step = (int) ((quantise(elapsed) - SLASH_START) / FRAME);
        return Math.round(SLASH_TRAVEL * (step / (float) 2) * 2 - SLASH_TRAVEL);
    }

    /**
     * Whether the card is drawn as two cleaved halves rather than whole.
     *
     * @param elapsed seconds on the kill's clock
     * @return true from the parting until the effect ends
     */
    static boolean halvesShowing(float elapsed) {
        return elapsed >= HALVES_START && elapsed < TOTAL;
    }

    /**
     * The upper half's sideways drift.
     *
     * @param elapsed seconds on the kill's clock
     * @return the offset in design pixels, 0 to -24 (leftward)
     */
    static int upperDx(float elapsed) {
        return Math.round(UPPER_END_X * progress(elapsed));
    }

    /**
     * The upper half's vertical drift, lift included.
     *
     * @param elapsed seconds on the kill's clock
     * @return the offset in design pixels, y measured downward, so negative is up
     */
    static int upperDy(float elapsed) {
        return Math.round(UPPER_END_Y * progress(elapsed)) - cardLift(elapsed);
    }

    /**
     * The lower half's sideways drift.
     *
     * @param elapsed seconds on the kill's clock
     * @return the offset in design pixels, 0 to 24 (rightward)
     */
    static int lowerDx(float elapsed) {
        return Math.round(LOWER_END_X * progress(elapsed));
    }

    /**
     * The lower half's vertical drift, lift included.
     *
     * @param elapsed seconds on the kill's clock
     * @return the offset in design pixels, y measured downward, so negative is up
     */
    static int lowerDy(float elapsed) {
        return Math.round(LOWER_END_Y * progress(elapsed)) - cardLift(elapsed);
    }

    /**
     * Full at the first parting frame, gone by the end.
     *
     * @param elapsed seconds on the kill's clock
     * @return the halves' alpha, stepping from 1 down to 0
     */
    static float halfAlpha(float elapsed) {
        return 1f - progress(elapsed);
    }

    /**
     * Whether the effect is over.
     *
     * @param elapsed seconds on the kill's clock
     * @return true from {@link #TOTAL} on
     */
    static boolean finished(float elapsed) {
        return elapsed >= TOTAL;
    }

    /**
     * How far through the parting we are, in discrete steps. The last one lands
     * on 1 so the halves finish fully separated and fully faded rather than
     * snapping out while still visible.
     */
    private static float progress(float elapsed) {
        if (elapsed < HALVES_START) {
            return 0f;
        }
        int step = (int) ((quantise(elapsed) - HALVES_START) / FRAME) + 1;
        return Math.min(1f, step / HALVES_STEPS);
    }
}
