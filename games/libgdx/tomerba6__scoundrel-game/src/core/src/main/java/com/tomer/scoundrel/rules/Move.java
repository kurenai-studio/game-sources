package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;

/**
 * A player intention, reified as data (Command pattern). Sealed so the engine
 * can switch exhaustively; new special cards normally reuse an existing move.
 */
public sealed interface Move {

    /** Scoop the whole room to the bottom of the dungeon; the only non-card move. */
    record AvoidRoom() implements Move {
    }

    /** A move that resolves one specific card in the current room. */
    sealed interface CardMove extends Move {
        /**
         * The card this move resolves.
         *
         * @return a card in the current room
         */
        Card targetCard();
    }

    /**
     * Equip a weapon from the room, discarding the old one and its stack.
     *
     * @param targetCard the weapon card to equip
     */
    record TakeWeapon(Card targetCard) implements CardMove {
    }

    /**
     * Drink a potion from the room; it heals only within the turn's allowance.
     *
     * @param targetCard the potion card to drink
     */
    record TakePotion(Card targetCard) implements CardMove {
    }

    /**
     * Fight a monster from the room with no weapon, taking its full value as damage.
     *
     * @param targetCard the monster card to fight
     */
    record FightBarehanded(Card targetCard) implements CardMove {
    }

    /**
     * Fight a monster from the room with the equipped weapon; offered only while
     * the weapon's degradation allows it.
     *
     * @param targetCard the monster card to fight
     */
    record FightWithWeapon(Card targetCard) implements CardMove {
    }
}
