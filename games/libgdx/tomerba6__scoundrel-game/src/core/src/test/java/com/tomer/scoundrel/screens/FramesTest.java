package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The one place time is floored onto a frame grid. Nothing in this art tweens,
 * so every effect and every idle asks this class which frame it is on, and the
 * answer must be the same answer everywhere — so the grid, and the comment
 * explaining it, live here once.
 */
class FramesTest {

    /**
     * The whole reason the epsilon exists. A frame boundary is not exactly
     * representable in binary, so a bare floor can land a boundary one tick
     * late — and land it late only sometimes, which reads as two effects tuned
     * against each other drifting a frame apart.
     */
    @Test
    void aBoundaryLandsOnTheNewFrameRatherThanSticking() {
        for (int frame = 0; frame <= 24; frame++) {
            assertEquals(frame, Frames.at(frame / 12f, Frames.EFFECT_FPS),
                    "effect frame " + frame + " stuck on the one before it");
            assertEquals(frame, Frames.at(frame / 6f, Frames.IDLE_FPS),
                    "idle frame " + frame + " stuck on the one before it");
        }
    }

    /**
     * The case that first caught it: one whole five-frame idle cycle divided by
     * one frame yields 4.9999998, not 5, so the cycle held its last frame for an
     * extra tick every time it wrapped.
     */
    @Test
    void awholeIdleCycleIsFiveFramesAndNotAHairUnder() {
        assertEquals(5, Frames.at(IdleCycle.CYCLE_TIME, Frames.IDLE_FPS));
    }

    /** Inside a frame nothing moves at all — that is what quantising is for. */
    @Test
    void timeInsideAFrameNeverAdvancesTheIndex() {
        float frame = 1f / Frames.EFFECT_FPS;
        for (float within = 0.001f; within < frame - 0.001f; within += 0.002f) {
            assertEquals(3, Frames.at(3 * frame + within, Frames.EFFECT_FPS),
                    "the index moved " + within + "s into the frame");
        }
    }

    /**
     * Multiplying by the rate rather than dividing by a stored 1/12 keeps the
     * arithmetic exact for as long as the game is open. A float 1/12 is a hair
     * over the true value, and over an hour that error outgrows the epsilon —
     * the boundary would have started landing a frame late.
     */
    @Test
    void anHourInTheBoundariesAreStillExact() {
        assertEquals(43200, Frames.at(3600f, Frames.EFFECT_FPS));
        assertEquals(21600, Frames.at(3600f, Frames.IDLE_FPS));
    }

    /** Snapping gives the frame's own start time, so snapping it again is a no-op. */
    @Test
    void snappingReturnsTheFrameStartAndIsIdempotent() {
        float t = 0.3f;
        float snapped = Frames.snap(t, Frames.EFFECT_FPS);
        assertEquals(3 / 12f, snapped, 1e-6f);
        assertTrue(snapped <= t, "snapping may only ever floor");
        assertEquals(snapped, Frames.snap(snapped, Frames.EFFECT_FPS), 1e-6f);
    }

    /** A time before anything started is drawable, not an exception. */
    @Test
    void aClockThatHasNotStartedOrHasRewoundStillAnswers() {
        assertEquals(0, Frames.at(0f, Frames.EFFECT_FPS));
        assertEquals(-1, Frames.at(-0.01f, Frames.EFFECT_FPS));
        assertEquals(0f, Frames.snap(0f, Frames.EFFECT_FPS), 1e-6f);
    }

    /**
     * Flights hold each hop for a period rather than a rate, so they take the
     * period form; at the same grid the two must agree.
     */
    @Test
    void thePeriodFormAgreesWithTheRateForm() {
        float period = 1f / Frames.EFFECT_FPS;
        for (int frame = 0; frame <= 12; frame++) {
            assertEquals(Frames.at(frame * period, Frames.EFFECT_FPS),
                    Frames.atPeriod(frame * period, period),
                    "the two forms disagree at frame " + frame);
        }
    }

    /** The rates the art was drawn at: effects at 12, idles at the calmer 6. */
    @Test
    void theTwoRatesAreTheOnesTheArtWasDrawnAt() {
        assertEquals(12, Frames.EFFECT_FPS);
        assertEquals(6, Frames.IDLE_FPS);
    }
}
