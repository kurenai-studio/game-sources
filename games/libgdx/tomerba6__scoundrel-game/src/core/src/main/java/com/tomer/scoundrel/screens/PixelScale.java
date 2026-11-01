package com.tomer.scoundrel.screens;

/**
 * How much to scale the 1280×720 design space by for a given window — the pure
 * arithmetic behind {@link PixelViewport}, kept out of the GL class so it can be
 * tested headlessly.
 *
 * <p>A plain fit-to-window scale is wrong for this art. Sprites are 64×64 drawn
 * at ×2 in world units, so one source pixel covers {@code 2 * scale} screen
 * pixels; unless that is a whole number, neighbouring source pixels are rendered
 * at different widths and the art shimmers as anything moves.
 *
 * <p>So the fit scale is snapped down to a multiple of {@code 0.5}. Half-steps
 * rather than whole ones is the point: 1920×1080 fits at exactly 1.5, which
 * already puts a source pixel on 3 whole screen pixels. Snapping to integers
 * would drop it to 1.0 and letterboxing would eat a third of the most common
 * display for no gain.
 */
final class PixelScale {

    /** Sprites draw at ×2, so half-steps of scale still land on whole pixels. */
    private static final float STEP = 0.5f;

    private PixelScale() {
    }

    /**
     * The largest clean scale that still fits {@code world} inside {@code screen}.
     * Whatever is left over becomes letterbox bars.
     *
     * @param screenWidth  the window's width, in screen pixels
     * @param screenHeight the window's height, in screen pixels
     * @param worldWidth   the design width, 1280
     * @param worldHeight  the design height, 720
     * @return a multiple of 0.5, at least 0.5; e.g. 1.5 at 1920×1080, 1.0 at 1600×900
     */
    static float forScreen(int screenWidth, int screenHeight, float worldWidth, float worldHeight) {
        return snap(Math.min(screenWidth / worldWidth, screenHeight / worldHeight));
    }

    /**
     * Rounds a fit scale down to the nearest half-step, never below one step.
     * Down rather than to-nearest, because rounding up would scale the world
     * past the window edge and crop the board.
     *
     * @param fitScale the plain fit-to-window scale
     * @return the largest multiple of 0.5 not above it, and never below 0.5
     */
    static float snap(float fitScale) {
        float snapped = (float) Math.floor(fitScale / STEP) * STEP;
        return Math.max(STEP, snapped);
    }
}
