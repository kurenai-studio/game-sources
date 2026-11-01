package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.demand.Truck;
import dev.meowpow.boxbot.engine.time.Alpha;

import java.util.Objects;

/**
 * The simulation state HUD panels read from each frame.
 *
 * @param world the simulation's runtime state
 * @param truck the loading bay's periodic truck visitor
 * @param alpha progress into the current simulation tick
 */
public record HudState(World world, Truck truck, Alpha alpha) {

    /**
     * @throws NullPointerException if any argument is null
     */
    public HudState {
        Objects.requireNonNull(world, "world must not be null");
        Objects.requireNonNull(truck, "truck must not be null");
        Objects.requireNonNull(alpha, "alpha must not be null");
    }
}
