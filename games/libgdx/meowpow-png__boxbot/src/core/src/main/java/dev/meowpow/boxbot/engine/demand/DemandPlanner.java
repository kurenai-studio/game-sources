package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.config.DemandCycleConfig;
import dev.meowpow.boxbot.gdx.HotPath;

import java.util.Objects;

/**
 * Sets the pace of outbound
 * order arrivals over a demand cycle.
 */
@HotPath
public final class DemandPlanner {

    private final int baseOrderIntervalTicks;
    private final DemandCycleConfig config;

    /**
     * Creates a demand planner.
     *
     * @param baseOrderIntervalTicks order interval at the cycle's average rate
     * @param config rules that shape order demand over time
     *
     * @throws IllegalArgumentException if {@code baseOrderIntervalTicks} is not positive
     * @throws NullPointerException if {@code config} is null
     */
    public DemandPlanner(int baseOrderIntervalTicks, DemandCycleConfig config) {
        if (baseOrderIntervalTicks <= 0) {
            var message = "baseOrderIntervalTicks must be > 0, got ";
            throw new IllegalArgumentException(message + baseOrderIntervalTicks);
        }
        this.baseOrderIntervalTicks = baseOrderIntervalTicks;
        this.config = Objects.requireNonNull(config, "config must not be null");
    }

    /**
     * Returns the interval until
     * the next outbound order arrives at {@code tick}.
     *
     * @param tick elapsed simulation tick
     *
     * @return a positive retrieval interval in ticks
     */
    public int orderIntervalAt(int tick) {
        int cycleLength = config.cycleLengthTicks();
        int halfCycle = cycleLength / 2;
        int phase = Math.floorMod(tick, cycleLength);

        double minimumRateFactor = config.minimumRateFactor();
        double factorRange = config.maximumRateFactor() - minimumRateFactor;
        double rateFactor;

        if (phase < halfCycle) {
            double progress = (double) phase / halfCycle;
            rateFactor = minimumRateFactor + factorRange * progress;
        }
        else {
            double progress = (double) (phase - halfCycle) / halfCycle;
            rateFactor = config.maximumRateFactor() - factorRange * progress;
        }
        int interval = (int) Math.round(baseOrderIntervalTicks / rateFactor);
        return Math.max(1, interval);
    }
}
