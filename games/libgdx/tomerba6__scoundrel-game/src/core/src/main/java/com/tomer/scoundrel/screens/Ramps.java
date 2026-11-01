package com.tomer.scoundrel.screens;

import java.util.HashMap;
import java.util.Map;

/**
 * The colour system the art is drawn on: nine eight-step material ramps plus a
 * row of accents, eighty colours, and nothing else appears in any sprite.
 *
 * <p>Held here so effects can move a colour <em>along its own ramp</em> rather
 * than blending toward white. That is what keeps a flash inside the palette:
 * brightening a pixel means picking a lighter step of the same material, not
 * lightening its RGB.
 */
final class Ramps {

    /** How many steps each ramp has, darkest first. */
    static final int STEPS = 8;

    private static final String[] TABLE = {
        // FUR — pelts, mange
        "0a080d 17111a 261a22 3a2a26 52402c 6f5738 8f7248 b09263",
        // FLESH — skin, meat
        "12060f 230d16 37131c 4f1d1e 6b2b23 8a3d2b a85338 c47049",
        // BONE — bone, dead skin, cloth
        "12101c 221f2c 383341 524a4c 6f6558 8f8368 b3a683 e6dcc0",
        // CHITIN — carapace, membrane
        "08070f 14101e 221a30 332643 453356 5b4569 74597e 91738f",
        // SALLOW — green-grey hide
        "0f0f14 1b1e1e 282f26 37422c 485834 5c6f3c 748845 93a457",
        // IRON — steel, plate
        "090c14 141a24 212b36 333f4c 4a5a66 667a86 8a9ea8 b2c6cd",
        // WOOD — hafts, planks, clay
        "100a07 1e140d 2f2014 422e1b 573c23 6e4f2e 8a6539 a67f4a",
        // ROT — clubs corruption
        "0e1a12 17281a 234026 325a31 43783c 58964a 71b45c 8fcf72",
        // COLD — spades corruption
        "101a20 1a2b33 263f49 35555f 487078 618c92 80a8ac a3c4c6",
        // ACCENT — torch, blood, cream
        "d9a441 f2cf7a ffe9b0 b5651f 8c2f22 c2503a e8ddc7 f7f0dc",
    };

    /** rgb -> the ramp it belongs to and its index within it. */
    private static final Map<Integer, int[]> LOOKUP = new HashMap<>();
    private static final int[][] RAMPS = new int[TABLE.length][STEPS];

    static {
        for (int r = 0; r < TABLE.length; r++) {
            String[] hexes = TABLE[r].split(" ");
            for (int i = 0; i < hexes.length; i++) {
                int rgb = Integer.parseInt(hexes[i], 16);
                RAMPS[r][i] = rgb;
                // No colour appears in two ramps, so first write wins is exact.
                LOOKUP.putIfAbsent(rgb, new int[] {r, i});
            }
        }
    }

    private Ramps() {
    }

    /**
     * Every colour in the system, for checks that nothing strays outside it.
     *
     * @param rgb the colour as {@code 0xRRGGBB}, no alpha
     * @return true if it is one of the eighty
     */
    static boolean contains(int rgb) {
        return LOOKUP.containsKey(rgb);
    }

    /**
     * How many distinct colours the ramps hold.
     *
     * @return the number of colours: eighty, unless the table is edited
     */
    static int size() {
        return LOOKUP.size();
    }

    /**
     * The colour {@code steps} lighter along its own ramp, clamped at the
     * lightest step.
     *
     * <p>Six of the twenty-six creatures are not fully on the ramps — the Ace
     * was installed verbatim at 51–64 tones, and the goblin and the knight had
     * only one part of each remapped. Those pixels are matched to their nearest
     * ramp colour first. Leaving them alone instead would be the safer-looking
     * choice and the wrong one: 92% of the Ace would not change, so being
     * struck would barely show on it.
     *
     * @param rgb   the colour as {@code 0xRRGGBB}, on a ramp or not
     * @param steps how many steps lighter, 0 or more
     * @return a colour on the ramps, as {@code 0xRRGGBB}
     */
    static int lighten(int rgb, int steps) {
        int[] found = LOOKUP.get(rgb);
        if (found == null) {
            found = nearest(rgb);
        }
        return RAMPS[found[0]][Math.min(STEPS - 1, found[1] + steps)];
    }

    /**
     * The same colour with the material drained out of it: the step it already
     * occupies, taken from the bone ramp instead of its own.
     *
     * <p>Not a greyscale conversion. Averaging the channels would invent a
     * colour that is nowhere in the art; moving sideways to bone at the same
     * step keeps the pixel inside the eighty and preserves how light or dark it
     * was, so a drained sprite still has all of its shading.
     *
     * @param rgb the colour as {@code 0xRRGGBB}, on a ramp or not
     * @return the bone ramp's colour at the same step, as {@code 0xRRGGBB}
     */
    static int drain(int rgb) {
        int[] found = LOOKUP.get(rgb);
        if (found == null) {
            found = nearest(rgb);
        }
        return RAMPS[BONE][found[1]];
    }

    /** The bone ramp's row in {@link #TABLE} — the near-neutral one. */
    private static final int BONE = 2;

    /** Closest ramp entry by squared RGB distance. */
    private static int[] nearest(int rgb) {
        int r = (rgb >> 16) & 0xff;
        int g = (rgb >> 8) & 0xff;
        int b = rgb & 0xff;
        int[] best = {0, 0};
        long bestDistance = Long.MAX_VALUE;
        for (int ramp = 0; ramp < RAMPS.length; ramp++) {
            for (int i = 0; i < STEPS; i++) {
                int candidate = RAMPS[ramp][i];
                long dr = r - ((candidate >> 16) & 0xff);
                long dg = g - ((candidate >> 8) & 0xff);
                long db = b - (candidate & 0xff);
                long distance = dr * dr + dg * dg + db * db;
                if (distance < bestDistance) {
                    bestDistance = distance;
                    best = new int[] {ramp, i};
                }
            }
        }
        return best;
    }
}
