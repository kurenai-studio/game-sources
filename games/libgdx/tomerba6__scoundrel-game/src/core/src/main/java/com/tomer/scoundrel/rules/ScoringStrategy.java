package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;

/** Computes the final score for a terminal state (Strategy — variants may replace it). */
public interface ScoringStrategy {

    /**
     * Called with {@code status} already set to WON or LOST, {@code score} still null.
     *
     * @param terminalState the finished game, frozen at the move that ended it
     * @param rules         the ruleset the game was played with
     * @return the final score; negative for a loss under standard scoring
     */
    int score(GameState terminalState, Ruleset rules);
}
