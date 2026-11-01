package dev.meowpow.boxbot.engine.entity;

import dev.meowpow.boxbot.engine.spatial.grid.Footprint;

import java.util.Objects;

/**
 * The charging station's fixed location in the warehouse.
 *
 * @param footprint the station's occupied grid tiles
 */
public record ChargingStation(Footprint footprint) {

    /**
     * @throws NullPointerException if {@code footprint} is null
     */
    public ChargingStation {
        Objects.requireNonNull(footprint, "footprint must not be null");
    }
}
