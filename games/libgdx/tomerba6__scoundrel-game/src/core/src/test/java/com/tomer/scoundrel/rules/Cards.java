package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;

/** Test shorthand for standard cards: monsters are clubs (spades via monster2). */
final class Cards {

    /** The standard 44-card deck every shorthand card is looked up in. */
    static final DeckDefinition DECK = new StandardDeck();

    private Cards() {
    }

    /**
     * A standard card by its id.
     *
     * @param id rank then suit letter, as in {@code "10D"} or {@code "QS"}
     * @return the deck's card with that id
     * @throws IllegalArgumentException if the standard deck has no card with that id
     */
    static Card card(String id) {
        return DECK.definition(id).card();
    }

    /**
     * A clubs monster.
     *
     * @param value 2 to 14; 11 to 14 are J, Q, K and A
     * @return the clubs card of that value
     * @throws IllegalArgumentException if the value is outside 2 to 14
     */
    static Card monster(int value) {
        return card(rank(value) + "C");
    }

    /**
     * A spades monster, for a second monster of a value that must not equal the
     * clubs one.
     *
     * @param value 2 to 14; 11 to 14 are J, Q, K and A
     * @return the spades card of that value
     * @throws IllegalArgumentException if the value is outside 2 to 14
     */
    static Card monster2(int value) {
        return card(rank(value) + "S");
    }

    /**
     * A weapon: the diamond of that value.
     *
     * @param value 2 to 10
     * @return the diamond of that value
     * @throws IllegalArgumentException if the value is outside 2 to 10
     */
    static Card weapon(int value) {
        return card(value + "D");
    }

    /**
     * A potion: the heart of that value.
     *
     * @param value 2 to 10
     * @return the heart of that value
     * @throws IllegalArgumentException if the value is outside 2 to 10
     */
    static Card potion(int value) {
        return card(value + "H");
    }

    private static String rank(int value) {
        return switch (value) {
            case 11 -> "J";
            case 12 -> "Q";
            case 13 -> "K";
            case 14 -> "A";
            default -> String.valueOf(value);
        };
    }
}
