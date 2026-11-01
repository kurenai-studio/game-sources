package dev.luchoc.littlespaceship.core.application;

import dev.luchoc.littlespaceship.core.port.InputFrame;

/**
 * Whatever the fixed-step loop advances.
 *
 * <p>It exists so the loop can be tested without a simulation behind it, and so the presentation
 * layer can wrap the simulation --to pause it, to record it-- without a single change in the core.
 */
@FunctionalInterface
public interface TickHandler {

    /**
     * Advances one tick.
     *
     * @param step seconds elapsed, always the same fixed value
     * @param input what the player asked for during this tick
     */
    void tick(float step, InputFrame input);
}
