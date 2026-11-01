package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The bottle a wasted potion collapses into: the same shape as the one you
 * actually drink, with the colour drained out of it.
 *
 * <p>Drained means moved to the bone ramp at the step it already occupied, not
 * desaturated arithmetically. A greyscale conversion invents colours nowhere in
 * the art; taking the same step of a different material keeps every pixel
 * inside the eighty and preserves the light-to-dark structure, so the bottle
 * still reads as a bottle rather than a silhouette.
 */
class SpentMaskTest {

    private static final int OPAQUE = 0xff000000;

    /** Every drained colour is on the ramps. */
    @Test
    void everyDrainedColourIsStillOnThePalette() {
        int[] source = {
            OPAQUE | 0x5d8a4a,   // the bottle's glass
            OPAQUE | 0x507641,   // its shaded side
            OPAQUE | 0x35291f,   // its dark lip
            OPAQUE | 0x9a8b70,   // the cork
        };
        int[] spent = SpentMask.generate(source);
        for (int argb : spent) {
            assertTrue(Ramps.contains(argb & 0xffffff),
                    "#" + Integer.toHexString(argb & 0xffffff) + " is off the palette");
        }
    }

    /** The glass loses its green for a near-neutral tone. */
    @Test
    void theColourIsActuallyDrained() {
        int[] spent = SpentMask.generate(new int[] {OPAQUE | 0x5d8a4a});
        assertNotEquals(0x5d8a4a, spent[0] & 0xffffff, "the glass kept its green");
        int rgb = spent[0] & 0xffffff;
        int r = (rgb >> 16) & 0xff;
        int g = (rgb >> 8) & 0xff;
        int b = rgb & 0xff;
        // Bone is near-neutral: no channel runs away from the others the way a
        // green does. The source has g - r = 45.
        assertTrue(Math.abs(g - r) < 20 && Math.abs(r - b) < 60,
                "expected a neutral tone, got " + r + "," + g + "," + b);
    }

    /**
     * The structure survives. A pixel that was darker than its neighbour has to
     * stay darker, or the bottle loses the shading that makes it look round.
     */
    @Test
    void lightAndDarkKeepTheirOrder() {
        int[] spent = SpentMask.generate(new int[] {
            OPAQUE | 0x35291f,   // lip: darkest
            OPAQUE | 0x507641,   // shade
            OPAQUE | 0x5d8a4a,   // glass: lightest of the three
        });
        assertTrue(luma(spent[0]) < luma(spent[1]), "the lip stopped being the darkest");
        assertTrue(luma(spent[1]) <= luma(spent[2]), "the shade outran the glass");
    }

    /** Clear pixels stay clear and opaque ones opaque. */
    @Test
    void transparentPixelsStayTransparent() {
        int[] spent = SpentMask.generate(new int[] {0, OPAQUE | 0x5d8a4a, 0});
        assertEquals(0, spent[0]);
        assertEquals(0, spent[2]);
        assertEquals(0xff, spent[1] >>> 24, "an opaque pixel should stay opaque");
    }

    /** Generating leaves the source untouched. */
    @Test
    void theSourceIsNotTouched() {
        int[] source = {OPAQUE | 0x5d8a4a};
        SpentMask.generate(source);
        assertEquals(OPAQUE | 0x5d8a4a, source[0], "generate() wrote through its argument");
    }

    private static int luma(int argb) {
        return ((argb >> 16) & 0xff) + ((argb >> 8) & 0xff) + (argb & 0xff);
    }
}
