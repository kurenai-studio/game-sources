package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;

import java.util.List;

/**
 * The outcome of applying one move: the next state plus everything that
 * happened, in order. Observers (achievements, stats, UI) read the events;
 * they are never pushed from inside core.
 *
 * @param state  the game after the move; the state passed in is left as it was
 * @param events what happened, in the order it happened; copied
 */
public record MoveResult(GameState state, List<GameEvent> events) {

    /**
     * Copies the events, so an observer holding the list can't have it change underneath it.
     *
     * @throws NullPointerException if {@code events} is null or holds a null
     */
    public MoveResult {
        events = List.copyOf(events);
    }
}
