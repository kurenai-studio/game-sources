package com.tomer.scoundrel.screens;

/**
 * The bare-handed exchange: two hits landing in quick succession, the creature
 * holding its struck frame throughout, the card shaking on a 4px grid and a
 * short bone flash under each blow.
 *
 * <p>The creature stays lit for the whole exchange rather than flashing once
 * per hit, so the two blows read as a single event. The shake is on a 4px grid
 * for the same reason everything else is on whole pixels — a 1px jitter at this
 * scale reads as noise rather than force.
 */
final class Barehanded {

    /** One effect frame. Effects run at 12fps; the grid itself is {@link Frames}. */
    static final float FRAME = 1f / Frames.EFFECT_FPS;

    /**
     * ~333ms. Any longer reads as a pause rather than a blow — the outcome is
     * already decided, so every frame after it registers is a frame spent
     * waiting. Four frames is the floor: two blows a frame apart, each star
     * growing through its three held sizes, and the last one gone exactly as the
     * effect ends.
     */
    static final float TOTAL = 4 * FRAME;

    /** The blows land on frames 0 and 1 — as fast as this grid can strike twice. */
    private static final int HIT_LENGTH = 2;
    /** The frame each blow lands on, in order. Shared: never write to it. */
    static final int[] HIT_FRAMES = {0, 1};

    /** The star box before scaling, and its three discrete sizes. */
    static final int STAR_BOX = 80;
    private static final float[] STAR_SCALE = {0.5f, 1.2f, 1.9f};
    /** Offsets from the struck card's centre, one per blow. */
    private static final int[][] STAR_OFFSET = {{-26, -18}, {22, 24}};

    /** Whole-pixel shake, one entry per frame, settling back to rest. */
    private static final int[] SHAKE_X = {-8, 8, -4, 0};
    private static final int[] SHAKE_Y = {4, -4, 4, 0};

    private Barehanded() {
    }

    /**
     * Floors a time onto the effect grid, so every segment holds on a frame.
     *
     * @param elapsed seconds on the fight's clock
     * @return the start of the frame it falls in, in seconds
     */
    static float quantise(float elapsed) {
        return Frames.snap(elapsed, Frames.EFFECT_FPS);
    }

    private static int frameOf(float elapsed) {
        return (int) (quantise(elapsed) / FRAME);
    }

    /**
     * The creature is lit for the whole exchange, not just on impact.
     *
     * @param elapsed seconds on the fight's clock
     * @return true from the first blow until the effect ends
     */
    static boolean hurtShowing(float elapsed) {
        return elapsed >= 0f && elapsed < TOTAL;
    }

    /**
     * True on the frame each blow lands, for the impact star.
     *
     * @param elapsed seconds on the fight's clock
     * @return whether a blow lands on this frame
     */
    static boolean hitLanding(float elapsed) {
        int frame = frameOf(elapsed);
        for (int start : HIT_FRAMES) {
            if (frame == start) {
                return true;
            }
        }
        return false;
    }

    /**
     * Whether the board is washed gold right now.
     *
     * @param elapsed seconds on the fight's clock
     * @return true while {@link #flashAlpha} is above zero
     */
    static boolean flashShowing(float elapsed) {
        return flashAlpha(elapsed) > 0f;
    }

    /**
     * The card's sideways shake.
     *
     * @param elapsed seconds on the fight's clock
     * @return the offset in whole design pixels: -8, 8, -4, then 0
     */
    static int shakeX(float elapsed) {
        return shake(SHAKE_X, elapsed);
    }

    /**
     * The card's vertical shake, y measured downward.
     *
     * @param elapsed seconds on the fight's clock
     * @return the offset in whole design pixels: 4, -4, 4, then 0
     */
    static int shakeY(float elapsed) {
        return shake(SHAKE_Y, elapsed);
    }

    private static int shake(int[] table, float elapsed) {
        int frame = frameOf(elapsed);
        return frame >= 0 && frame < table.length ? table[frame] : 0;
    }

    /**
     * The star's box for blow {@code hit} right now, or 0 when it is not up.
     * Three discrete sizes — never a tween — rounded to whole pixels.
     *
     * @param hit     which blow, from 0 to {@code hits() - 1}
     * @param elapsed seconds on the fight's clock
     * @return the star's box in design pixels: 40, 96 or 152, or 0
     */
    static int starSize(int hit, float elapsed) {
        int step = starStep(hit, elapsed);
        return step < 0 ? 0 : Math.round(STAR_BOX * STAR_SCALE[step]);
    }

    /**
     * Full on the frame the blow lands, gone by the third.
     *
     * @param hit     which blow, from 0 to {@code hits() - 1}
     * @param elapsed seconds on the fight's clock
     * @return 1, then two thirds, then one third; 0 when the star is not up
     */
    static float starAlpha(int hit, float elapsed) {
        int step = starStep(hit, elapsed);
        return step < 0 ? 0f : 1f - step / (float) STAR_SCALE.length;
    }

    /**
     * Where a blow's star sits sideways, from the struck card's centre.
     *
     * @param hit which blow, from 0 to {@code hits() - 1}
     * @return the offset in design pixels
     */
    static int starOffsetX(int hit) {
        return STAR_OFFSET[hit][0];
    }

    /**
     * Where a blow's star sits vertically, from the struck card's centre.
     *
     * @param hit which blow, from 0 to {@code hits() - 1}
     * @return the offset in design pixels
     */
    static int starOffsetY(int hit) {
        return STAR_OFFSET[hit][1];
    }

    /**
     * How many blows there are, so callers do not hardcode two.
     *
     * @return the number of blows
     */
    static int hits() {
        return HIT_FRAMES.length;
    }

    /**
     * Which of the three growth steps a star is on, or -1 when it is not up.
     * One step per frame: three steps over two frames would change a value
     * mid-frame, and nothing here is allowed to slide.
     */
    private static int starStep(int hit, float elapsed) {
        int frame = frameOf(elapsed);
        int offset = frame - HIT_FRAMES[hit];
        return offset >= 0 && offset < STAR_SCALE.length ? offset : -1;
    }

    /**
     * The gold wash over the board: 80% alpha decaying over two frames, keyed
     * to the first blow alone. The second lands inside it, so one wash covers
     * the whole exchange — which is the point. A second flash would read as a
     * strobe rather than as a hit.
     *
     * @param elapsed seconds on the fight's clock
     * @return 0.8 on the first blow's frame, 0.4 on the next, else 0
     */
    static float flashAlpha(float elapsed) {
        int offset = frameOf(elapsed) - HIT_FRAMES[0];
        if (offset < 0 || offset >= HIT_LENGTH) {
            return 0f;
        }
        return 0.8f * (1f - offset / (float) HIT_LENGTH);
    }

    /**
     * Whether the effect is over.
     *
     * @param elapsed seconds on the fight's clock
     * @return true from {@link #TOTAL} on
     */
    static boolean finished(float elapsed) {
        return elapsed >= TOTAL;
    }
}
