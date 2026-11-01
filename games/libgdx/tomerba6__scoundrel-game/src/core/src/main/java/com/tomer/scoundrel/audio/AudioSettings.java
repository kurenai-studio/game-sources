package com.tomer.scoundrel.audio;

/**
 * The player's volume: a music level and a sound level, each off or one of
 * three steps, and a mute that silences both without forgetting them.
 *
 * <p>Three steps and not a slider because the title's MUSIC and SOUND plates
 * cycle on a click, as every menu button acts; a slider is a widget this game
 * does not have. Each step is 6 dB — half the amplitude, clearly different —
 * so the quietest is still audible at −12 dB.
 *
 * <p>A setting, not progress: {@code Progress.eraseAll} never touches it.
 *
 * @param music the music level, 0 (off) to {@link #MAX_LEVEL}
 * @param sound the sound-effects level, 0 (off) to {@link #MAX_LEVEL}
 * @param muted true while M has silenced both; the levels are kept underneath
 */
public record AudioSettings(int music, int sound, boolean muted) {

    /** The loudest step: the file as mastered. Levels run 0 (off) to this. */
    public static final int MAX_LEVEL = 3;
    /** First launch: both on, the music a step below the effects. */
    public static final AudioSettings DEFAULTS = new AudioSettings(2, 3, false);
    private static final double DECIBELS_PER_STEP = 6.0;

    /**
     * Rejects a level outside the steps.
     *
     * @throws IllegalArgumentException if {@code music} or {@code sound} is below 0 or above
     *                                  {@link #MAX_LEVEL}
     */
    public AudioSettings {
        requireLevel("music", music);
        requireLevel("sound", sound);
    }

    /**
     * The music plate: up a step, and from the top back round to off. Turning it up unmutes.
     *
     * @return new settings with the music a step up (or off from the top), unmuted
     */
    public AudioSettings cycleMusic() {
        return new AudioSettings(next(music), sound, false);
    }

    /**
     * The sound plate, likewise.
     *
     * @return new settings with the sound a step up (or off from the top), unmuted
     */
    public AudioSettings cycleSound() {
        return new AudioSettings(music, next(sound), false);
    }

    /**
     * M: silence everything, or bring it back at the levels it had.
     *
     * @return new settings with {@code muted} flipped and both levels unchanged
     */
    public AudioSettings toggleMute() {
        return new AudioSettings(music, sound, !muted);
    }

    /**
     * The linear amplitude to scale music by.
     *
     * @return 0 when muted or off, else 1, ~0.50 or ~0.25 for levels 3, 2, 1
     */
    public float musicGain() {
        return muted ? 0f : gain(music);
    }

    /**
     * The linear amplitude to scale sound effects by.
     *
     * @return 0 when muted or off, else 1, ~0.50 or ~0.25 for levels 3, 2, 1
     */
    public float soundGain() {
        return muted ? 0f : gain(sound);
    }

    /**
     * 0 is silent; the top step is the file as mastered, and each step below it 6 dB quieter.
     *
     * @param level a level, 0 to {@link #MAX_LEVEL}; anything at or below 0 is silent
     * @return the linear amplitude, 0 to 1
     */
    static float gain(int level) {
        if (level <= 0) {
            return 0f;
        }
        double decibels = -DECIBELS_PER_STEP * (MAX_LEVEL - level);
        return (float) Math.pow(10.0, decibels / 20.0);
    }

    private static int next(int level) {
        return (level + 1) % (MAX_LEVEL + 1);
    }

    private static void requireLevel(String name, int level) {
        if (level < 0 || level > MAX_LEVEL) {
            throw new IllegalArgumentException(name + " level must be 0.." + MAX_LEVEL + ", got " + level);
        }
    }
}
