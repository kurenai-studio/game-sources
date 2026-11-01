package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;

/**
 * Base Scoundrel scoring. Loss: raw (zero-or-negative) health minus the values
 * of monsters still in the face-down dungeon — unresolved room cards do not
 * count. Win: remaining health, or cap + potion value when finishing at
 * exactly the cap with a potion as the last resolved card (even if that heal
 * was wasted by the cap).
 */
public final class StandardScoring implements ScoringStrategy {

    /** Creates the strategy; it holds no state. */
    public StandardScoring() {
    }

    @Override
    public int score(GameState state, Ruleset rules) {
        if (state.status() == Status.LOST) {
            int monstersLeft = state.dungeon().stream()
                    .filter(card -> card.type() == CardType.MONSTER)
                    .mapToInt(Card::value)
                    .sum();
            return state.health() - monstersLeft;
        }
        Card last = state.lastResolvedCard();
        if (state.health() == rules.healthCap() && last != null && last.type() == CardType.POTION) {
            return rules.healthCap() + last.value();
        }
        return state.health();
    }
}
