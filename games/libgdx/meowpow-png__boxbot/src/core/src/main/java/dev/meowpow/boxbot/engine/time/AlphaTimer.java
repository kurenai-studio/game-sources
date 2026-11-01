package dev.meowpow.boxbot.engine.time;

import dev.meowpow.boxbot.gdx.HotPath;

/**
 * Tracks progress toward a fixed
 * real-time duration, as an {@link Alpha}.
 */
@HotPath
public final class AlphaTimer {

    private final float duration;
    private final Alpha alpha = new Alpha(0f);

    private float elapsed = 0f;

    /**
     * Creates a timer that reaches
     * an alpha of 1 after the given duration.
     *
     * @param duration the time to reach an alpha of 1, in seconds
     *
     * @throws IllegalArgumentException if {@code duration} is not positive
     */
    public AlphaTimer(float duration) {
        if (Float.isNaN(duration) || duration <= 0) {
            throw new IllegalArgumentException("duration must be > 0, got " + duration);
        }
        this.duration = duration;
    }

    /**
     * Advances the timer by {@code delta}, in seconds.
     *
     * @param delta elapsed time since the last call, in seconds
     */
    public void update(float delta) {
        elapsed = Math.min(duration, elapsed + delta);
        alpha.set(elapsed / duration);
    }

    /**
     * Returns this timer's alpha.
     * <p>
     * <strong>API Note:</strong>
     * The same instance is mutated in place
     * on every {@link #update} call; read its value
     * promptly rather than retaining it across frames.
     */
    public Alpha alpha() {
        return alpha;
    }

    /**
     * Returns whether the timer has reached its full duration.
     */
    public boolean isFinished() {
        return elapsed >= duration;
    }

    /**
     * Restarts the timer from zero.
     */
    public void reset() {
        elapsed = 0f;
    }
}
