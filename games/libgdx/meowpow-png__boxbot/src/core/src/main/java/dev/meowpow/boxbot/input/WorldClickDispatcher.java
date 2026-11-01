package dev.meowpow.boxbot.input;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

/**
 * Keeps a list of listeners and calls
 * each one whenever the player clicks in the world.
 */
public final class WorldClickDispatcher {

    private final List<Consumer<WorldClick>> listeners = new ArrayList<>();

    /**
     * Adds a listener to be called
     * whenever a click is dispatched.
     *
     * @param listener called with each dispatched click
     */
    public void addListener(Consumer<WorldClick> listener) {
        listeners.add(listener);
    }

    /**
     * Stops calling the given listener when clicks are dispatched.
     *
     * @param listener the listener to remove
     */
    public void removeListener(Consumer<WorldClick> listener) {
        listeners.remove(listener);
    }

    /**
     * Calls every registered
     * listener with the given click.
     *
     * @param click the click to dispatch
     */
    public void dispatch(WorldClick click) {
        for (Consumer<WorldClick> listener : List.copyOf(listeners)) {
            listener.accept(click);
        }
    }
}
