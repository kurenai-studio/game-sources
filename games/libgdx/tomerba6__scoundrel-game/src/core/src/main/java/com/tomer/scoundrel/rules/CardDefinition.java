package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;

/**
 * The data-driven description of a card: identity, stamped stats, and the
 * effect that gives it behavior. Adding a new card is a new definition plus
 * effect — never a change to the engine's turn loop.
 *
 * @param id     unique within its deck; the key an in-play card finds this definition by
 * @param type   the base category, stamped onto the card
 * @param value  the card's strength, stamped onto the card (2–14 for a monster, 2–10 otherwise
 *               in the standard deck)
 * @param effect what taking the card does; shared between definitions, as it holds no state
 */
public record CardDefinition(String id, CardType type, int value, CardEffect effect) {

    /**
     * The plain, serializable in-play card for this definition.
     *
     * @return a new card carrying this definition's id, type and value, but not its effect
     */
    public Card card() {
        return new Card(id, type, value);
    }
}
