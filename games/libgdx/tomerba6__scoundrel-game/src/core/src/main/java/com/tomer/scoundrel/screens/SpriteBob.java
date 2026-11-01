package com.tomer.scoundrel.screens;

/**
 * The idle bob: every sprite on the board rising and settling together, as one
 * breath.
 *
 * <p>It moves the <b>sprite alone</b> — the card's frame, header and value stay
 * exactly where they are, so the art breathes inside its window rather than the
 * whole card wobbling. And it is a <b>position</b>, where the creature idle is a
 * <b>frame</b>: the five-frame cycle plays on top of this for the hovered card
 * and the two never interact.
 *
 * <p><b>Synchronised by construction.</b> The offset is a function of the
 * board's clock and nothing else — no card, no slot, no per-card stagger to pass
 * in — so two sprites cannot drift apart however they were dealt. That is
 * deliberately the opposite of {@link IdleCycle}, which staggers each card so
 * four creatures do not animate in lockstep: one breath shared by the whole
 * board reads as the room being lit by one torch, where four independent bobs
 * read as four loose sprites. The stagger still governs the frame cycle, which
 * is what it was for, and only the hovered card runs that anyway.
 *
 * <p>Amplitude is bounded by the well: a 128 sprite in a 140 well has six pixels
 * of clearance, and ±2 spends a third of it. Every step is even because sprites
 * draw at ×2 — an odd offset would move the art by half a source pixel.
 */
final class SpriteBob {

    /**
     * Rest, up, rest, down. Negative is up: these are design-space offsets, and
     * design space counts down from the top of the screen.
     *
     * <p>Two frames at each end mean the board spends half the cycle still,
     * which is what makes it read as breathing rather than as a bounce.
     */
    private static final int[] STEP = {0, -2, -2, 0, 0, 2, 2, 0};

    /** How many steps one breath has: eight. */
    static final int STEPS = STEP.length;
    /** One whole breath: eight steps at the idle rate, a little over a second. */
    static final float PERIOD = STEPS / (float) Frames.IDLE_FPS;

    private SpriteBob() {
    }

    /**
     * How far the sprite is displaced from its resting place, in design-space
     * pixels, at {@code elapsed} seconds of board time. Negative is up.
     *
     * <p>Tolerates a negative time rather than throwing — a clock that has not
     * started, or one that has been rewound, should still draw something.
     *
     * @param elapsed seconds of board time, any value
     * @return the vertical offset: -2, 0 or 2 design pixels
     */
    static int offsetAt(float elapsed) {
        int step = Frames.at(elapsed, Frames.IDLE_FPS) % STEPS;
        return STEP[step < 0 ? step + STEPS : step];
    }
}
