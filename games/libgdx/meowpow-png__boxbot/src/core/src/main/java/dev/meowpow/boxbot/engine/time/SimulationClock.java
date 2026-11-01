package dev.meowpow.boxbot.engine.time;

import dev.meowpow.boxbot.gdx.HotPath;

/**
 * Tracks elapsed simulation ticks and playtime.
 */
@HotPath
public final class SimulationClock {

    private int currentTick;
    private float elapsedSeconds;

    /**
     * Returns the current simulation tick.
     */
    public int currentTick() {
        return currentTick;
    }

    /**
     * Advances the simulation clock by one tick.
     */
    public void advance() {
        currentTick++;
    }

    /**
     * Returns the elapsed real playtime, in seconds.
     * <p>
     * <strong>Implementation Note:</strong>
     * This tracks real frame time directly rather than deriving
     * from {@link #currentTick()}, since ticks fire at a fixed
     * cadence that doesn't evenly divide into whole seconds.
     */
    public float elapsedSeconds() {
        return elapsedSeconds;
    }

    /**
     * Advances the elapsed real playtime by {@code delta}.
     *
     * @param delta elapsed time since the last call, in seconds
     */
    public void advanceRealTime(float delta) {
        elapsedSeconds += delta;
    }

    /**
     * Resets the current tick and
     * elapsed real playtime back to zero.
     */
    public void reset() {
        currentTick = 0;
        elapsedSeconds = 0;
    }
}
