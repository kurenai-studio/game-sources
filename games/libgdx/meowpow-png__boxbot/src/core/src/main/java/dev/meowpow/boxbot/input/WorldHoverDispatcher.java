package dev.meowpow.boxbot.input;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.function.Consumer;

/**
 * Keeps a list of listeners and calls
 * each one whenever the player moves the pointer.
 * <p>
 * <strong>Implementation Note:</strong>
 * Backed by a copy-on-write list since hovers
 * dispatch far more often than listeners are added
 * or removed, so dispatch needs no defensive copy.
 */
public final class WorldHoverDispatcher {

    private final List<Consumer<WorldHover>> listeners = new CopyOnWriteArrayList<>();

    /**
     * Adds a listener to be called
     * whenever a hover is dispatched.
     *
     * @param listener called with each dispatched hover
     */
    public void addListener(Consumer<WorldHover> listener) {
        listeners.add(listener);
    }

    /**
     * Stops calling the given listener when hovers are dispatched.
     *
     * @param listener the listener to remove
     */
    public void removeListener(Consumer<WorldHover> listener) {
        listeners.remove(listener);
    }

    /**
     * Calls every registered
     * listener with the given hover.
     *
     * @param hover the hover to dispatch
     */
    public void dispatch(WorldHover hover) {
        for (Consumer<WorldHover> listener : listeners) {
            listener.accept(hover);
        }
    }
}
