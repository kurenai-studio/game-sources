package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Dying: a red flare over the killer, the board shaking, the screen going out
 * by ordered dither, and YOU DIED growing in.
 *
 * <p>The dither is a <b>pattern, never an alpha fade</b> — the board stays
 * legible through it as it thins out, which is what makes the death read as the
 * screen failing rather than a dialog dimming the game behind it.
 */
class DeathCinematicTest {

    private static final float FRAME = 1f / 12f;

    /** The death flares first, then the dither starts, then the title appears. */
    @Test
    void thePhasesRunInOrder() {
        assertTrue(DeathCinematic.flaring(0f), "the blow flares first");
        assertEquals(0, DeathCinematic.ditherLevel(0f), "nothing has gone dark yet");
        assertFalse(DeathCinematic.titleShowing(0f), "and the title is not up");

        assertTrue(DeathCinematic.ditherLevel(DeathCinematic.DITHER_START) > 0);
        assertTrue(DeathCinematic.titleShowing(DeathCinematic.TITLE_START));
        assertFalse(DeathCinematic.titleShowing(DeathCinematic.TITLE_START - FRAME));
    }

    /** The board shakes in multiples of 4px, then settles. */
    @Test
    void theBoardShakesOnAWholePixelGridThenStops() {
        boolean moved = false;
        for (float t = 0f; t < DeathCinematic.TOTAL; t += 0.004f) {
            int x = DeathCinematic.shakeX(t);
            assertEquals(0, x % 4, "shake off the 4px grid at t=" + t);
            moved |= x != 0;
        }
        assertTrue(moved, "the board never shook");
        assertEquals(0, DeathCinematic.shakeX(DeathCinematic.TOTAL), "and it settles");
    }

    /**
     * The dither climbs one step at a time to full, and never overshoots the
     * pattern it is drawn from.
     */
    @Test
    void theDitherClimbsToFullAndStops() {
        assertEquals(0, DeathCinematic.ditherLevel(0f));
        int previous = -1;
        for (float t = 0f; t <= DeathCinematic.TOTAL; t += 0.004f) {
            int level = DeathCinematic.ditherLevel(t);
            assertTrue(level >= previous, "the screen got lighter again at t=" + t);
            assertTrue(level <= DeathCinematic.DITHER_LEVELS,
                    "level " + level + " is past the pattern");
            previous = level;
        }
        assertEquals(DeathCinematic.DITHER_LEVELS, DeathCinematic.ditherLevel(DeathCinematic.TOTAL));
    }

    /** Midway through the dither, the pattern is partial. */
    @Test
    void theBoardIsStillVisibleWhileTheDitherIsClimbing() {
        // Partway through, some of the pattern is on and some is off -- that is
        // what a dither is. A fade would have one value covering everything.
        float midway = DeathCinematic.DITHER_START
                + (DeathCinematic.DITHER_END - DeathCinematic.DITHER_START) / 2f;
        int level = DeathCinematic.ditherLevel(midway);
        assertTrue(level > 0 && level < DeathCinematic.DITHER_LEVELS,
                "expected a partial pattern midway, got " + level);
    }

    /**
     * Every step is a whole multiple of the face it is drawn from. Silkscreen
     * is a 1-bit face rendered at 1:1 with nearest filtering, so a fractional
     * scale resamples it: whole rows of pixels vanish, and identical stems land
     * on one screen pixel or two depending where each glyph falls.
     */
    @Test
    void everyTitleStepIsAWholeMultipleOfTheFace() {
        for (float t = DeathCinematic.TITLE_START; t < DeathCinematic.TOTAL; t += 0.004f) {
            assertTrue(DeathCinematic.titleZoom(t) >= 1,
                    "zoom fell below 1:1 at t=" + t);
        }
    }

    /**
     * Fifteen steps, and one of them every single frame. At 12fps that is as
     * smooth as anything in this game can be — any hold longer than a frame is a
     * visible stutter.
     *
     * <p>Holding the first steps several frames apiece, while they are also the
     * largest jumps in the run, is precisely the recipe for a lurch: dwell on a
     * size, then leap.
     */
    @Test
    void theTitleTakesAStepEveryFrame() {
        int previous = -1;
        for (int frame = 0; frame < 15; frame++) {
            int zoom = DeathCinematic.titleZoom(DeathCinematic.TITLE_START + frame * FRAME);
            assertTrue(zoom > previous,
                    "the title paused at frame " + frame + " (zoom " + zoom + ")");
            previous = zoom;
        }
    }

    /** The title grows through fifteen sizes. */
    @Test
    void theTitleGrowsInFifteenSteps() {
        Set<Integer> zooms = new LinkedHashSet<>();
        for (float t = DeathCinematic.TITLE_START; t < DeathCinematic.TOTAL; t += 0.004f) {
            zooms.add(DeathCinematic.titleZoom(t));
        }
        assertEquals(15, zooms.size(), "expected fifteen steps, got " + zooms);
    }

    /** The title never shrinks. */
    @Test
    void theTitleOnlyEverGrows() {
        int previous = 0;
        for (float t = DeathCinematic.TITLE_START; t < DeathCinematic.TOTAL; t += 0.004f) {
            int zoom = DeathCinematic.titleZoom(t);
            assertTrue(zoom >= previous, "the title shrank at t=" + t);
            previous = zoom;
        }
        assertTrue(previous > DeathCinematic.titleZoom(DeathCinematic.TITLE_START),
                "it never grew at all");
    }

    /**
     * No single step is a lurch. The jump that matters is the <em>first</em>,
     * because at the small end one whole multiple is a large fraction of the
     * size — which is exactly why the title is drawn from the smallest face
     * there is rather than a comfortable one. From the display face the first
     * step would be a third larger in one go.
     */
    @Test
    void noSingleStepIsALurch() {
        int previous = DeathCinematic.titleZoom(DeathCinematic.TITLE_START);
        float worst = 1f;
        for (int frame = 1; frame < 15; frame++) {
            int zoom = DeathCinematic.titleZoom(DeathCinematic.TITLE_START + frame * FRAME);
            worst = Math.max(worst, zoom / (float) previous);
            previous = zoom;
        }
        assertTrue(worst <= 1.21f,
                "biggest jump was " + Math.round((worst - 1) * 100) + "%");
    }

    /** Every value holds for a whole frame. */
    @Test
    void everyValueHoldsForAWholeFrame() {
        for (int frame = 0; frame < 66; frame++) {
            Set<String> seen = new LinkedHashSet<>();
            for (float within = 0f; within < FRAME - 1e-4f; within += 0.004f) {
                float t = frame * FRAME + within;
                seen.add(DeathCinematic.shakeX(t) + "|" + DeathCinematic.ditherLevel(t)
                        + "|" + DeathCinematic.titleZoom(t) + "|" + DeathCinematic.flaring(t)
                        + "|" + DeathCinematic.torchLight(t) + "|"
                        + DeathCinematic.tickerShowing(t));
            }
            assertEquals(1, seen.size(), "values slid within frame " + frame + ": " + seen);
        }
    }

    /**
     * The board is left standing for a beat before anything takes it away. The
     * blow lands, the board shakes, and then nothing happens at all — long
     * enough to read the empty bar and the number under zero. A death that
     * wiped the board in half a second would never let the loss register.
     */
    @Test
    void theBoardIsLeftStandingBeforeTheDarkTakesIt() {
        float frame = 1f / 12f;
        assertEquals(15 * frame, DeathCinematic.DITHER_START, 1e-6f);
        assertTrue(DeathCinematic.torchLight(DeathCinematic.DITHER_START - frame) >= 1f,
                "the torch should still be full while the board sits");
        assertEquals(0, DeathCinematic.ditherLevel(DeathCinematic.DITHER_START - frame),
                "nothing should have gone dark yet");
    }

    /**
     * The torch gutters rather than fading. A smooth ramp reads as a dimmer
     * switch; a flame going out flares and sinks and flares again, and only
     * trends downward. Every value is held a whole frame like everything else.
     */
    @Test
    void theTorchGuttersOutRatherThanFading() {
        assertEquals(1f, DeathCinematic.torchLight(0f), 1e-6f);
        assertEquals(0f, DeathCinematic.torchLight(DeathCinematic.TITLE_START), 1e-6f);
        float frame = 1f / 12f;
        boolean recovered = false;
        float previous = 1f;
        for (float t = DeathCinematic.DITHER_START; t < DeathCinematic.DITHER_END; t += frame) {
            float light = DeathCinematic.torchLight(t);
            assertTrue(light >= 0f && light <= 1f, "light left its range at t=" + t);
            if (light > previous) {
                recovered = true;
            }
            previous = light;
        }
        assertTrue(recovered, "the flame never flared back — that is a fade, not a gutter");
        assertTrue(DeathCinematic.torchLight(DeathCinematic.DITHER_END - frame) < 0.1f,
                "it should be all but out by the end");
    }

    /**
     * The depth ticker outlives the board. Everything else thins into the dark,
     * but the gauge you watched all run stays lit — so the last thing on screen
     * is how close you got — and then it goes too, leaving a beat of nothing
     * before the title.
     */
    @Test
    void theDepthTickerIsTheLastThingToGoOut() {
        assertTrue(DeathCinematic.tickerShowing(DeathCinematic.DITHER_END),
                "the ticker should survive the dither");
        assertTrue(DeathCinematic.tickerShowing(
                        DeathCinematic.DITHER_END + 4 * (1f / 12f)),
                "and hold alone in the dark for a beat");
        assertFalse(DeathCinematic.tickerShowing(DeathCinematic.TITLE_START),
                "but be gone before the title");
        // A gap of pure dark between the two, so they are not one movement.
        assertFalse(DeathCinematic.tickerShowing(DeathCinematic.TITLE_START - (1f / 12f)));
    }

    /** The title appears between 3.2s and 3.6s, and the death ends between 5.3s and 5.7s. */
    @Test
    void theWholeDeathIsSlowButStillEnds() {
        assertTrue(DeathCinematic.TITLE_START > 3.2f && DeathCinematic.TITLE_START < 3.6f,
                "expected the title at ~3.4s, was " + DeathCinematic.TITLE_START);
        assertTrue(DeathCinematic.TOTAL > 5.3f && DeathCinematic.TOTAL < 5.7f,
                "expected ~5500ms, was " + DeathCinematic.TOTAL);
        assertTrue(DeathCinematic.finished(DeathCinematic.TOTAL));
        assertFalse(DeathCinematic.finished(DeathCinematic.TOTAL - 0.01f));
    }
}
