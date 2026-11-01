package com.tomer.scoundrel.audio;

import java.util.List;

/**
 * The value ranges a weighted sound is split along, and where a value sits
 * inside its weight.
 *
 * <p>The weight picks the file; the pitch separates the cards that share one.
 * Three weapons share a light blade, and without the nudge a Rusted Shiv and a
 * Hatchet would be the same sound. The nudge restarts in every weight — the
 * lightest of the heavies is pitched <em>up</em> — because the weight has
 * already said "heavier" with a different file, and the nudge only has to tell
 * neighbours apart.
 *
 * <p>Values outside a scale take its nearest edge. The standard deck never deals
 * one, but a future card definition may, and it should still make a sound.
 */
enum Scale {
    /** Equip and blade: 2–4, 5–7, 8–10. */
    WEAPON(2, 4, 7, 10),
    /** Drink: 2–4, 5–7, 8–10. */
    POTION(2, 4, 7, 10),
    /** Bare-handed strike: 2–5, 6–10, and the four face cards 11–14. */
    MONSTER(2, 5, 10, 14),
    /**
     * The thud of damage a weapon let through: 1–4 light, 5 and up heavy. No
     * medium — the medium band is empty. Nothing got through (0) means no thud
     * at all, which the caller decides; 12 is the most that can get through in
     * the standard deck (an Ace against a 2).
     */
    DAMAGE(1, 4, 4, 12);

    /**
     * How far the lightest and heaviest values of a weight are pitched from the
     * middle one: ±4%. A starting value, to be tuned by ear in listening round 1.
     */
    static final float NUDGE = 0.04f;

    /** The lowest value on the scale; anything below plays as this. */
    final int min;
    /** The top of the light band, inclusive. */
    final int lightMax;
    /** The top of the medium band, inclusive; equal to {@code lightMax} when there is none. */
    final int mediumMax;
    /** The highest value on the scale; anything above plays as this. */
    final int max;

    /**
     * A scale of three bands, {@code min..lightMax}, {@code lightMax+1..mediumMax} and
     * {@code mediumMax+1..max}.
     *
     * @param min       the lowest value
     * @param lightMax  the top of the light band
     * @param mediumMax the top of the medium band; {@code lightMax} for no medium band
     * @param max       the highest value
     */
    Scale(int min, int lightMax, int mediumMax, int max) {
        this.min = min;
        this.lightMax = lightMax;
        this.mediumMax = mediumMax;
        this.max = max;
    }

    /**
     * The weights a value on this scale can land in: every one, unless the medium band is empty.
     *
     * @return the weights, lightest first; each needs its own rendered files
     */
    List<Weight> weights() {
        return mediumMax > lightMax
                ? List.of(Weight.LIGHT, Weight.MEDIUM, Weight.HEAVY)
                : List.of(Weight.LIGHT, Weight.HEAVY);
    }

    /**
     * Which band a value falls in, after clamping it to the scale.
     *
     * @param value a card value or a damage figure, any int
     * @return the weight whose file plays for it
     */
    Weight weightOf(int value) {
        int v = clamp(value);
        if (v <= lightMax) {
            return Weight.LIGHT;
        }
        return v <= mediumMax ? Weight.MEDIUM : Weight.HEAVY;
    }

    /**
     * The playback pitch for a value: 1 in the middle of its weight, higher below, lower above.
     *
     * @param value a card value or a damage figure, any int; clamped to the scale
     * @return a pitch multiplier within {@code 1 ± NUDGE}
     */
    float pitchOf(int value) {
        int v = clamp(value);
        return switch (weightOf(v)) {
            case LIGHT -> pitchWithin(v, min, lightMax);
            case MEDIUM -> pitchWithin(v, lightMax + 1, mediumMax);
            case HEAVY -> pitchWithin(v, mediumMax + 1, max);
        };
    }

    /**
     * Linear across the band, so neighbours are evenly spaced whatever its width.
     *
     * @param value a value inside the band
     * @param lo    the band's lowest value, pitched {@code 1 + NUDGE}
     * @param hi    the band's highest value, pitched {@code 1 - NUDGE}
     * @return the pitch multiplier; exactly 1 for a one-value band
     */
    static float pitchWithin(int value, int lo, int hi) {
        if (hi <= lo) {
            return 1f;
        }
        float middle = (lo + hi) / 2f;
        float half = (hi - lo) / 2f;
        return 1f + NUDGE * (middle - value) / half;
    }

    private int clamp(int value) {
        return Math.max(min, Math.min(max, value));
    }
}
