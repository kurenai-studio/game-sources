package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.Random;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The idle animation's clock: five frames at 6 fps, looping, each card started
 * at its own random offset so a room does not breathe in lockstep. Quantising
 * here is what stops a frame ever being interpolated.
 */
class IdleCycleTest {

    private static final int FRAMES = 5;

    /** The idle runs at 6 fps, so a frame holds 1/6s and the five-frame cycle 5/6s. */
    @Test
    void aCycleIsFiveFramesAtSixFps() {
        assertEquals(6, IdleCycle.FPS);
        assertEquals(1f / 6f, IdleCycle.FRAME_TIME, 1e-6f);
        // 5 frames x 167ms
        assertEquals(5f / 6f, IdleCycle.CYCLE_TIME, 1e-6f);
    }

    /** Every moment inside a frame shows that frame. */
    @Test
    void timeHoldsOnAFrameRatherThanSlidingBetweenThem() {
        // Every instant inside a frame's 167ms returns that same frame; the
        // whole art direction depends on segments holding, never tweening.
        assertEquals(0, IdleCycle.frameIndex(0.000f, 0f, FRAMES));
        assertEquals(0, IdleCycle.frameIndex(0.166f, 0f, FRAMES));
        assertEquals(1, IdleCycle.frameIndex(0.167f, 0f, FRAMES));
        assertEquals(1, IdleCycle.frameIndex(0.333f, 0f, FRAMES));
        assertEquals(2, IdleCycle.frameIndex(0.334f, 0f, FRAMES));
        assertEquals(4, IdleCycle.frameIndex(0.834f - 0.002f, 0f, FRAMES));
    }

    /** The cycle loops back to its first frame. */
    @Test
    void theCycleLoops() {
        assertEquals(0, IdleCycle.frameIndex(IdleCycle.CYCLE_TIME, 0f, FRAMES));
        assertEquals(1, IdleCycle.frameIndex(IdleCycle.CYCLE_TIME + 0.2f, 0f, FRAMES));
        assertEquals(0, IdleCycle.frameIndex(IdleCycle.CYCLE_TIME * 100, 0f, FRAMES));
    }

    /** A card's offset shifts which frame it shows. */
    @Test
    void anOffsetShiftsThePhase() {
        // Two cards a frame apart show different frames at the same instant --
        // which is the entire point of the stagger.
        assertEquals(0, IdleCycle.frameIndex(0f, 0f, FRAMES));
        assertEquals(1, IdleCycle.frameIndex(0f, IdleCycle.FRAME_TIME, FRAMES));
        assertEquals(3, IdleCycle.frameIndex(0f, 3 * IdleCycle.FRAME_TIME, FRAMES));
    }

    /** The frame index is always in range, whatever the time and offset. */
    @Test
    void theIndexIsAlwaysInRange() {
        Random random = new Random(20260805L);
        for (int i = 0; i < 20000; i++) {
            float elapsed = random.nextFloat() * 600f;
            float offset = random.nextFloat() * IdleCycle.CYCLE_TIME;
            int index = IdleCycle.frameIndex(elapsed, offset, FRAMES);
            assertTrue(index >= 0 && index < FRAMES,
                    "index " + index + " out of range at t=" + elapsed + " off=" + offset);
        }
    }

    /** A negative delta from a paused or rewound clock must not throw. */
    @Test
    void aNegativeTimeStillYieldsALegalFrame() {
        for (float t = -5f; t < 0f; t += 0.05f) {
            int index = IdleCycle.frameIndex(t, 0f, FRAMES);
            assertTrue(index >= 0 && index < FRAMES, "bad index " + index + " at t=" + t);
        }
    }

    /** Random offsets fall within one cycle and reach into its last frame. */
    @Test
    void offsetsSpanExactlyOneCycleAndNoMore() {
        Random random = new Random(7L);
        float max = 0f;
        for (int i = 0; i < 5000; i++) {
            float offset = IdleCycle.randomOffset(random);
            assertTrue(offset >= 0f && offset < IdleCycle.CYCLE_TIME,
                    "offset outside one cycle: " + offset);
            max = Math.max(max, offset);
        }
        // Should reach well into the last frame, or the stagger is lopsided.
        assertTrue(max > IdleCycle.CYCLE_TIME * 0.9f, "offsets never reach the end: max " + max);
    }

    /**
     * Four cards breathing at once reads as busy, so only the card the
     * player is looking at animates and the rest hold on frame 1 — which is the
     * base sprite, pixel-identical, so a frozen card is indistinguishable from a
     * static one.
     */
    @Test
    void aCardThatIsNotTheFocusHoldsOnTheBaseFrame() {
        for (float t = 0f; t < 3f; t += 0.07f) {
            assertEquals(0, IdleCycle.frameIndex(t, 0.4f, FRAMES, false),
                    "an unfocused card moved at t=" + t);
        }
    }

    /** The focused card passes through every frame. */
    @Test
    void theFocusedCardStillRunsItsCycle() {
        Set<Integer> seen = new HashSet<>();
        for (float t = 0f; t < IdleCycle.CYCLE_TIME; t += 0.02f) {
            seen.add(IdleCycle.frameIndex(t, 0f, FRAMES, true));
        }
        assertEquals(FRAMES, seen.size(), "focused card should pass through every frame");
    }

    /**
     * The stagger has to actually spread a room. With four cards drawn from one
     * cycle of offsets, they should rarely all show the same frame.
     */
    @Test
    void fourStaggeredCardsUsuallyShowDifferentFrames() {
        Random random = new Random(99L);
        int lockstep = 0;
        int trials = 2000;
        for (int t = 0; t < trials; t++) {
            Set<Integer> shown = new HashSet<>();
            for (int card = 0; card < 4; card++) {
                shown.add(IdleCycle.frameIndex(0f, IdleCycle.randomOffset(random), FRAMES));
            }
            if (shown.size() == 1) {
                lockstep++;
            }
        }
        // Chance of four independent picks landing on one frame is (1/5)^3 = 0.8%.
        assertTrue(lockstep < trials * 0.03,
                "rooms in lockstep " + lockstep + "/" + trials + " — offsets are not spreading");
    }
}
