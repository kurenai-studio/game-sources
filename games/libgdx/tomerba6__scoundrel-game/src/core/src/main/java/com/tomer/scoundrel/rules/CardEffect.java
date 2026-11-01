package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.GameState;

import java.util.List;

/**
 * A card's behavior (Strategy). The engine never switches on suit or type:
 * it asks the effect which moves the card offers, and dispatches resolution
 * to the effect via a {@link ResolutionContext}.
 */
public interface CardEffect {

    /**
     * The moves this card offers the player in the given state.
     *
     * @param card  a card in the current room whose definition carries this effect
     * @param state the game as it stands, still in progress
     * @return at least one move, each targeting {@code card}
     */
    List<Move> legalMoves(Card card, GameState state);

    /**
     * Apply the chosen move's consequences to the in-flight resolution.
     *
     * @param move one of the moves {@link #legalMoves} offered for its target card
     * @param ctx  the working copy to change and to emit this move's events into
     * @throws IllegalMoveException an implementation may throw it when handed a kind of move
     *                              it never offers; the engine validates first, so never does
     */
    void resolve(Move.CardMove move, ResolutionContext ctx);
}
