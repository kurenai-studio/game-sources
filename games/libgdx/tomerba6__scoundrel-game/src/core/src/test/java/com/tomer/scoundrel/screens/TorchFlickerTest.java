package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The torch's flicker: bounded, visibly moving, smooth from frame to frame, and
 * the same at the same moment.
 */
class TorchFlickerTest {

    /** Over five minutes the brightness stays within its depth either side of 1. */
    @Test
    void staysWithinItsBoundsAcrossALongSweep() {
        for (float t = 0; t < 300; t += 0.01f) {
            float i = TorchFlicker.intensityAt(t);
            assertTrue(i >= 1f - TorchFlicker.DEPTH - 1e-4f && i <= 1f + TorchFlicker.DEPTH + 1e-4f,
                    "intensity " + i + " out of bounds at t=" + t);
        }
    }

    /** Over twenty seconds the brightness swings by more than its depth. */
    @Test
    void actuallyFlickers() {
        float min = Float.MAX_VALUE;
        float max = -Float.MAX_VALUE;
        for (float t = 0; t < 20; t += 0.01f) {
            float i = TorchFlicker.intensityAt(t);
            min = Math.min(min, i);
            max = Math.max(max, i);
        }
        // It should swing across a real portion of its range, not sit near constant.
        assertTrue(max - min > TorchFlicker.DEPTH, "range too small: " + (max - min));
    }

    /** The brightness changes by less than 0.03 from one 60 fps frame to the next. */
    @Test
    void isContinuousFrameToFrame() {
        float dt = 1f / 60f;
        float previous = TorchFlicker.intensityAt(0);
        for (float t = dt; t < 60; t += dt) {
            float i = TorchFlicker.intensityAt(t);
            assertTrue(Math.abs(i - previous) < 0.03f,
                    "jump of " + Math.abs(i - previous) + " at t=" + t);
            previous = i;
        }
    }

    /** The same moment gives the same brightness. */
    @Test
    void isDeterministic() {
        assertEquals(TorchFlicker.intensityAt(7.5f), TorchFlicker.intensityAt(7.5f));
    }
}
