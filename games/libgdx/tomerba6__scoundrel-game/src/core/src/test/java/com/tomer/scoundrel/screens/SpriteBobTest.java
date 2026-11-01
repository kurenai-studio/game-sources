package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The idle bob: every sprite on the board rising and settling together, as one
 * breath. It is a position, not a frame — the five-frame creature idle plays on
 * top of it and the two never interact.
 */
class SpriteBobTest {

    /**
     * Synchronised by construction. The offset is a function of the board's own
     * clock and nothing else — there is no card, no slot and no per-card stagger
     * to pass in, so two cards cannot drift apart however they were dealt.
     */
    @Test
    void everyCardIsOnTheSameBreathBecauseThereIsNothingToTellThemApart() {
        for (float t = 0f; t < 4f; t += 0.037f) {
            assertEquals(SpriteBob.offsetAt(t), SpriteBob.offsetAt(t),
                    "the offset depends on something other than the clock");
            assertEquals(SpriteBob.offsetAt(t), SpriteBob.offsetAt(t + SpriteBob.PERIOD),
                    "the cycle does not close at " + t);
        }
    }

    /**
     * The sprite is 128 tall in a 140 well, so it has six pixels of clearance
     * above and below. The bob must never spend them — a sprite touching the
     * well's edge reads as broken framing, not as life.
     */
    @Test
    void theSpriteNeverLeavesItsWell() {
        int clearance = (CardArt.WELL_H - CardArt.SPRITE) / 2;
        assertEquals(6, clearance, "the well's geometry moved; re-check the amplitude");
        for (float t = 0f; t < 4f; t += 0.01f) {
            assertTrue(Math.abs(SpriteBob.offsetAt(t)) <= clearance - 2,
                    "the bob left less than 2px of clearance at " + t);
        }
    }

    /**
     * Sprites draw at ×2, so an odd offset would move the art by half a source
     * pixel — legal on the design grid but a shear in the art's own grid.
     */
    @Test
    void everyStepMovesAWholeSourcePixel() {
        for (float t = 0f; t < 4f; t += 0.01f) {
            assertEquals(0, SpriteBob.offsetAt(t) % 2,
                    "half a source pixel at " + t);
        }
    }

    /** Nothing in this art slides: the bob holds a position, then jumps. */
    @Test
    void theBobHoldsOnItsFrameAndNeverSlides() {
        float frame = 1f / Frames.IDLE_FPS;
        for (int step = 0; step < SpriteBob.STEPS; step++) {
            int at = SpriteBob.offsetAt(step * frame);
            for (float within = 0.001f; within < frame - 0.001f; within += 0.004f) {
                assertEquals(at, SpriteBob.offsetAt(step * frame + within),
                        "the sprite moved " + within + "s into step " + step);
            }
        }
    }

    /**
     * Rest, up, rest, down — a breath through the resting position rather than a
     * hop off it, and it passes through rest for two frames at each end so the
     * board spends most of its time still.
     */
    @Test
    void theCycleRisesAndSettlesThroughRest() {
        float frame = 1f / Frames.IDLE_FPS;
        int[] expected = {0, -2, -2, 0, 0, 2, 2, 0};
        assertEquals(expected.length, SpriteBob.STEPS);
        for (int i = 0; i < expected.length; i++) {
            assertEquals(expected[i], SpriteBob.offsetAt(i * frame), "step " + i);
        }
    }

    /** A whole cycle is a slow breath, not a twitch. */
    @Test
    void theBreathTakesOverASecond() {
        assertEquals(8 / 6f, SpriteBob.PERIOD, 1e-6f);
        assertTrue(SpriteBob.PERIOD > 1f, "a cycle under a second reads as a twitch");
    }

    /** A board that has just been dealt is at rest, not caught mid-rise. */
    @Test
    void theBoardStartsAtRest() {
        assertEquals(0, SpriteBob.offsetAt(0f));
    }

    /** A clock that has not started, or has been rewound, still draws something. */
    @Test
    void aRewoundClockStillAnswers() {
        for (float t = -3f; t < 0f; t += 0.03f) {
            int at = SpriteBob.offsetAt(t);
            assertTrue(Math.abs(at) <= 2, "out of range at " + t + ": " + at);
            assertEquals(0, at % 2, "half a source pixel at " + t);
        }
    }
}
