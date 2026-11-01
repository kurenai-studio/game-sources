package com.tomer.scoundrel.model;

import java.util.ArrayList;
import java.util.List;
import java.util.OptionalInt;

/**
 * The equipped weapon plus the stack of monsters it has slain, most recent
 * last. Degradation state is derived from the stack rather than stored.
 *
 * @param weapon the weapon card itself
 * @param slain  the monsters it has killed, oldest first; copied, and empty while fresh
 */
public record EquippedWeapon(Card weapon, List<Card> slain) {

    /**
     * Copies the stack, so a weapon never shares its list with a caller.
     *
     * @throws NullPointerException if {@code slain} is null or holds a null
     */
    public EquippedWeapon {
        slain = List.copyOf(slain);
    }

    /**
     * A freshly equipped weapon that has slain nothing yet.
     *
     * @param weapon the weapon card being equipped
     */
    public EquippedWeapon(Card weapon) {
        this(weapon, List.of());
    }

    /**
     * Whether the weapon has killed anything, which is what switches degradation on.
     *
     * @return true once {@code slain} is non-empty
     */
    public boolean hasSlain() {
        return !slain.isEmpty();
    }

    /**
     * Value of the last slain monster; empty while the weapon is fresh (no limit).
     *
     * @return the exclusive upper bound on what the weapon may fight next (2–14), or empty
     */
    public OptionalInt threshold() {
        return hasSlain() ? OptionalInt.of(slain.getLast().value()) : OptionalInt.empty();
    }

    /**
     * A fresh weapon can fight anything; afterwards only monsters strictly
     * weaker than the last slain one (equal value must be fought barehanded).
     *
     * @param monster the monster being considered
     * @return whether fighting it with this weapon is allowed
     */
    public boolean canUseAgainst(Card monster) {
        return !hasSlain() || monster.value() < slain.getLast().value();
    }

    /**
     * The same weapon with one more kill on its stack; this one is unchanged.
     *
     * @param monster the monster just slain, which becomes the new threshold
     * @return a new weapon whose {@code slain} ends with {@code monster}
     */
    public EquippedWeapon withSlain(Card monster) {
        List<Card> next = new ArrayList<>(slain);
        next.add(monster);
        return new EquippedWeapon(weapon, next);
    }
}
