package com.tomer.scoundrel.screens;

/**
 * Drinking a potion: the card collapses into its bottle, the bottle hops to the
 * health bar, tips, and pours while the bar fills and three drops fall.
 *
 * <p>The phases must not overlap wrongly. If the bar started filling while the
 * bottle was still in the air, the drink would read as two unrelated things
 * happening at once rather than one action with a cause — so nothing reaches
 * the bar until the bottle has arrived and turned.
 *
 * <p>The bottle <b>rotates</b>, in a few discrete steps held a frame each. That
 * is safe here where it would not be in a browser: the texture is nearest
 * filtered, so a rotated draw point-samples one texel per pixel and cannot
 * blend two ramp steps into a colour that is not in the palette. The edges
 * step rather than smooth, which is the correct look.
 */
final class PotionDrink {

    private static final float FRAME = 1f / Frames.EFFECT_FPS;

    /** The card folding down into the bottle it contained. */
    static final int COLLAPSE_FRAMES = 2;
    /** The bottle's hops to the bar. */
    private static final int FLIGHT_FRAMES = 2;
    /**
     * Turning over, one step a frame. A single step: nothing in this art tweens,
     * so the bottle holds upright and then holds poured, and one held angle
     * reads exactly as deliberate as two while costing a frame less.
     */
    static final int TIP_STEPS = 1;
    private static final int TIP_FRAMES = TIP_STEPS;
    /** How far the bottle ends up turned, in degrees. */
    private static final float POURED_DEGREES = -62f;
    /**
     * And pouring. Three frames is enough to read as a pour; any longer and the
     * bottle sits tipped with nothing left to do. The bar's own fill runs on its
     * own clock and finishes in its own time either way.
     */
    private static final int POUR_FRAMES = 3;

    /** When the bottle is tipped far enough for anything to come out. */
    static final float POUR_START = (COLLAPSE_FRAMES + FLIGHT_FRAMES + TIP_FRAMES) * FRAME;

    /** ~667ms, quantised onto the effect grid. */
    static final float TOTAL =
            (COLLAPSE_FRAMES + FLIGHT_FRAMES + TIP_FRAMES + POUR_FRAMES) * FRAME;

    private static final int DROPS = 3;

    private PotionDrink() {
    }

    private static int frameOf(float elapsed) {
        return Frames.at(elapsed, Frames.EFFECT_FPS);
    }

    /**
     * Whether the card is still folding into its bottle.
     *
     * @param elapsed seconds on the drink's clock
     * @return true for the first {@link #COLLAPSE_FRAMES} frames
     */
    static boolean collapsing(float elapsed) {
        return elapsed >= 0f && frameOf(elapsed) < COLLAPSE_FRAMES;
    }

    /**
     * Whether the bottle is on its way to the bar.
     *
     * @param elapsed seconds on the drink's clock
     * @return true for the two hop frames after the collapse
     */
    static boolean flying(float elapsed) {
        int frame = frameOf(elapsed);
        return frame >= COLLAPSE_FRAMES && frame < COLLAPSE_FRAMES + FLIGHT_FRAMES;
    }

    /**
     * How far through its hops the bottle is, 0 to 1.
     *
     * @param elapsed seconds on the drink's clock
     * @return 0 at the card, 0.5 after one hop, 1 at the bar
     */
    static float flightProgress(float elapsed) {
        int frame = frameOf(elapsed) - COLLAPSE_FRAMES;
        if (frame < 0) {
            return 0f;
        }
        return Math.min(1f, frame / (float) FLIGHT_FRAMES);
    }

    /**
     * The card's size as it folds away, as a percentage.
     *
     * @param elapsed seconds on the drink's clock
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
     * Which turn step the bottle is on: upright until it has arrived, then one
     * step a frame. Discrete, so it holds each angle rather than sweeping
     * through them — nothing in this art tweens.
     *
     * @param elapsed seconds on the drink's clock
     * @return 0 (upright) to {@link #TIP_STEPS} (poured)
     */
    static int tiltStage(float elapsed) {
        int frame = frameOf(elapsed) - (COLLAPSE_FRAMES + FLIGHT_FRAMES);
        if (frame < 0) {
            return 0;
        }
        return Math.min(TIP_STEPS, frame + 1);
    }

    /**
     * The bottle's angle in degrees, one of a handful of held values.
     *
     * @param elapsed seconds on the drink's clock
     * @return 0 upright, -62 poured
     */
    static float tiltDegrees(float elapsed) {
        return POURED_DEGREES * tiltStage(elapsed) / TIP_STEPS;
    }

    /**
     * Whether the bottle is pouring — the bar fills from the same moment.
     *
     * @param elapsed seconds on the drink's clock
     * @return true from {@link #POUR_START} until the effect ends
     */
    static boolean pouring(float elapsed) {
        return elapsed >= POUR_START && elapsed < TOTAL;
    }

    /**
     * How many of the three drops have left the bottle.
     *
     * @param elapsed seconds on the drink's clock
     * @return 0 to 3
     */
    static int dropsFallen(float elapsed) {
        if (elapsed < POUR_START) {
            return 0;
        }
        int frame = frameOf(elapsed) - frameOf(POUR_START);
        // Spread across the pour rather than in the first instant.
        return Math.min(DROPS, frame / Math.max(1, POUR_FRAMES / DROPS) + 1);
    }

    /**
     * Whether the effect is over.
     *
     * @param elapsed seconds on the drink's clock
     * @return true from {@link #TOTAL} on
     */
    static boolean finished(float elapsed) {
        return elapsed >= TOTAL;
    }
}
