package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * A wasted potion: the second one taken in a room, which heals nothing. The
 * card collapses into the same bottle a drink does, drained of colour, and it
 * tips over and spills where the card was.
 *
 * <p>The whole point is that it <b>goes nowhere</b>. A wasted potion that flew
 * to the health bar and tipped over it with nothing to pour would read as the
 * heal being broken; spilling it on the table says the potion was wasted, which is
 * what actually happened.
 */
class PotionSpillTest {

    private static final float FRAME = 1f / 12f;

    /** A spill starts with the same collapse as a drink. */
    @Test
    void itStartsExactlyAsADrinkDoes() {
        // Same collapse, so you cannot tell the two apart until the bottle
        // either sets off for the bar or stays put and tips.
        assertEquals(PotionDrink.COLLAPSE_FRAMES, PotionSpill.COLLAPSE_FRAMES);
        assertEquals(100, PotionSpill.cardScale(0f));
        assertTrue(PotionSpill.cardScale(FRAME) < 100, "the card should be folding away");
        assertEquals(0, PotionSpill.cardScale(PotionSpill.COLLAPSE_FRAMES * FRAME));
    }

    /** The bottle stays upright and dry until the card has gone. */
    @Test
    void theBottleIsUprightUntilTheCardHasGone() {
        for (float t = 0f; t < PotionSpill.COLLAPSE_FRAMES * FRAME; t += 0.004f) {
            assertEquals(0f, PotionSpill.tiltDegrees(t), 1e-4f, "tipped early at t=" + t);
            assertEquals(0, PotionSpill.dropsFallen(t), "spilled early at t=" + t);
        }
    }

    /** The bottle tips in held steps, never between them, and ends well over. */
    @Test
    void itTipsThroughHeldStagesAndNeverSweeps() {
        Set<Float> angles = new LinkedHashSet<>();
        for (float t = 0f; t < PotionSpill.TOTAL; t += 0.004f) {
            angles.add(PotionSpill.tiltDegrees(t));
        }
        assertEquals(PotionSpill.TIP_STEPS + 1, angles.size(),
                "expected upright plus each held step, got " + angles);
        assertTrue(PotionSpill.tiltDegrees(PotionSpill.TOTAL - FRAME) < -30f,
                "it should end well over");
    }

    /** The drops fall one at a time, from the moment the bottle has tipped. */
    @Test
    void theDropsFallOnceItHasTipped() {
        assertEquals(0, PotionSpill.dropsFallen(PotionSpill.SPILL_START - FRAME));
        assertTrue(PotionSpill.dropsFallen(PotionSpill.SPILL_START) > 0, "nothing came out");
        assertEquals(PotionSpill.drops(), PotionSpill.dropsFallen(PotionSpill.TOTAL - FRAME));
        // They arrive one at a time rather than all at once.
        Set<Integer> counts = new LinkedHashSet<>();
        for (float t = PotionSpill.SPILL_START; t < PotionSpill.TOTAL; t += 0.004f) {
            counts.add(PotionSpill.dropsFallen(t));
        }
        assertTrue(counts.size() >= PotionSpill.drops(),
                "drops should dribble rather than appear together, saw " + counts);
    }

    /** It slumps as it goes over, on the same 4px grid every other shake uses. */
    @Test
    void itSlumpsOnAWholePixelGrid() {
        boolean moved = false;
        for (float t = 0f; t < PotionSpill.TOTAL; t += 0.004f) {
            int slump = PotionSpill.slump(t);
            assertEquals(0, slump % 4, "slump off the 4px grid at t=" + t + ": " + slump);
            moved |= slump != 0;
        }
        assertTrue(moved, "the bottle never settled");
    }

    /** Every value holds for a whole frame. */
    @Test
    void everyValueHoldsForAWholeFrame() {
        for (int frame = 0; frame < 6; frame++) {
            Set<String> seen = new LinkedHashSet<>();
            for (float within = 0f; within < FRAME - 1e-4f; within += 0.004f) {
                float t = frame * FRAME + within;
                seen.add(PotionSpill.tiltDegrees(t) + "|" + PotionSpill.dropsFallen(t)
                        + "|" + PotionSpill.cardScale(t) + "|" + PotionSpill.slump(t));
            }
            assertEquals(1, seen.size(), "values slid within frame " + frame + ": " + seen);
        }
    }

    /**
     * Shorter than a drink. Nothing is gained by it, so it should not hold the
     * board as long as the one that heals you.
     */
    @Test
    void itIsOverSoonerThanADrink() {
        assertTrue(PotionSpill.TOTAL < PotionDrink.TOTAL,
                "a wasted potion should not outlast a real one: "
                        + PotionSpill.TOTAL + " vs " + PotionDrink.TOTAL);
        assertTrue(PotionSpill.TOTAL > 0.45f && PotionSpill.TOTAL < 0.55f,
                "expected ~500ms, was " + PotionSpill.TOTAL);
        assertTrue(PotionSpill.finished(PotionSpill.TOTAL));
        assertFalse(PotionSpill.finished(PotionSpill.TOTAL - 0.01f));
    }
}
