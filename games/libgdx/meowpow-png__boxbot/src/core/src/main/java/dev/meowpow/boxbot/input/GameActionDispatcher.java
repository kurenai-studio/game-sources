package dev.meowpow.boxbot.input;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

/**
 * Keeps a list of listeners and calls
 * each one whenever a {@link GameAction} happens.
 */
public final class GameActionDispatcher {

    private final List<Consumer<GameAction>> listeners = new ArrayList<>();

    /**
     * Adds a listener to be called
     * whenever an action is dispatched.
     *
     * @param listener called with each dispatched action
     */
    public void addListener(Consumer<GameAction> listener) {
        listeners.add(listener);
    }

    /**
     * Stops calling the given listener when actions are dispatched.
     *
     * @param listener the listener to remove
     */
    public void removeListener(Consumer<GameAction> listener) {
        listeners.remove(listener);
    }

    /**
     * Calls every registered
     * listener with the given action.
     *
     * @param action the action to dispatch
     */
    public void dispatch(GameAction action) {
        for (Consumer<GameAction> listener : List.copyOf(listeners)) {
            listener.accept(action);
        }
    }
}
