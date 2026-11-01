package com.tomer.scoundrel.screens;

/**
 * Spilling a wasted potion: the second one taken in a room, which heals
 * nothing. The card collapses into the same bottle a drink does — drained of
 * colour by {@link SpentMask} — and it tips over and dribbles where the card
 * was.
 *
 * <p>It <b>goes nowhere</b>, and that is the whole effect. A wasted potion that
 * flew to the health bar and tipped over it with nothing to pour would read as
 * the heal being broken; spilling it on the table says the potion was wasted,
 * which is what actually happened.
 *
 * <p>Shorter than a drink, too. Nothing is gained by it, so it has no business
 * holding the board as long as the one that heals you.
 */
final class PotionSpill {

    private static final float FRAME = 1f / Frames.EFFECT_FPS;

    /** The card folding down into the bottle — the same beat a drink opens on. */
    static final int COLLAPSE_FRAMES = PotionDrink.COLLAPSE_FRAMES;
    /** Going over, in one held step. Nothing in this art tweens. */
    static final int TIP_STEPS = 1;
    /** Further than a drink tips: this one is being tipped out, not poured. */
    private static final float POURED_DEGREES = -48f;
    private static final int SPILL_FRAMES = 3;
    private static final int DROPS = 2;
    /** How far the bottle settles as it goes over, on the shared 4px grid. */
    private static final int SLUMP_PX = 4;

    /** When it is over far enough for anything to come out. */
    static final float SPILL_START = (COLLAPSE_FRAMES + TIP_STEPS) * FRAME;

    /** ~500ms — six frames, two shorter than the drink. */
    static final float TOTAL = (COLLAPSE_FRAMES + TIP_STEPS + SPILL_FRAMES) * FRAME;

    private PotionSpill() {
    }

    private static int frameOf(float elapsed) {
        return Frames.at(elapsed, Frames.EFFECT_FPS);
    }

    /**
     * How many drops dribble out in all.
     *
     * @return the drop count, two
     */
    static int drops() {
        return DROPS;
    }

    /**
     * The card's size as it folds away, as a percentage.
     *
     * @param elapsed seconds on the spill's clock
     * @return 100 before the fold, 0 once the card is gone, whole steps between
     */
    static int cardScale(float elapsed) {
        int frame = frameOf(elapsed);
        if (frame <= 0) {
            return 100;
        }
        if (frame >= COLLAPSE_FRAMES) {
            return 0;
        }
        return Math.round(100f * (COLLAPSE_FRAMES - frame) / COLLAPSE_FRAMES);
    }

    /**
     * Upright while the card is still there, then over and held.
     *
     * @param elapsed seconds on the spill's clock
     * @return 0 (upright) to {@link #TIP_STEPS} (over)
     */
    static int tiltStage(float elapsed) {
        int frame = frameOf(elapsed) - COLLAPSE_FRAMES;
        if (frame < 0) {
            return 0;
        }
        return Math.min(TIP_STEPS, frame + 1);
    }

    /**
     * The bottle's angle, held at each stage.
     *
     * @param elapsed seconds on the spill's clock
     * @return 0 upright, -48 once over
     */
    static float tiltDegrees(float elapsed) {
        return POURED_DEGREES * tiltStage(elapsed) / TIP_STEPS;
    }

    /**
     * It drops onto its side as it goes over, and stays there.
     *
     * @param elapsed seconds on the spill's clock
     * @return how far down the bottle has settled, in design pixels: 0 or 4
     */
    static int slump(float elapsed) {
        return tiltStage(elapsed) > 0 ? SLUMP_PX : 0;
    }

    /**
     * Whether anything is coming out.
     *
     * @param elapsed seconds on the spill's clock
     * @return true from {@link #SPILL_START} until the effect ends
     */
    static boolean spilling(float elapsed) {
        return elapsed >= SPILL_START && elapsed < TOTAL;
    }

    /**
     * How many drops have dribbled out — one a frame, so they arrive separately.
     *
     * @param elapsed seconds on the spill's clock
     * @return 0 to {@link #drops()}
     */
    static int dropsFallen(float elapsed) {
        if (elapsed < SPILL_START) {
            return 0;
        }
        return Math.min(DROPS, frameOf(elapsed) - frameOf(SPILL_START) + 1);
    }

    /**
     * Whether the effect is over.
     *
     * @param elapsed seconds on the spill's clock
     * @return true from {@link #TOTAL} on
     */
    static boolean finished(float elapsed) {
        return elapsed >= TOTAL;
    }
}
