package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The weapon kill's timeline. The outline flashes cream with the creature still
 * on the card, and only then does the blade land.
 *
 * <p>That ordering is the whole point of the effect and it is easy to lose:
 * halves that exist but are merely transparent during the flash still cover the
 * sprite. The property test below is the guard — nothing may be drawable over
 * the card before the flash ends.
 */
class WeaponKillTest {

    /** The flash holds for one frame and then ends. */
    @Test
    void theFlashHoldsBeforeAnythingElseHappens() {
        assertEquals(WeaponKill.FRAME, WeaponKill.RIM_TIME, 1e-6f);
        assertTrue(WeaponKill.rimShowing(0f));
        assertTrue(WeaponKill.rimShowing(WeaponKill.RIM_TIME - 0.01f));
        assertFalse(WeaponKill.rimShowing(WeaponKill.RIM_TIME));
    }

    /**
     * The load-bearing invariant. Checked densely rather than at the boundary,
     * because the failure mode is an element that exists early and occludes the
     * creature while invisible.
     */
    @Test
    void nothingIsDrawableOverTheCardUntilTheFlashEnds() {
        for (float t = 0f; t < WeaponKill.RIM_TIME; t += 0.001f) {
            assertFalse(WeaponKill.cardCut(t), "card counted as cut at t=" + t);
            assertFalse(WeaponKill.halvesShowing(t), "halves present at t=" + t);
            assertFalse(WeaponKill.slashShowing(t), "slash present at t=" + t);
            assertEquals(0, WeaponKill.cardLift(t), "card lifted at t=" + t);
        }
    }

    /** As the flash ends the card is cut and lifted 10px. */
    @Test
    void theBladeLandsTheInstantTheFlashEnds() {
        float t = WeaponKill.RIM_TIME;
        assertTrue(WeaponKill.cardCut(t));
        assertEquals(10, WeaponKill.cardLift(t), "the blow should pick the card up 10px");
    }

    /**
     * The card is lifted whole for a frame, and only then does anything cover
     * it — that ordering is the effect. The slash and the parting share the next
     * frame: the bar crosses as the halves come apart, which is what a blade
     * actually does.
     */
    @Test
    void theCardIsLiftedWholeBeforeAnythingCoversIt() {
        assertTrue(WeaponKill.cardCut(WeaponKill.RIM_TIME), "the blade lands");
        assertFalse(WeaponKill.slashShowing(WeaponKill.RIM_TIME), "nothing covers it yet");
        assertFalse(WeaponKill.halvesShowing(WeaponKill.RIM_TIME));
        // Then the bar and the parting together, on the next frame.
        assertTrue(WeaponKill.slashShowing(WeaponKill.RIM_TIME + WeaponKill.FRAME));
        assertTrue(WeaponKill.halvesShowing(WeaponKill.RIM_TIME + WeaponKill.FRAME));
    }

    /** The halves rise and drift apart, the upper left and the lower right. */
    @Test
    void theHalvesPartAndRiseWithoutEverRotating() {
        // Whole-pixel offsets only. There is no rotation in the API at all --
        // a turned pixel is a blurred pixel, so it is not expressible.
        float start = WeaponKill.RIM_TIME + WeaponKill.FRAME;
        int previousUpper = 0;
        int previousLower = 0;
        for (int step = 0; step < 3; step++) {
            float t = start + step * WeaponKill.FRAME;
            int upper = -WeaponKill.upperDy(t);
            int lower = -WeaponKill.lowerDy(t);
            assertTrue(upper >= previousUpper, "upper half stopped rising at step " + step);
            assertTrue(lower >= previousLower, "lower half stopped rising at step " + step);
            previousUpper = upper;
            previousLower = lower;
        }
        // They part: one drifts left, the other right.
        float end = start + 2 * WeaponKill.FRAME;
        assertTrue(WeaponKill.upperDx(end) < 0, "upper half should drift left");
        assertTrue(WeaponKill.lowerDx(end) > 0, "lower half should drift right");
    }

    /** The halves fade out by the end. */
    @Test
    void theHalvesFadeOut() {
        float start = WeaponKill.RIM_TIME + WeaponKill.FRAME;
        assertTrue(WeaponKill.halfAlpha(start) > WeaponKill.halfAlpha(start + 2 * WeaponKill.FRAME));
        assertEquals(0f, WeaponKill.halfAlpha(WeaponKill.TOTAL), 1e-6f);
    }

    /**
     * Effects run at 12fps and every segment holds on a frame. If any value
     * changed within a frame the effect would slide instead of stepping.
     */
    @Test
    void everyValueHoldsForAWholeFrame() {
        for (int frame = 0; frame < 4; frame++) {
            Set<String> seen = new LinkedHashSet<>();
            for (float within = 0f; within < WeaponKill.FRAME - 1e-4f; within += 0.004f) {
                float t = frame * WeaponKill.FRAME + within;
                seen.add(WeaponKill.cardLift(t) + "|" + WeaponKill.upperDx(t) + "|"
                        + WeaponKill.upperDy(t) + "|" + WeaponKill.lowerDx(t) + "|"
                        + WeaponKill.lowerDy(t) + "|" + WeaponKill.halfAlpha(t) + "|"
                        + WeaponKill.slashOffset(t));
            }
            assertEquals(1, seen.size(), "values slid within frame " + frame + ": " + seen);
        }
    }

    /** The kill is four frames long, flash included, and then over. */
    @Test
    void theEffectEnds() {
        assertFalse(WeaponKill.finished(WeaponKill.TOTAL - 0.01f));
        assertTrue(WeaponKill.finished(WeaponKill.TOTAL));
        assertTrue(WeaponKill.finished(99f));
        // Flash then blade: the whole kill inside a third of a second.
        assertEquals(WeaponKill.RIM_TIME + 3 * WeaponKill.FRAME, WeaponKill.TOTAL, 1e-6f);
        assertEquals(4 * WeaponKill.FRAME, WeaponKill.TOTAL, 1e-6f);
    }

    /** Times floor onto the 12 fps grid. */
    @Test
    void quantiseFloorsToTheEffectGrid() {
        assertEquals(0f, WeaponKill.quantise(0f), 1e-6f);
        assertEquals(0f, WeaponKill.quantise(WeaponKill.FRAME - 0.001f), 1e-6f);
        assertEquals(WeaponKill.FRAME, WeaponKill.quantise(WeaponKill.FRAME), 1e-6f);
        assertEquals(4 * WeaponKill.FRAME, WeaponKill.quantise(0.36f), 1e-5f);
    }
}
