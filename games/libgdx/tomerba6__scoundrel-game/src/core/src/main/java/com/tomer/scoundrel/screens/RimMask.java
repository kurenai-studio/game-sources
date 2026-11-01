package com.tomer.scoundrel.screens;

/**
 * Builds the cream outline used by the weapon-kill flash, from a sprite's own
 * pixels: every solid pixel with at least one transparent edge-neighbour becomes
 * cream, everything else clear.
 *
 * <p>Generated at load rather than shipped, which keeps 52 files out of the
 * atlas and stays correct if a sprite is ever redrawn. Plain {@code int[]} in
 * and out rather than a Pixmap, so the rule can be proved headlessly against the
 * reference copies the artist supplied.
 */
final class RimMask {

    /** The outline colour. */
    private static final int CREAM = 0xfff7f0dc;
    private static final int CLEAR = 0x00000000;

    private RimMask() {
    }

    /**
     * Builds the outline of a sprite frame.
     *
     * @param argb   source pixels, row-major, alpha in the high byte
     * @param width  source width in pixels
     * @param height source height in pixels
     * @return a new array the same size: cream where the outline falls, clear elsewhere
     */
    static int[] generate(int[] argb, int width, int height) {
        int[] rim = new int[argb.length];
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int index = y * width + x;
                if (isClear(argb[index])) {
                    rim[index] = CLEAR;
                    continue;
                }
                boolean onEdge = touchesClear(argb, width, height, x - 1, y)
                        || touchesClear(argb, width, height, x + 1, y)
                        || touchesClear(argb, width, height, x, y - 1)
                        || touchesClear(argb, width, height, x, y + 1);
                rim[index] = onEdge ? CREAM : CLEAR;
            }
        }
        return rim;
    }

    /**
     * Whether the neighbour at {@code (x, y)} is transparent. Off the edge of
     * the image counts as transparent, so a sprite drawn flush against its
     * bounding box is still outlined there — the delivered art relies on this;
     * the Ace differs by 38 pixels between the two conventions.
     */
    private static boolean touchesClear(int[] argb, int width, int height, int x, int y) {
        if (x < 0 || y < 0 || x >= width || y >= height) {
            return true;
        }
        return isClear(argb[y * width + x]);
    }

    /** Anything with no alpha at all; the art is binary, but do not assume it. */
    private static boolean isClear(int argb) {
        return (argb >>> 24) == 0;
    }
}
