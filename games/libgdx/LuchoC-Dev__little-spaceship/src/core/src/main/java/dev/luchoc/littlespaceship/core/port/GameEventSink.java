package dev.luchoc.littlespaceship.core.port;

import dev.luchoc.littlespaceship.core.domain.event.GameEvent;

/**
 * Where the simulation drops what happened, for the layers that react to it.
 *
 * <p>Audio, HUD, particles and camera shakes hook in here. The core does not know sound exists, so
 * adding an effect changes no game rule.
 *
 * <p>Events are drained after the tick, never in the middle of one. A sink that called back into
 * the simulation would reorder the systems, and their order is a game rule.
 */
public interface GameEventSink {

    /**
     * Receives one event. Called once per event and always outside the systems' execution.
     *
     * @param event what happened, immutable
     */
    void emit(GameEvent event);
}
