package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.EquippedWeapon;
import com.tomer.scoundrel.model.GameState;

import java.util.ArrayList;
import java.util.List;

/**
 * Mutable working copy of the parts of the state a card effect may change.
 * Created by the engine for a single {@code apply} call and never escapes it;
 * the engine reads the results back into the next immutable GameState.
 */
public final class ResolutionContext {

    private final Ruleset rules;
    private int health;
    private EquippedWeapon weapon;
    private int potionsUsedThisRoom;
    private final List<GameEvent> events = new ArrayList<>();

    /**
     * A working copy seeded from the state a move is applied to.
     *
     * @param rules the ruleset in play, for the cap and allowances an effect checks
     * @param state the state before the move; read once, never written
     */
    ResolutionContext(Ruleset rules, GameState state) {
        this.rules = rules;
        this.health = state.health();
        this.weapon = state.weapon();
        this.potionsUsedThisRoom = state.potionsUsedThisRoom();
    }

    /**
     * The ruleset in play.
     *
     * @return the same ruleset the engine was built with
     */
    public Ruleset rules() {
        return rules;
    }

    /**
     * Health as changed so far by this move.
     *
     * @return current health; may be zero or below after {@link #damage}
     */
    public int health() {
        return health;
    }

    /**
     * Null when nothing is equipped.
     *
     * @return the equipped weapon as changed so far by this move, or null
     */
    public EquippedWeapon weapon() {
        return weapon;
    }

    /**
     * Potions that have healed this turn, including one this move just took.
     *
     * @return the count so far, to compare against {@link Ruleset#potionsPerTurn()}
     */
    public int potionsUsedThisRoom() {
        return potionsUsedThisRoom;
    }

    /**
     * Health may go below zero; the loss score needs the raw value.
     *
     * @param amount health to take away, 0 or more
     */
    public void damage(int amount) {
        health -= amount;
    }

    /**
     * Heals up to the ruleset's health cap; returns the amount actually healed.
     *
     * @param amount the most health to restore, 0 or more
     * @return how much was restored: {@code amount}, less whatever the cap cut off
     */
    public int heal(int amount) {
        int healed = Math.min(amount, Math.max(0, rules.healthCap() - health));
        health += healed;
        return healed;
    }

    /**
     * Equips a fresh weapon; the previous weapon and its stack are discarded.
     *
     * @param weaponCard the weapon card being taken
     */
    public void equip(Card weaponCard) {
        weapon = new EquippedWeapon(weaponCard);
    }

    /**
     * Stacks a monster on the equipped weapon, which degrades the weapon to it.
     *
     * @param monster the monster just killed with the weapon
     * @throws NullPointerException if nothing is equipped
     */
    public void slayWithWeapon(Card monster) {
        weapon = weapon.withSlain(monster);
    }

    /** Counts one potion against the turn's allowance; call it only for a potion that healed. */
    public void notePotionTaken() {
        potionsUsedThisRoom++;
    }

    /**
     * Records something that happened, to be returned in the move's result.
     *
     * @param event the event, appended after any this move already emitted
     */
    public void emit(GameEvent event) {
        events.add(event);
    }

    /**
     * Everything emitted so far, for the engine to read back.
     *
     * @return the live list, in emission order
     */
    List<GameEvent> events() {
        return events;
    }
}
