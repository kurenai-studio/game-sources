package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;

import java.util.List;

/**
 * Something that happened while applying a move. Returned from
 * {@link ScoundrelEngine#apply} so achievements, stats and the UI can observe
 * the game from outside core. Deliberately not sealed: new card effects may
 * emit their own event types.
 */
public interface GameEvent {

    /**
     * A new room began: after an avoid, or when a turn ends with any card still
     * in the room. Not emitted for the first room of a game.
     *
     * @param room the whole room, any carried-over card first, then what was dealt
     *             (nothing, once the dungeon is empty); copied
     */
    record RoomDealt(List<Card> room) implements GameEvent {
        /**
         * Copies the room, so the event can be held after the engine moves on.
         *
         * @throws NullPointerException if {@code room} is null or holds a null
         */
        public RoomDealt {
            room = List.copyOf(room);
        }
    }

    /**
     * The room was scooped, unresolved, to the bottom of the dungeon.
     *
     * @param room the cards that were avoided, in room order; copied
     */
    record RoomAvoided(List<Card> room) implements GameEvent {
        /**
         * Copies the room, so the event can be held after the engine moves on.
         *
         * @throws NullPointerException if {@code room} is null or holds a null
         */
        public RoomAvoided {
            room = List.copyOf(room);
        }
    }

    /**
     * A weapon was taken and equipped, discarding the old one and its stack.
     *
     * @param weapon the weapon card now equipped
     */
    record WeaponEquipped(Card weapon) implements GameEvent {
    }

    /**
     * A monster was fought and discarded or stacked on the weapon.
     *
     * @param monster     the monster that was fought
     * @param withWeapon  true if the equipped weapon was used, false if barehanded
     * @param damageTaken the health lost, 0 or more: the monster's full value barehanded,
     *                    {@code max(0, monster − weapon)} with a weapon
     */
    record MonsterDefeated(Card monster, boolean withWeapon, int damageTaken) implements GameEvent {
    }

    /**
     * A potion was taken within the turn's allowance.
     *
     * @param potion the potion card
     * @param healed the health actually restored after the cap, 0 when already at it
     */
    record PotionUsed(Card potion, int healed) implements GameEvent {
    }

    /**
     * A potion was taken after the turn's allowance was spent, and did nothing.
     *
     * @param potion the potion card that was discarded
     */
    record PotionWasted(Card potion) implements GameEvent {
    }

    /**
     * A weapon killed a monster, lowering what it may fight next.
     *
     * @param weapon       the weapon card that was used
     * @param newThreshold the slain monster's value; the weapon can now only be used on
     *                     monsters strictly below it
     */
    record WeaponDegraded(Card weapon, int newThreshold) implements GameEvent {
    }

    /**
     * The dungeon was cleared; always the last event of the game.
     *
     * @param score the final score; positive under standard scoring
     */
    record GameWon(int score) implements GameEvent {
    }

    /**
     * Health reached zero or below; always the last event of the game.
     *
     * @param score the final score; zero or negative under standard scoring
     */
    record GameLost(int score) implements GameEvent {
    }
}
