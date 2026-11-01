package dev.meowpow.boxbot.engine.time;

import dev.meowpow.boxbot.gdx.HotPath;

/**
 * Drives a fixed-timestep tick loop from frame-delta,
 * carrying over leftover time between frames.
 */
@HotPath
public final class TickAccumulator {

    private final float tickDuration;
    private float accumulator = 0f;
    private final Alpha alpha = new Alpha(0f);

    /**
     * Creates an accumulator that fires
     * ticks every {@code tickDuration} seconds.
     *
     * @param tickDuration duration of one tick, in seconds
     *
     * @throws IllegalArgumentException if {@code tickDuration} is not positive
     */
    public TickAccumulator(float tickDuration) {
        if (Float.isNaN(tickDuration) || tickDuration <= 0) {
            var message = "tickDuration must be > 0, got " + tickDuration;
            throw new IllegalArgumentException(message);
        }
        this.tickDuration = tickDuration;
    }

    /**
     * Advances the accumulator by {@code delta}
     * and returns the number of whole tick
     * durations that have elapsed.
     *
     * @param delta elapsed time since the last call, in seconds
     *
     * @return the number of elapsed ticks
     */
    public int update(float delta) {
        accumulator += delta;

        int tickCount = 0;
        while (accumulator >= tickDuration) {
            tickCount++;
            accumulator -= tickDuration;
        }
        alpha.set(accumulator / tickDuration);
        return tickCount;
    }

    /**
     * Returns this accumulator's alpha.
     * <p>
     * <strong>API Note:</strong>
     * The same instance is mutated in place
     * on every {@link #update} call; read its value
     * promptly rather than retaining it across frames.
     */
    public Alpha alpha() {
        return alpha;
    }
}
