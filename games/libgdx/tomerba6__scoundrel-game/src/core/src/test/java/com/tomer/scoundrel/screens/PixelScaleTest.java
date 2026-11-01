package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The scaling rule behind the pixel-art viewport. A sprite is 64×64 drawn at ×2
 * in world units, so one source pixel covers {@code 2 * viewportScale} screen
 * pixels — and that has to be a whole number, or neighbouring source pixels get
 * different widths and the art shimmers.
 */
class PixelScaleTest {

    private static final float W = 1280;
    private static final float H = 720;

    /** A scale already on a half-step is kept. */
    @Test
    void aScaleThatIsAlreadyCleanIsLeftAlone() {
        assertEquals(1.0f, PixelScale.snap(1.0f));
        assertEquals(1.5f, PixelScale.snap(1.5f));
        assertEquals(2.0f, PixelScale.snap(2.0f));
        assertEquals(3.0f, PixelScale.snap(3.0f));
    }

    /** A scale between half-steps falls to the one below. */
    @Test
    void aFractionalScaleFallsToTheHalfStepBelow() {
        // Rounding *down* rather than to nearest: rounding up would scale the
        // world larger than the window and crop the board.
        assertEquals(1.0f, PixelScale.snap(1.25f));
        assertEquals(1.0f, PixelScale.snap(1.4999f));
        assertEquals(2.5f, PixelScale.snap(2.9f));
    }

    /** No scale snaps below 0.5. */
    @Test
    void itNeverCollapsesBelowAHalfStep() {
        // A window smaller than half the design size would otherwise snap to 0
        // and draw nothing at all.
        assertEquals(0.5f, PixelScale.snap(0.4f));
        assertEquals(0.5f, PixelScale.snap(0.01f));
    }

    /** The property the whole class exists for, over the entire useful range. */
    @Test
    void everySnappedScaleGivesWholeScreenPixelsPerSourcePixel() {
        for (int hundredths = 50; hundredths <= 600; hundredths++) {
            float raw = hundredths / 100f;
            float onePixel = PixelScale.snap(raw) * 2f; // sprites draw at ×2
            assertEquals(Math.round(onePixel), onePixel, 1e-4f,
                    "raw " + raw + " snapped to " + PixelScale.snap(raw)
                            + ", which puts a source pixel at " + onePixel + " screen px");
        }
    }

    /** Above the 0.5 floor, the world never comes out larger than the window. */
    @Test
    void neverScalesTheWorldLargerThanTheWindow() {
        for (int w = 640; w <= 3840; w += 17) {
            for (int h = 360; h <= 2160; h += 23) {
                float scale = PixelScale.forScreen(w, h, W, H);
                assertTrue(W * scale <= w + 0.001f || scale == 0.5f,
                        "world overflows width at " + w + "x" + h);
                assertTrue(H * scale <= h + 0.001f || scale == 0.5f,
                        "world overflows height at " + w + "x" + h);
            }
        }
    }

    /**
     * Common displays get 1.0 up to 1600×900, 1.5 at 1920×1080, 2.0 at 2560×1440
     * and 3.0 at 3840×2160.
     */
    @Test
    void commonDisplaysGetTheExpectedScale() {
        // 1080p is the case worth protecting: it fits at exactly 1.5, which is
        // already clean at ×2 sprites, so snapping must not drop it to 1.0 and
        // letterbox a third of the screen away.
        assertEquals(1.0f, PixelScale.forScreen(1280, 720, W, H));
        assertEquals(1.0f, PixelScale.forScreen(1366, 768, W, H));
        assertEquals(1.0f, PixelScale.forScreen(1600, 900, W, H));
        assertEquals(1.5f, PixelScale.forScreen(1920, 1080, W, H));
        assertEquals(2.0f, PixelScale.forScreen(2560, 1440, W, H));
        assertEquals(3.0f, PixelScale.forScreen(3840, 2160, W, H));
    }

    /** An ultrawide's scale is set by its height. */
    @Test
    void anUltrawideIsLimitedByItsHeight() {
        // 3440x1440: 2.68 across but only 2.0 down, so height wins and the
        // extra width becomes side bars.
        assertEquals(2.0f, PixelScale.forScreen(3440, 1440, W, H));
    }

    /** A 16:10 display's scale is set by its width. */
    @Test
    void aSixteenTenDisplayIsLimitedByItsWidth() {
        assertEquals(1.5f, PixelScale.forScreen(1920, 1200, W, H));
    }
}
