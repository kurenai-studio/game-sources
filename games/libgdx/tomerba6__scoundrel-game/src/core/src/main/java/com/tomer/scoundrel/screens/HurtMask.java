package com.tomer.scoundrel.screens;

/**
 * The frame a creature holds while it is being struck: every colour moved two
 * steps up its own ramp, with the cream outline laid on top.
 *
 * <p>Brightening along the ramp is the point. A conventional white flash blends
 * toward {@code #ffffff} and invents colours that are nowhere in the art; moving
 * to a lighter step of the same material keeps the whole frame inside the eighty
 * colours everything else is drawn from, so a struck creature still looks like
 * it belongs to the game.
 */
final class HurtMask {

    /** How far up the ramp a struck pixel moves. */
    private static final int STEPS = 2;

    private HurtMask() {
    }

    /**
     * Builds the struck frame from a base sprite frame.
     *
     * @param argb   source pixels, row-major, alpha in the high byte
     * @param width  source width in pixels
     * @param height source height in pixels
     * @return a new array the same size: the brightened sprite under its outline
     */
    static int[] generate(int[] argb, int width, int height) {
        int[] rim = RimMask.generate(argb, width, height);
        int[] hurt = new int[argb.length];
        for (int i = 0; i < argb.length; i++) {
            if ((rim[i] >>> 24) != 0) {
                hurt[i] = rim[i];
            } else if ((argb[i] >>> 24) == 0) {
                hurt[i] = 0;
            } else {
                hurt[i] = (argb[i] & 0xff000000) | Ramps.lighten(argb[i] & 0xffffff, STEPS);
            }
        }
        return hurt;
    }
}
