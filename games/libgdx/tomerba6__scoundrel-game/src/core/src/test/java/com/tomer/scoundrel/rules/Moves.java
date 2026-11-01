package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.GameState;

import java.util.List;

/** Test shorthand for querying the engine's move surface. */
final class Moves {

    private Moves() {
    }

    /**
     * Moves the engine offers for one specific room card.
     *
     * @param engine the engine to ask
     * @param state  the state to ask about
     * @param card   the room card the moves must target
     * @return the legal card moves targeting {@code card}, in the engine's order; empty if none
     */
    static List<Move> movesFor(ScoundrelEngine engine, GameState state, Card card) {
        return engine.legalMoves(state).stream()
                .filter(m -> m instanceof Move.CardMove cm && cm.targetCard().equals(card))
                .toList();
    }
}
