package dev.meowpow.boxbot.config;

import java.util.Objects;

/**
 * The tunable behavior of a simulation run.
 *
 * @param seed seed for level generation randomness
 * @param timing fixed-step simulation pacing
 * @param warehouse warehouse constraints
 * @param demand inbound stock and outbound shipment demand
 * @param input player input constraints
 * @param ui UI display tuning
 */
public record BoxbotConfig(
        long seed,
        TimingConfig timing,
        WarehouseConfig warehouse,
        DemandConfig demand,
        InputConfig input,
        UiConfig ui
) {

    /**
     * @throws NullPointerException if any argument is null
     */
    public BoxbotConfig {
        Objects.requireNonNull(timing, "timing must not be null");
        Objects.requireNonNull(warehouse, "warehouse must not be null");
        Objects.requireNonNull(demand, "demand must not be null");
        Objects.requireNonNull(input, "input must not be null");
        Objects.requireNonNull(ui, "ui must not be null");
    }
}
