package com.tomer.scoundrel.screens;

import java.util.Random;

/**
 * The idle animation's clock: five frames at 6 fps, looping, each card started
 * at its own offset so four cards in a room do not breathe in lockstep.
 *
 * <p>Time is <b>floored</b> to a frame rather than interpolated. Every segment
 * of this art holds on a frame — nothing tweens and nothing rotates — so the
 * quantising here is the rule, not an optimisation, and this is the single
 * place idle time is floored.
 */
final class IdleCycle {

    /** Six frames a second, 167ms each. Effects run at 12; idles do not. */
    static final int FPS = Frames.IDLE_FPS;
    /** One idle frame's hold, in seconds. */
    static final float FRAME_TIME = 1f / FPS;
    /** One full five-frame loop, 833ms — also the range of the start stagger. */
    static final float CYCLE_TIME = 5f / FPS;

    private IdleCycle() {
    }

    /**
     * Which frame is showing at {@code elapsed} seconds for a card started at
     * {@code offset}. Wraps, and tolerates a negative elapsed time rather than
     * throwing, since a paused or rewound clock should still draw something.
     *
     * @param elapsed    seconds of board time, any value
     * @param offset     the card's start offset, in seconds, from {@link #randomOffset}
     * @param frameCount frames in the cycle, 1 or more (five for every creature)
     * @return the frame to draw, from 0 to {@code frameCount - 1}
     */
    static int frameIndex(float elapsed, float offset, int frameCount) {
        // Frames does the flooring, and carries the note on why a boundary has
        // to be nudged before it is floored — this cycle wrapping a frame late
        // is the case that found it.
        int index = Frames.at(elapsed + offset, FPS) % frameCount;
        return index < 0 ? index + frameCount : index;
    }

    /**
     * As {@link #frameIndex(float, float, int)}, but holds on frame 1 when the
     * card is not the player's focus. Four cards breathing at once reads
     * as busy; frame 1 is the base sprite pixel-for-pixel, so a held card is
     * indistinguishable from a static one and nothing jumps when focus moves.
     *
     * @param elapsed    seconds of board time, any value
     * @param offset     the card's start offset, in seconds
     * @param frameCount frames in the cycle, 1 or more
     * @param animating  whether this card is the player's focus
     * @return the frame to draw; 0 (frame 1) when not animating
     */
    static int frameIndex(float elapsed, float offset, int frameCount, boolean animating) {
        return animating ? frameIndex(elapsed, offset, frameCount) : 0;
    }

    /**
     * A start offset spanning exactly one cycle. Assigned once when a card is
     * dealt and kept — recomputing it per frame would make the card stutter
     * instead of breathe.
     *
     * @param random the board's generator
     * @return an offset in seconds, from 0 up to (not including) {@link #CYCLE_TIME}
     */
    static float randomOffset(Random random) {
        return random.nextFloat() * CYCLE_TIME;
    }
}
