package com.tomer.scoundrel.screens;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Random;

/**
 * The dungeon's drifting motes as a pure simulation: embers spawn near the
 * floor, rise slowly while swaying, fade in and out over their life, and are
 * culled at the end of it. No LibGDX — the {@link Backdrop} owns one, ticks it
 * in {@code advance}, and draws a soft dot per particle; the simulation is tested
 * headlessly. Deterministic given its seed. Coordinates are in world units.
 */
final class Embers {

    /** The most embers alive at once; spawning pauses at this many. */
    static final int MAX = 40;
    /** An ember's alpha at the height of its life, before the backdrop's light. */
    static final float PEAK_ALPHA = 0.55f;

    private static final float SPAWN_RATE = 5f;   // per second
    private static final float SPAWN_BAND = 110f; // spawn within this height of the floor
    private static final float FADE_IN = 0.2f;    // fraction of life spent fading in
    private static final float FADE_OUT = 0.4f;   // fraction of life spent fading out

    /** A single mote; fields are read by the Backdrop for drawing. */
    static final class Ember {
        /** Centre x, in world units; sways about where it spawned. */
        float x;
        /** Centre y, in world units, from the floor; rises over its life. */
        float y;
        /** How strongly to draw it now, 0 to {@link #PEAK_ALPHA}. */
        float alpha;
        /** Its diameter, in world units, 6 to 14. */
        float size;
        private float baseX;
        private float vy;
        private float age;
        private float life;
        private float swayAmp;
        private float swayFreq;
        private float swayPhase;

        /** Created only by the simulation's own spawn. */
        Ember() {
        }
    }

    private final List<Ember> live = new ArrayList<>();
    private final Random rng;
    private float spawnAccumulator;

    /**
     * An empty simulation; embers start spawning on the first update.
     *
     * @param seed the generator's seed; the same seed drifts the same embers
     */
    Embers(long seed) {
        this.rng = new Random(seed);
    }

    /**
     * Spawns, moves, fades and culls.
     *
     * @param dt seconds since the last update
     */
    void update(float dt) {
        if (live.size() < MAX) {
            spawnAccumulator += dt * SPAWN_RATE;
        }
        while (spawnAccumulator >= 1f && live.size() < MAX) {
            spawnAccumulator -= 1f;
            spawn();
        }
        for (Iterator<Ember> it = live.iterator(); it.hasNext(); ) {
            Ember e = it.next();
            e.age += dt;
            if (e.age >= e.life) {
                it.remove();
                continue;
            }
            e.y += e.vy * dt;
            e.x = e.baseX + e.swayAmp * (float) Math.sin(e.swayPhase + e.swayFreq * e.age);
            e.alpha = fade(e.age, e.life) * PEAK_ALPHA;
        }
    }

    /**
     * The embers alive now, for drawing.
     *
     * @return the live list itself; read it, don't change it
     */
    List<Ember> particles() {
        return live;
    }

    /**
     * Ramp up over the first fraction of life, hold, ramp down over the last; in [0, 1].
     *
     * @param age  seconds since the ember spawned
     * @param life seconds it lives in all
     * @return the fade multiplier; 0 before birth and from the end of life on
     */
    static float fade(float age, float life) {
        if (age <= 0f || age >= life) {
            return 0f;
        }
        float fadeIn = Math.min(1f, age / (life * FADE_IN));
        float fadeOut = Math.min(1f, (life - age) / (life * FADE_OUT));
        return Math.min(fadeIn, fadeOut);
    }

    private void spawn() {
        Ember e = new Ember();
        e.baseX = rng.nextFloat() * Theme.WORLD_WIDTH;
        e.y = rng.nextFloat() * SPAWN_BAND;
        e.vy = range(16f, 30f);
        e.life = range(6f, 9f);
        e.size = range(6f, 14f);
        e.swayAmp = range(6f, 18f);
        e.swayFreq = range(0.5f, 1.3f);
        e.swayPhase = rng.nextFloat() * 6.2832f;
        e.x = e.baseX;
        live.add(e);
    }

    private float range(float lo, float hi) {
        return lo + rng.nextFloat() * (hi - lo);
    }
}
