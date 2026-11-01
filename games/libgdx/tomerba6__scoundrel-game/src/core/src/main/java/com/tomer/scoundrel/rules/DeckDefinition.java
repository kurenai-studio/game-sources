package com.tomer.scoundrel.rules;

import java.util.List;

/** The set of card definitions a game is played with (Factory for the dungeon). */
public interface DeckDefinition {

    /**
     * All definitions, in canonical (unshuffled) order.
     *
     * @return one definition per card in the dungeon; the engine shuffles its own copy
     */
    List<CardDefinition> cards();

    /**
     * Looks up behavior for an in-play card; ids must be unique within a deck.
     *
     * @param cardId the {@link com.tomer.scoundrel.model.Card#id() id} of an in-play card
     * @return the definition with that id
     * @throws IllegalArgumentException if no definition in this deck has that id
     */
    default CardDefinition definition(String cardId) {
        return cards().stream()
                .filter(def -> def.id().equals(cardId))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unknown card id: " + cardId));
    }
}
