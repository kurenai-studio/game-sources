package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.rules.Move.FightBarehanded;
import com.tomer.scoundrel.rules.Move.FightWithWeapon;
import org.junit.jupiter.api.Test;

import java.util.List;

import static com.tomer.scoundrel.rules.Cards.monster;
import static com.tomer.scoundrel.rules.Cards.monster2;
import static com.tomer.scoundrel.rules.Cards.weapon;
import static com.tomer.scoundrel.rules.Moves.movesFor;
import static com.tomer.scoundrel.rules.StateBuilder.state;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Weapon degradation: a weapon only takes monsters weaker than the last one it slew. */
class WeaponDegradationTest {

    private final ScoundrelEngine engine = new ScoundrelEngine(Rulesets.standard());

    /** A weapon that has slain nothing can take any monster, even an Ace. */
    @Test
    void freshWeaponCanFightAnyMonsterIncludingAnAce() {
        GameState s = state().room(monster(14), weapon(3), weapon(4), weapon(6))
                .weapon(weapon(2)).build();
        assertTrue(movesFor(engine, s, monster(14)).contains(new FightWithWeapon(monster(14))));
        GameState next = engine.apply(s, new FightWithWeapon(monster(14))).state();
        assertEquals(8, next.health()); // Ace(14) - weapon 2 = 12
    }

    /** A weapon whose last kill was a Queen can still take a 6, which then joins the stack. */
    @Test
    void weaponThatSlewAQueenCanStillFightASix() {
        GameState s = state().room(monster(6), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(5), monster(12)).build();
        GameState next = engine.apply(s, new FightWithWeapon(monster(6))).state();
        assertEquals(19, next.health()); // 6 - 5 = 1
        assertEquals(List.of(monster(12), monster(6)), next.weapon().slain());
    }

    /** A monster equal to the last kill is refused, because the limit is strictly less than. */
    @Test
    void equalValueIsRejectedStrictLessThanNotLessOrEqual() {
        GameState s = state().room(monster2(6), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(5), monster(6)).build();
        assertFalse(movesFor(engine, s, monster2(6)).contains(new FightWithWeapon(monster2(6))));
        assertThrows(IllegalMoveException.class,
                () -> engine.apply(s, new FightWithWeapon(monster2(6))));
    }

    /** A monster one below the last kill is still allowed. */
    @Test
    void oneBelowTheLastSlainValueIsStillAllowed() {
        GameState s = state().room(monster2(5), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(5), monster(6)).build();
        assertTrue(movesFor(engine, s, monster2(5)).contains(new FightWithWeapon(monster2(5))));
        GameState next = engine.apply(s, new FightWithWeapon(monster2(5))).state();
        assertEquals(20, next.health());
    }

    /** A monster stronger than the last kill is refused. */
    @Test
    void strongerMonsterThanLastSlainIsRejected() {
        GameState s = state().room(monster(7), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(5), monster(6)).build();
        assertFalse(movesFor(engine, s, monster(7)).contains(new FightWithWeapon(monster(7))));
        assertThrows(IllegalMoveException.class,
                () -> engine.apply(s, new FightWithWeapon(monster(7))));
    }

    /**
     * The limit follows the latest kill rather than the first: after a Queen then
     * a 6, only monsters below 6 are allowed.
     */
    @Test
    void thresholdTracksTheLastSlainMonsterNotTheLowestOrFirst() {
        // Killed a Queen(12), then a 6: now even another 6 is rejected, only <6 remains.
        GameState s = state().room(monster2(6), monster2(5), weapon(3), weapon(4))
                .weapon(weapon(5), monster(12), monster(6)).build();
        assertFalse(movesFor(engine, s, monster2(6)).contains(new FightWithWeapon(monster2(6))));
        assertTrue(movesFor(engine, s, monster2(5)).contains(new FightWithWeapon(monster2(5))));
    }

    /** The new limit is the slain monster's value, not the damage taken. */
    @Test
    void thresholdIsTheMonstersValueNotTheDamageDealt() {
        // Weapon 5 kills a Jack(11) taking 6 damage; a 10 is still fightable (10 < 11).
        GameState s = state().room(monster(11), monster2(10), weapon(3), weapon(4))
                .weapon(weapon(5)).build();
        GameState next = engine.apply(s, new FightWithWeapon(monster(11))).state();
        assertTrue(movesFor(engine, next, monster2(10)).contains(new FightWithWeapon(monster2(10))));
    }

    /** A weapon too worn for a monster stays equipped, and bare hands are the only move offered. */
    @Test
    void unusableWeaponStaysEquippedAndBarehandedIsStillOffered() {
        GameState s = state().room(monster2(12), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(5), monster(6)).build();
        assertEquals(List.of(new FightBarehanded(monster2(12))), movesFor(engine, s, monster2(12)));
        GameState next = engine.apply(s, new FightBarehanded(monster2(12))).state();
        assertEquals(weapon(5), next.weapon().weapon());
        assertEquals(List.of(monster(6)), next.weapon().slain());
    }

    /** A bare-handed kill leaves the weapon's limit where it was. */
    @Test
    void barehandedFightDoesNotChangeTheWeaponThreshold() {
        GameState s = state().room(monster2(9), monster2(10), weapon(3), weapon(4))
                .weapon(weapon(5), monster(12)).build();
        GameState next = engine.apply(s, new FightBarehanded(monster2(9))).state();
        assertEquals(List.of(monster(12)), next.weapon().slain());
        // 10 < 12 still fightable with the weapon
        assertTrue(movesFor(engine, next, monster2(10)).contains(new FightWithWeapon(monster2(10))));
    }

    /** A weapon whose last kill was a 2 can take no monster at all, yet stays equipped. */
    @Test
    void weaponThatSlewATwoCanNeverBeUsedAgain() {
        GameState s = state().room(monster2(2), monster2(5), monster2(14), weapon(4))
                .weapon(weapon(9), monster(2)).build();
        for (var card : List.of(monster2(2), monster2(5), monster2(14))) {
            assertEquals(List.of(new FightBarehanded(card)), movesFor(engine, s, card),
                    "no weapon option for " + card.id());
        }
        GameState next = engine.apply(s, new FightBarehanded(monster2(5))).state();
        assertEquals(weapon(9), next.weapon().weapon()); // still equipped
    }
}
