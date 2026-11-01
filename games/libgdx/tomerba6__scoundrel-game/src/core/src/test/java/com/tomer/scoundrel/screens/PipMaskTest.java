package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The four suit pips as 12×12 masks, rasterised from circles and triangles in a
 * 64-unit box and thresholded at each pixel's centre. A hard test rather than coverage
 * sampling: anti-aliasing a 12px glyph spends half its pixels on grey edges,
 * and grey is not a colour this board has.
 *
 * <p>Row widths are the whole shape at this size, so they are what is pinned,
 * for all four suits.
 */
class PipMaskTest {

    private static int[] widths(PipMask.Suit suit) {
        boolean[] mask = PipMask.generate(suit);
        int[] rows = new int[PipMask.SIZE];
        for (int y = 0; y < PipMask.SIZE; y++) {
            for (int x = 0; x < PipMask.SIZE; x++) {
                if (mask[y * PipMask.SIZE + x]) {
                    rows[y]++;
                }
            }
        }
        return rows;
    }

    /**
     * The diamond is a taxicab rhombus, stepping exactly one pixel a row — 45° on
     * the nose. Two triangles meeting at the waist would rasterise at this size
     * to four straight rows of eight through the middle: a rounded blob, not a
     * diamond.
     */
    @Test
    void theDiamondStepsOnePixelPerRow() {
        assertArrayEquals(new int[] {0, 2, 4, 6, 8, 10, 10, 8, 6, 4, 2, 0},
                widths(PipMask.Suit.DIAMONDS));
    }

    /**
     * The edges never run straight. Every row is wider than the one above it
     * until the waist and narrower after — the single pair of equal rows at the
     * widest point is the waist itself. Four equal rows there would make it read
     * round.
     */
    @Test
    void theDiamondHasNoStraightSides() {
        int[] rows = widths(PipMask.Suit.DIAMONDS);
        int repeats = 0;
        for (int y = 1; y < rows.length; y++) {
            if (rows[y] == rows[y - 1]) {
                repeats++;
            }
        }
        assertEquals(1, repeats, "the only equal pair should be the waist, got rows "
                + java.util.Arrays.toString(rows));
        // And each step is one pixel each side, which is what 45° means here.
        for (int y = 1; y <= 5; y++) {
            assertEquals(2, rows[y] - rows[y - 1], "row " + y + " did not step by one each side");
        }
    }

    /** The diamond mirrors across both axes. */
    @Test
    void theDiamondIsSymmetricBothWays() {
        boolean[] mask = PipMask.generate(PipMask.Suit.DIAMONDS);
        for (int y = 0; y < PipMask.SIZE; y++) {
            for (int x = 0; x < PipMask.SIZE; x++) {
                boolean on = mask[y * PipMask.SIZE + x];
                assertEquals(on, mask[y * PipMask.SIZE + (PipMask.SIZE - 1 - x)],
                        "not mirrored across x at " + x + "," + y);
                assertEquals(on, mask[(PipMask.SIZE - 1 - y) * PipMask.SIZE + x],
                        "not mirrored across y at " + x + "," + y);
            }
        }
    }

    /** The other three are pinned too, so a change to the diamond cannot reach them. */
    @Test
    void theClubIsUnchanged() {
        assertArrayEquals(new int[] {0, 4, 4, 4, 8, 8, 10, 10, 6, 2, 2, 4},
                widths(PipMask.Suit.CLUBS));
    }

    /** The heart's row widths are pinned. */
    @Test
    void theHeartIsUnchanged() {
        assertArrayEquals(new int[] {0, 6, 10, 10, 10, 10, 8, 6, 4, 2, 2, 0},
                widths(PipMask.Suit.HEARTS));
    }

    /** The spade's row widths are pinned. */
    @Test
    void theSpadeIsUnchanged() {
        assertArrayEquals(new int[] {0, 2, 4, 6, 8, 10, 10, 10, 10, 6, 2, 4},
                widths(PipMask.Suit.SPADES));
    }

    /** Every pip fills a 12×12 mask with more than twenty pixels inked. */
    @Test
    void everyPipFitsItsBoxAndIsActuallyInked() {
        for (PipMask.Suit suit : PipMask.Suit.values()) {
            boolean[] mask = PipMask.generate(suit);
            assertEquals(PipMask.SIZE * PipMask.SIZE, mask.length, suit + " is the wrong size");
            int inked = 0;
            for (boolean on : mask) {
                if (on) {
                    inked++;
                }
            }
            assertTrue(inked > 20, suit + " came out nearly blank: " + inked + " pixels");
        }
    }
}
