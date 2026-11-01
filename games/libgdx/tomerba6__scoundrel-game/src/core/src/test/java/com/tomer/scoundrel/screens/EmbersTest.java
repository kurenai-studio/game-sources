package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The drifting embers: their fade over a life, and a field that stays bounded,
 * rises, and repeats for a seed.
 */
class EmbersTest {

    private static final float DT = 1f / 60f;

    private static Embers run(long seed, float seconds) {
        Embers embers = new Embers(seed);
        for (float t = 0; t < seconds; t += DT) {
            embers.update(DT);
        }
        return embers;
    }

    // --- the fade curve (pure) ---

    /** An ember's fade is zero at birth and at death. */
    @Test
    void fadeIsZeroAtBirthAndDeath() {
        assertEquals(0f, Embers.fade(0f, 10f));
        assertEquals(0f, Embers.fade(10f, 10f));
    }

    /** An ember's fade rises early, falls late, and stays between 0 and 1. */
    @Test
    void fadeRisesThenFallsAndStaysWithinUnit() {
        assertTrue(Embers.fade(1f, 10f) < Embers.fade(3f, 10f), "should be fading in early");
        assertTrue(Embers.fade(7f, 10f) > Embers.fade(9f, 10f), "should be fading out late");
        for (float age = 0; age <= 10; age += 0.05f) {
            float f = Embers.fade(age, 10f);
            assertTrue(f >= 0f && f <= 1f, "fade " + f + " out of unit range at age=" + age);
        }
    }

    // --- the emitter (stochastic but deterministic per seed) ---

    /** Over a minute the embers never pass the maximum, and some are still alive at the end. */
    @Test
    void countStaysBoundedYetTheSystemSustainsEmbers() {
        Embers embers = new Embers(1);
        int maxSeen = 0;
        for (int i = 0; i < 3600; i++) { // a full minute
            embers.update(DT);
            maxSeen = Math.max(maxSeen, embers.particles().size());
        }
        assertTrue(maxSeen <= Embers.MAX, "exceeded MAX: " + maxSeen);
        assertTrue(embers.particles().size() > 0, "the system should keep some embers alive");
    }

    /** After ten seconds, embers have risen well above the band they spawn in. */
    @Test
    void embersDriftUpwardFromTheSpawnBand() {
        float maxY = 0;
        for (Embers.Ember e : run(3, 10).particles()) {
            maxY = Math.max(maxY, e.y);
        }
        assertTrue(maxY > 200, "embers should rise well above the spawn band, got " + maxY);
    }

    /** Every ember's alpha stays between 0 and the peak. */
    @Test
    void everyEmberAlphaStaysWithinItsPeak() {
        for (Embers.Ember e : run(5, 15).particles()) {
            assertTrue(e.alpha >= 0f && e.alpha <= Embers.PEAK_ALPHA + 1e-4f,
                    "alpha out of range: " + e.alpha);
        }
    }

    /** The same seed gives the same embers. */
    @Test
    void sameSeedGivesTheSameField() {
        Embers a = run(7, 8);
        Embers b = run(7, 8);
        assertEquals(a.particles().size(), b.particles().size());
        if (!a.particles().isEmpty()) {
            assertEquals(a.particles().get(0).x, b.particles().get(0).x);
            assertEquals(a.particles().get(0).y, b.particles().get(0).y);
        }
    }
}
