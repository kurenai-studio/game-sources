package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The sizes Silkscreen is allowed to be rendered at.
 *
 * <p>Every one must be even. The viewport snaps to half-steps, so at 1920×1080 —
 * the commonest display — everything is drawn at ×1.5, and an odd size lands on
 * a half pixel. A pixel face at a half pixel is exactly the blur the whole art
 * direction exists to avoid, and it would be invisible in code review.
 */
class PixelTypeTest {

    /** Every size is even. */
    @Test
    void everySizeIsEven() {
        for (int size : PixelType.SIZES) {
            assertEquals(0, size % 2,
                    size + "px is odd, so it lands on a half pixel at the ×1.5 viewport");
        }
    }

    /** Every size lands on a whole pixel at ×1, ×1.5, ×2 and ×3. */
    @Test
    void everySizeSurvivesTheViewportScales() {
        // 1.0, 1.5, 2.0 and 3.0 are the scales PixelScale can produce on common
        // displays; a size must land on a whole pixel at each.
        for (int size : PixelType.SIZES) {
            for (float scale : new float[] {1.0f, 1.5f, 2.0f, 3.0f}) {
                float drawn = size * scale;
                assertEquals(Math.round(drawn), drawn, 1e-4f,
                        size + "px renders at " + drawn + " when scaled ×" + scale);
            }
        }
    }

    /**
     * There are at least five sizes, ascending, with the smallest caption at 8
     * and the display size at 38.
     */
    @Test
    void theSizesCoverWhatTheScreensAskFor() {
        // Smallest caption through to the card value, with nothing in between
        // that a screen would have to round.
        assertTrue(PixelType.SIZES.length >= 5, "too few sizes to build the screens from");
        assertEquals(8, PixelType.SMALL);
        assertEquals(38, PixelType.DISPLAY);
        for (int i = 1; i < PixelType.SIZES.length; i++) {
            assertTrue(PixelType.SIZES[i] > PixelType.SIZES[i - 1], "sizes should ascend");
        }
    }

    /** 11 and 13 are odd, so neither is a size; text that would be set at one is set at 12 or 14. */
    @Test
    void theOddSizesFromTheSpecAreNotUsed() {
        for (int size : PixelType.SIZES) {
            assertTrue(size != 11 && size != 13,
                    size + "px is an odd size; use the even neighbour");
        }
    }
}
