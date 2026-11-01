package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.EquippedWeapon;
import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;

import java.util.List;

/** Builds a specific in-progress GameState so a rule can be tested in isolation. */
final class StateBuilder {

    private List<Card> dungeon = List.of();
    private List<Card> room = List.of();
    private EquippedWeapon weapon;
    private int health = 20;
    private int potionsUsed = 0;
    private int cardsResolved = 0;
    private boolean previousAvoided = false;
    private Card lastResolved;

    /**
     * A fresh builder: no dungeon, room or weapon, 20 health, nothing used or
     * resolved this turn, and the previous room not avoided.
     *
     * @return the builder
     */
    static StateBuilder state() {
        return new StateBuilder();
    }

    /**
     * Sets the face-down pile.
     *
     * @param cards the dungeon, top first
     * @return this builder
     */
    StateBuilder dungeon(Card... cards) {
        this.dungeon = List.of(cards);
        return this;
    }

    /**
     * Sets the face-up room.
     *
     * @param cards the room's cards, in order
     * @return this builder
     */
    StateBuilder room(Card... cards) {
        this.room = List.of(cards);
        return this;
    }

    /**
     * Equips a fresh weapon that has slain nothing.
     *
     * @param weaponCard the weapon card
     * @return this builder
     */
    StateBuilder weapon(Card weaponCard) {
        this.weapon = new EquippedWeapon(weaponCard);
        return this;
    }

    /**
     * Equips a weapon that has already slain these monsters.
     *
     * @param weaponCard the weapon card
     * @param slain      the monsters on it, oldest first, the last setting the limit
     * @return this builder
     */
    StateBuilder weapon(Card weaponCard, Card... slain) {
        this.weapon = new EquippedWeapon(weaponCard, List.of(slain));
        return this;
    }

    /**
     * Sets current health.
     *
     * @param health the health; no cap is applied here
     * @return this builder
     */
    StateBuilder health(int health) {
        this.health = health;
        return this;
    }

    /**
     * Sets how many potions have already healed this turn.
     *
     * @param potionsUsed the count, 0 or more
     * @return this builder
     */
    StateBuilder potionsUsed(int potionsUsed) {
        this.potionsUsed = potionsUsed;
        return this;
    }

    /**
     * Marks the room as started, one card already resolved this turn, which
     * forbids avoiding it.
     *
     * @return this builder
     */
    StateBuilder started() {
        this.cardsResolved = 1;
        return this;
    }

    /**
     * Marks the room before this one as avoided, which forbids avoiding this one.
     *
     * @return this builder
     */
    StateBuilder previousAvoided() {
        this.previousAvoided = true;
        return this;
    }

    /**
     * The state built so far: in progress, with no last-resolved card and no score.
     *
     * @return the state
     */
    GameState build() {
        return new GameState(dungeon, room, weapon, health, potionsUsed,
                cardsResolved, previousAvoided, lastResolved, Status.IN_PROGRESS, null);
    }
}
