package com.tomer.scoundrel.screens;

/**
 * The bottle a <em>wasted</em> potion collapses into: the same pixels as the one
 * you actually drink, with the colour drained out of them.
 *
 * <p>Drained rather than greyed. Averaging a pixel's channels invents a colour
 * that appears nowhere in the art; {@link Ramps#drain} moves it sideways to the
 * bone ramp at the step it already occupied, which keeps every pixel inside the
 * eighty and keeps the light-to-dark structure intact. The bottle still looks
 * round and still reads as glass — it has simply gone dead.
 *
 * <p>Generated once at load, exactly as the hurt and rim frames are, so nothing
 * is tinted at draw time and no blend can produce an off-palette colour.
 */
final class SpentMask {

    private SpentMask() {
    }

    /**
     * Drains a potion sprite to the bone ramp.
     *
     * @param argb source pixels, row-major, alpha in the high byte
     * @return a new array the same size; transparent pixels stay transparent
     */
    static int[] generate(int[] argb) {
        int[] spent = new int[argb.length];
        for (int i = 0; i < argb.length; i++) {
            if ((argb[i] >>> 24) == 0) {
                spent[i] = 0;
            } else {
                spent[i] = (argb[i] & 0xff000000) | Ramps.drain(argb[i] & 0xffffff);
            }
        }
        return spent;
    }
}
