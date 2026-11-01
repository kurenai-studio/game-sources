package dev.meowpow.boxbot.engine.time;

import dev.meowpow.boxbot.gdx.HotPath;

/**
 * An interpolation fraction between 0 and 1.
 */
@HotPath
public final class Alpha {

    private float value;

    /**
     * Creates an alpha fixed at the given value.
     *
     * @param value the interpolation fraction
     *
     * @throws IllegalArgumentException if {@code value} is not in [0, 1]
     */
    public Alpha(float value) {
        set(value);
    }

    /**
     * Returns the current interpolation fraction.
     */
    public float value() {
        return value;
    }

    /**
     * Overwrites the current interpolation fraction.
     *
     * @param value the new fraction
     *
     * @throws IllegalArgumentException if {@code value} is not in [0, 1]
     */
    void set(float value) {
        if (Float.isNaN(value) || value < 0f || value > 1f) {
            throw new IllegalArgumentException("value must be in [0, 1], got " + value);
        }
        this.value = value;
    }
}
