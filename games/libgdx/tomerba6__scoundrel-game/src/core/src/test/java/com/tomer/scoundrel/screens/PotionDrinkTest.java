package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Drinking a potion: the card collapses into its bottle, the bottle hops to the
 * health bar, tips, and pours while the bar fills and drops fall.
 *
 * <p>The phases run in that order and never overlap wrongly — the bar must not
 * start filling before the bottle has arrived and tipped, or the drink reads as
 * two unrelated things happening at once.
 */
class PotionDrinkTest {

    private static final float FRAME = 1f / 12f;

    /** The card collapses, then the bottle flies, then it pours once it has arrived. */
    @Test
    void thePhasesRunInOrder() {
        assertTrue(PotionDrink.collapsing(0f), "starts by collapsing the card");
        assertFalse(PotionDrink.flying(0f), "and has not set off yet");

        float flight = PotionDrink.COLLAPSE_FRAMES * FRAME;
        assertFalse(PotionDrink.collapsing(flight));
        assertTrue(PotionDrink.flying(flight));

        assertFalse(PotionDrink.pouring(flight), "cannot pour in mid-air");
        assertTrue(PotionDrink.pouring(PotionDrink.POUR_START), "pours once it has arrived");
    }

    /**
     * The load-bearing one: nothing reaches the bar until the bottle is there
     * and tipped.
     */
    @Test
    void theBarDoesNotFillBeforeTheBottleTips() {
        for (float t = 0f; t < PotionDrink.POUR_START; t += 0.002f) {
            assertFalse(PotionDrink.pouring(t), "poured early at t=" + t);
            assertEquals(0, PotionDrink.dropsFallen(t), "a drop fell early at t=" + t);
        }
    }

    /** The bottle goes from upright to fully tipped in held steps, with nothing in between. */
    @Test
    void theBottleTipsThroughDiscreteStages() {
        Set<Integer> stages = new LinkedHashSet<>();
        for (float t = 0f; t < PotionDrink.TOTAL; t += 0.004f) {
            stages.add(PotionDrink.tiltStage(t));
        }
        // Upright, then each lean stage, and nothing in between.
        assertEquals(PotionDrink.TIP_STEPS + 1, stages.size(),
                "expected upright plus each step, got " + stages);
        assertEquals(0, PotionDrink.tiltStage(0f), "upright while it is still a card");
        assertEquals(PotionDrink.TIP_STEPS, PotionDrink.tiltStage(PotionDrink.TOTAL - FRAME),
                "fully turned by the end");
    }

    /** The angle holds discrete values; it never sweeps between them. */
    @Test
    void theAngleIsHeldNotSwept() {
        Set<Float> angles = new LinkedHashSet<>();
        for (float t = 0f; t < PotionDrink.TOTAL; t += 0.004f) {
            angles.add(PotionDrink.tiltDegrees(t));
        }
        assertEquals(PotionDrink.TIP_STEPS + 1, angles.size(),
                "expected one angle per step, got " + angles);
        assertEquals(0f, PotionDrink.tiltDegrees(0f), 1e-4f);
        assertTrue(PotionDrink.tiltDegrees(PotionDrink.TOTAL - FRAME) < -50f,
                "should end well over");
    }

    /** Three drops fall during the pour, one at a time. */
    @Test
    void threeDropsFallOverThePour() {
        assertEquals(0, PotionDrink.dropsFallen(PotionDrink.POUR_START - FRAME));
        assertEquals(3, PotionDrink.dropsFallen(PotionDrink.TOTAL));
        // They arrive one at a time rather than all at once.
        Set<Integer> counts = new LinkedHashSet<>();
        for (float t = PotionDrink.POUR_START; t < PotionDrink.TOTAL; t += 0.004f) {
            counts.add(PotionDrink.dropsFallen(t));
        }
        assertTrue(counts.size() >= 3, "drops should arrive separately, saw " + counts);
    }

    /** The card starts full size and shrinks from the second frame. */
    @Test
    void theCardShrinksIntoTheBottleRatherThanVanishing() {
        assertEquals(100, PotionDrink.cardScale(0f));
        assertTrue(PotionDrink.cardScale(FRAME) < 100, "should be shrinking by the second frame");
        assertTrue(PotionDrink.cardScale(PotionDrink.COLLAPSE_FRAMES * FRAME) <= 100);
    }

    /** Every value holds for a whole frame. */
    @Test
    void everyValueHoldsForAWholeFrame() {
        for (int frame = 0; frame < 8; frame++) {
            Set<String> seen = new LinkedHashSet<>();
            for (float within = 0f; within < FRAME - 1e-4f; within += 0.004f) {
                float t = frame * FRAME + within;
                seen.add(PotionDrink.tiltStage(t) + "|" + PotionDrink.dropsFallen(t)
                        + "|" + PotionDrink.cardScale(t));
            }
            assertEquals(1, seen.size(), "values slid within frame " + frame + ": " + seen);
        }
    }

    /**
     * Eight frames keep every phase, with the bottle turning over in a single
     * held step; any longer and the bottle sits tipped over a bar that has
     * already filled. Nothing here tweens, so one step looks as deliberate as
     * two, only quicker.
     */
    @Test
    void theDrinkIsOverInTwoThirdsOfASecond() {
        assertTrue(PotionDrink.TOTAL > 0.62f && PotionDrink.TOTAL < 0.72f,
                "expected ~667ms, was " + PotionDrink.TOTAL);
        assertTrue(PotionDrink.finished(PotionDrink.TOTAL));
        assertFalse(PotionDrink.finished(PotionDrink.TOTAL - 0.01f));
    }
}
