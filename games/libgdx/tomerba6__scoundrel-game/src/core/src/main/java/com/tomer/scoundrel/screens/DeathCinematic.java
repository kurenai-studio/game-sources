package com.tomer.scoundrel.screens;

/**
 * Dying: the blow flares, the board shakes and is then <em>left standing</em>,
 * the torch gutters out over it, the depth ticker outlives everything else, and
 * only once that has gone does YOU DIED grow in.
 *
 * <p>The screen dies by <b>pattern, never alpha</b>. An alpha fade dims every
 * pixel toward black together, which reads as a dialog covering the game; an
 * ordered dither turns pixels off in a fixed order, so the board stays legible
 * through it and thins out until it is gone. That is the difference between the
 * game being obscured and the game failing.
 *
 * <p>The pacing is the point, and this is deliberately the slowest thing in the
 * game. Wiping the board in half a second, with the title up before the loss has
 * registered, reads as a page turn; so the board is held dead and lit for the
 * best part of a second — long enough to read the empty bar and the number under
 * zero — and the light is taken away before the board is. The whole thing can be
 * clicked through at any point.
 */
final class DeathCinematic {

    private static final float FRAME = 1f / Frames.EFFECT_FPS;

    /** The blow lands and flares over whatever killed you. */
    private static final int FLARE_FRAMES = 2;
    /** Then the board takes it. */
    private static final int SHAKE_FRAMES = 3;
    /**
     * Then nothing at all. This is the beat the whole death is built around: the
     * board stands lit and unmoving with an empty bar on it, and you are given
     * time to understand that it is over before anything is taken away.
     */
    private static final int SETTLE_FRAMES = 10;
    /** The torch dies and the board thins out under it, together. */
    private static final int GUTTER_FRAMES = 18;
    /** The ticker alone in the dark, saying how close you got. */
    private static final int TICKER_HOLD_FRAMES = 6;
    /** And a beat of nothing, so the title is not part of that movement. */
    private static final int BLACK_FRAMES = 2;
    /**
     * The title's size at each step, as a whole multiple of the face it is drawn
     * from — see {@link #titleZoom}. Fifteen of them, and it is drawn from the
     * <em>smallest</em> face in the game for exactly that reason: whole
     * multiples are the only clean sizes there are, so the smaller the face,
     * the more of them fit inside the same final size.
     *
     * <p>That granularity is the whole point. Drawn from a large face the first
     * jump would be 3× to 4× — a third larger in one go — with only four sizes in
     * the run. Here the first jump is a fifth and the last an eighteenth.
     */
    private static final int[] TITLE_ZOOM = {
        5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
    };
    /**
     * One frame each. At 12fps a step every frame is as smooth as anything in
     * this game can be, and any hold longer than that is a visible stutter,
     * worst on the first steps, where the jumps are largest.
     * The death is slow because its lead-in is long, not because the title
     * pauses on the way in.
     */
    private static final int TITLE_STEP_FRAMES = 1;
    /** It then sits at full size, which is where the slowness belongs. */
    private static final int HOLD_FRAMES = 12;

    /** A 4×4 ordered pattern has sixteen thresholds to cross. */
    static final int DITHER_LEVELS = 16;

    /** When the dark starts to take the board and the torch starts to gutter, in seconds. */
    static final float DITHER_START = (FLARE_FRAMES + SHAKE_FRAMES + SETTLE_FRAMES) * FRAME;
    /** When the dark has the whole board and the torch is out, in seconds. */
    static final float DITHER_END = DITHER_START + GUTTER_FRAMES * FRAME;
    /** When the last lit thing on the board goes out. */
    private static final float TICKER_OUT = DITHER_END + TICKER_HOLD_FRAMES * FRAME;
    /** When YOU DIED begins to grow in, in seconds; the death cue plays here too. */
    static final float TITLE_START = TICKER_OUT + BLACK_FRAMES * FRAME;
    /** ~5500ms, quantised onto the effect grid. Skippable throughout. */
    static final float TOTAL = TITLE_START + (growthFrames() + HOLD_FRAMES) * FRAME;

    private static int growthFrames() {
        return TITLE_ZOOM.length * TITLE_STEP_FRAMES;
    }

    /** Whole-pixel shake, one entry per frame of the shake phase. */
    private static final int[] SHAKE = {-8, 8, -4};

    /**
     * How alive the fire is, one entry per frame of the gutter. A flame going
     * out does not fade: it sinks, flares back, sinks further. A smooth ramp
     * reads as a dimmer switch being turned, which is the wrong thing entirely —
     * so the trend is downward but every other step recovers.
     */
    private static final float[] GUTTER = {
        1.00f, 0.88f, 0.96f, 0.74f, 0.83f, 0.60f,
        0.69f, 0.46f, 0.55f, 0.33f, 0.41f, 0.22f,
        0.29f, 0.14f, 0.19f, 0.07f, 0.11f, 0.03f,
    };

    private DeathCinematic() {
    }

    private static int frameOf(float elapsed) {
        return Frames.at(elapsed, Frames.EFFECT_FPS);
    }

    /**
     * The red flare over the killer, before anything else happens.
     *
     * @param elapsed seconds on the death's clock
     * @return true for the flare's opening frames
     */
    static boolean flaring(float elapsed) {
        int frame = frameOf(elapsed);
        return frame >= 0 && frame < FLARE_FRAMES;
    }

    /**
     * How far through the flare, so it can fade as it spreads.
     *
     * @param elapsed seconds on the death's clock
     * @return 1 on the first frame, stepping down; 0 outside the flare
     */
    static float flareStrength(float elapsed) {
        if (!flaring(elapsed)) {
            return 0f;
        }
        return 1f - frameOf(elapsed) / (float) FLARE_FRAMES;
    }

    /**
     * The board's sideways shake, after the flare.
     *
     * @param elapsed seconds on the death's clock
     * @return the offset in whole design pixels: -8, 8, -4 over three frames, else 0
     */
    static int shakeX(float elapsed) {
        int frame = frameOf(elapsed) - FLARE_FRAMES;
        if (frame < 0 || frame >= SHAKE.length) {
            return 0;
        }
        return SHAKE[frame];
    }

    /**
     * The torchlight: full while the board is still standing, guttering out
     * across the dither, and gone by the time the title arrives.
     *
     * @param elapsed seconds on the death's clock
     * @return 1 before the dither, a guttering 1-to-0 through it, 0 after
     */
    static float torchLight(float elapsed) {
        int frame = frameOf(elapsed) - frameOf(DITHER_START);
        if (frame < 0) {
            return 1f;
        }
        if (frame >= GUTTER.length) {
            return 0f;
        }
        return GUTTER[frame];
    }

    /**
     * How many of the pattern's sixteen thresholds have gone dark. Climbs to
     * full and stays there — the screen never lightens again.
     *
     * @param elapsed seconds on the death's clock
     * @return 0 to {@link #DITHER_LEVELS}
     */
    static int ditherLevel(float elapsed) {
        int frame = frameOf(elapsed) - frameOf(DITHER_START);
        if (frame < 0) {
            return 0;
        }
        int level = Math.round(DITHER_LEVELS * (frame + 1) / (float) GUTTER_FRAMES);
        return Math.min(DITHER_LEVELS, level);
    }

    /**
     * Whether the depth ticker is still lit. It is drawn <em>over</em> the
     * dither rather than under it, so the dark takes the whole board and leaves
     * the one gauge that says how far you got — then takes that too, a beat
     * before the title, so the two do not read as one movement.
     *
     * @param elapsed seconds on the death's clock
     * @return true from the start until a beat after the dither completes
     */
    static boolean tickerShowing(float elapsed) {
        return elapsed >= 0f && elapsed < TICKER_OUT;
    }

    /**
     * Whether YOU DIED is on screen.
     *
     * @param elapsed seconds on the death's clock
     * @return true from {@link #TITLE_START} until the cinematic ends
     */
    static boolean titleShowing(float elapsed) {
        return elapsed >= TITLE_START && elapsed < TOTAL;
    }

    /**
     * How many times larger than its own face the title is drawn, right now.
     *
     * <p>Always a <b>whole multiple</b>. Silkscreen is a 1-bit face rendered at
     * 1:1 with nearest filtering, so a fractional scale resamples it: whole rows
     * of pixels vanish and identical stems land on one screen pixel or two
     * depending where each glyph falls. That is also why it is drawn from a
     * small face — the whole multiples are the only sizes available, and a small
     * face has ten of them inside the same final size where a large one had four.
     *
     * @param elapsed seconds on the death's clock
     * @return 0 before the title, then a whole multiple that grows and holds at its largest
     */
    static int titleZoom(float elapsed) {
        if (elapsed < TITLE_START) {
            return 0;
        }
        int frame = frameOf(elapsed) - frameOf(TITLE_START);
        int step = Math.max(0, frame / TITLE_STEP_FRAMES);
        return TITLE_ZOOM[Math.min(TITLE_ZOOM.length - 1, step)];
    }

    /**
     * Whether the cinematic is over and the end panel may come up.
     *
     * @param elapsed seconds on the death's clock
     * @return true from {@link #TOTAL} on
     */
    static boolean finished(float elapsed) {
        return elapsed >= TOTAL;
    }
}
