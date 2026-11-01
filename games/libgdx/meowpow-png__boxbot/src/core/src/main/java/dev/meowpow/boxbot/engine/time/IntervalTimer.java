package dev.meowpow.boxbot.engine.time;

import dev.meowpow.boxbot.gdx.HotPath;

/**
 * Fires once every {@code intervalTicks} ticks.
 */
@HotPath
public final class IntervalTimer {

    private final int intervalTicks;
    private int elapsedTicks;

    /**
     * @param intervalTicks ticks between firings
     *
     * @throws IllegalArgumentException if {@code intervalTicks} is not positive
     */
    public IntervalTimer(int intervalTicks) {
        if (intervalTicks <= 0) {
            throw new IllegalArgumentException("intervalTicks must be > 0, got " + intervalTicks);
        }
        this.intervalTicks = intervalTicks;
    }

    /**
     * Advances the timer by one tick.
     *
     * @return true if the interval has elapsed, resetting the timer; false otherwise
     */
    public boolean advance() {
        elapsedTicks++;
        if (elapsedTicks < intervalTicks) {
            return false;
        }
        elapsedTicks = 0;
        return true;
    }

    /**
     * Returns how many ticks remain before the interval elapses.
     */
    public int ticksRemaining() {
        return intervalTicks - elapsedTicks;
    }
}
