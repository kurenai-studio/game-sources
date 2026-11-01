package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * What the health bar does when it changes. Damage jolts it and reddens the
 * number; healing fills it back a segment at a time rather than jumping, so a
 * big potion reads as a big potion.
 */
class HpPulseTest {

    private static final float FRAME = 1f / 12f;

    /** A hit jolts the bar 4px left, then right, then settles. */
    @Test
    void damageShakesTheBarAndSettles() {
        // Nothing lost, so only the two-frame floor.
        assertEquals(-4, HpPulse.barOffset(120, 120, 0f));
        assertEquals(4, HpPulse.barOffset(120, 120, FRAME));
        assertEquals(0, HpPulse.barOffset(120, 120, 2 * FRAME));
    }

    /**
     * A fixed-length jolt would settle while a large hit was still bleeding,
     * leaving the bar calmly draining. The shake lasts the whole drain.
     */
    @Test
    void theShakeLastsAsLongAsTheBarIsDraining() {
        // 140 to 40 is ten segments, so ten frames of drain.
        for (int frame = 0; frame < 10; frame++) {
            assertEquals(frame % 2 == 0 ? -4 : 4, HpPulse.barOffset(140, 40, frame * FRAME),
                    "bar stopped shaking at frame " + frame + " while still draining");
            assertTrue(HpPulse.bleeding(140, 40, frame * FRAME),
                    "expected still bleeding at frame " + frame);
        }
        assertEquals(0, HpPulse.barOffset(140, 40, 10 * FRAME), "settles once the drain ends");
        assertFalse(HpPulse.bleeding(140, 40, 10 * FRAME));
    }

    /** The shake is always a multiple of 4px. */
    @Test
    void theShakeIsAlwaysAWholePixel() {
        for (float t = 0f; t < 1f; t += 0.004f) {
            assertEquals(0, Math.abs(HpPulse.barOffset(140, 40, t)) % 4,
                    "offset off the 4px grid at t=" + t);
        }
    }

    /**
     * The number holds its colour for as long as the bar is changing, so a big
     * hit does not go back to bone while it is still visibly bleeding.
     */
    @Test
    void theNumberStaysRedForTheWholeDrain() {
        for (int frame = 0; frame < 10; frame++) {
            assertTrue(HpPulse.numberBloodied(140, 40, frame * FRAME),
                    "number went back to bone at frame " + frame + ", still draining");
        }
        assertFalse(HpPulse.numberBloodied(140, 40, 10 * FRAME));
    }

    /** A hit that costs nothing still reddens the number for three frames. */
    @Test
    void aHitThatTakesNothingStillRedensBriefly() {
        assertTrue(HpPulse.numberBloodied(120, 120, 0f));
        assertTrue(HpPulse.numberBloodied(120, 120, 2 * FRAME));
        assertFalse(HpPulse.numberBloodied(120, 120, 3 * FRAME));
    }

    /** The number stays green while the bar fills, and not at all when nothing was gained. */
    @Test
    void theNumberStaysGreenForTheWholeFill() {
        // 0 to 120 is four frames at thirty pixels a frame.
        for (int frame = 0; frame < 4; frame++) {
            assertTrue(HpPulse.numberHealed(0, 120, frame * FRAME),
                    "number stopped being green at frame " + frame + ", still filling");
        }
        assertFalse(HpPulse.numberHealed(0, 120, 4 * FRAME));
        assertFalse(HpPulse.numberHealed(120, 120, 0f), "nothing gained, nothing green");
    }

    /**
     * A heal climbs three segments a frame. At one, the drain's rate, a big
     * drink would take the best part of a second to register — long after the
     * bottle had finished pouring. A drain earns its time because it is the
     * dramatic beat; a heal is just good news.
     */
    @Test
    void aHealGrowsThreeSegmentsPerFrame() {
        // From 100px to 160px is two frames at thirty pixels a frame.
        assertEquals(100, HpPulse.healWidth(100, 160, 0f));
        assertEquals(130, HpPulse.healWidth(100, 160, FRAME));
        assertEquals(160, HpPulse.healWidth(100, 160, 2 * FRAME));
    }

    /** The full bar, the longest heal there is, inside half a second. */
    @Test
    void evenAFullBarFillsPromptly() {
        int full = HudArt.barInteriorWidth();
        int frames = 0;
        while (!HpPulse.healFinished(0, full, frames * FRAME)) {
            frames++;
            assertTrue(frames < 30, "the heal never finished");
        }
        assertTrue(frames <= 8, "a full heal took " + frames + " frames");
    }

    /** A heal stops exactly on its target, even on a partial last step. */
    @Test
    void aHealNeverOvershootsItsTarget() {
        assertEquals(140, HpPulse.healWidth(100, 140, 99f));
        // A partial last step still lands exactly on the target.
        assertEquals(135, HpPulse.healWidth(100, 135, 99f));
        assertEquals(135, HpPulse.healWidth(100, 135, 4 * FRAME));
    }

    /** A heal holds each width for a whole frame. */
    @Test
    void aHealHoldsEachStepForAWholeFrame() {
        Set<Integer> widths = new LinkedHashSet<>();
        for (float t = 0f; t < 5 * FRAME; t += 0.004f) {
            widths.add(HpPulse.healWidth(100, 190, t));
        }
        assertEquals(4, widths.size(), "expected one width per frame, got " + widths);
    }

    /** A heal that changes nothing is finished at once. */
    @Test
    void aHealThatChangesNothingIsAlreadyDone() {
        assertEquals(120, HpPulse.healWidth(120, 120, 0f));
        assertTrue(HpPulse.healFinished(120, 120, 0f));
    }

    /**
     * Damage drains the bar the way a heal fills it — a segment a frame — so a
     * big hit reads as a big hit rather than the bar simply being shorter next
     * frame. It runs backwards, and stops exactly on the target.
     */
    @Test
    void damageDrainsOneSegmentPerFrame() {
        assertEquals(140, HpPulse.damageWidth(140, 100, 0f));
        assertEquals(130, HpPulse.damageWidth(140, 100, FRAME));
        assertEquals(120, HpPulse.damageWidth(140, 100, 2 * FRAME));
        assertEquals(100, HpPulse.damageWidth(140, 100, 4 * FRAME));
    }

    /** A drain stops exactly on its target, and a killing blow empties the bar. */
    @Test
    void damageNeverUndershootsItsTarget() {
        assertEquals(100, HpPulse.damageWidth(140, 100, 99f));
        assertEquals(105, HpPulse.damageWidth(140, 105, 99f));
        assertEquals(0, HpPulse.damageWidth(40, 0, 99f), "a killing blow empties the bar");
        assertTrue(HpPulse.damageWidth(140, 100, 99f) >= 0);
    }

    /** A hit for nothing jolts the bar without draining it. */
    @Test
    void aHitThatChangesNothingStillJolts() {
        // Being struck for zero -- a weapon that outclasses the monster -- should
        // still shake the bar, just not drain it.
        assertEquals(120, HpPulse.damageWidth(120, 120, 0f));
        assertEquals(-4, HpPulse.barOffset(120, 120, 0f));
    }

    /** The bar bleeds while it drains, and not when nothing was lost. */
    @Test
    void theBarBleedsWhileItIsDraining() {
        assertTrue(HpPulse.bleeding(140, 100, 0f));
        assertTrue(HpPulse.bleeding(140, 100, 2 * FRAME));
        assertFalse(HpPulse.bleeding(140, 100, 4 * FRAME), "settled once it reaches the target");
        assertFalse(HpPulse.bleeding(120, 120, 0f), "nothing lost, nothing bleeding");
    }

    /** The pulse is not over until both the jolt and the drain have finished. */
    @Test
    void aLongDrainOutlastsTheJolt() {
        // 140 to 40 is ten segments, far longer than the three-frame jolt.
        assertFalse(HpPulse.damageFinished(140, 40, 5 * FRAME));
        assertTrue(HpPulse.damageFinished(140, 40, 10 * FRAME));
        // And a short drain still waits for the jolt to end.
        assertFalse(HpPulse.damageFinished(140, 130, FRAME));
        assertTrue(HpPulse.damageFinished(140, 130, 3 * FRAME));
    }

    /** A hit for nothing ends with its jolt, and a heal once it reaches its target. */
    @Test
    void bothPulsesEnd() {
        assertTrue(HpPulse.damageFinished(120, 120, HpPulse.JOLT_TOTAL));
        assertFalse(HpPulse.damageFinished(120, 120, HpPulse.JOLT_TOTAL - 0.01f));
        assertTrue(HpPulse.healFinished(100, 160, 2 * FRAME));
        assertFalse(HpPulse.healFinished(100, 160, FRAME));
    }
}
