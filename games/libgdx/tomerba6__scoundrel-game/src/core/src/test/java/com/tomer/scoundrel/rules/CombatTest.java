package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.rules.Move.FightBarehanded;
import com.tomer.scoundrel.rules.Move.FightWithWeapon;
import com.tomer.scoundrel.rules.Move.TakeWeapon;
import org.junit.jupiter.api.Test;

import java.util.List;

import static com.tomer.scoundrel.rules.Cards.monster;
import static com.tomer.scoundrel.rules.Cards.weapon;
import static com.tomer.scoundrel.rules.Moves.movesFor;
import static com.tomer.scoundrel.rules.StateBuilder.state;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Fighting a monster bare-handed or with the weapon, and equipping a weapon. */
class CombatTest {

    private final ScoundrelEngine engine = new ScoundrelEngine(Rulesets.standard());

    /** A bare-handed fight costs the monster's full value, discards it and starts the room. */
    @Test
    void barehandedFightSubtractsFullMonsterValue() {
        GameState s = state().room(monster(7), weapon(2), weapon(3), weapon(4)).build();
        GameState next = engine.apply(s, new FightBarehanded(monster(7))).state();
        assertEquals(13, next.health());
        assertFalse(next.room().contains(monster(7)));
        assertNull(next.weapon());
        assertEquals(monster(7), next.lastResolvedCard());
        assertTrue(next.roomResolutionStarted());
    }

    /** Bare hands stay on offer beside a weapon that could take the monster. */
    @Test
    void barehandedIsOfferedEvenWithUsableWeaponEquipped() {
        GameState s = state().room(monster(7), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(9)).build();
        List<Move> moves = movesFor(engine, s, monster(7));
        assertTrue(moves.contains(new FightBarehanded(monster(7))));
        assertTrue(moves.contains(new FightWithWeapon(monster(7))));
    }

    /** An armed fight costs the monster's value less the weapon's, and stacks the monster on the weapon. */
    @Test
    void weaponFightTakesExcessDamageAndStacksTheMonster() {
        GameState s = state().room(monster(11), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(5)).build();
        GameState next = engine.apply(s, new FightWithWeapon(monster(11))).state();
        assertEquals(14, next.health()); // Jack(11) - weapon 5 = 6 damage
        assertEquals(List.of(monster(11)), next.weapon().slain());
    }

    /** A weapon stronger than the monster costs no health, and still stacks it. */
    @Test
    void strongEnoughWeaponDealsZeroDamage() {
        GameState s = state().room(monster(3), weapon(2), weapon(4), weapon(6))
                .weapon(weapon(5)).build();
        GameState next = engine.apply(s, new FightWithWeapon(monster(3))).state();
        assertEquals(20, next.health());
        assertEquals(List.of(monster(3)), next.weapon().slain());
    }

    /** A weapon equal to the monster costs no health either. */
    @Test
    void equalValuesAlsoDealZeroDamage() {
        GameState s = state().room(monster(5), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(5)).build();
        GameState next = engine.apply(s, new FightWithWeapon(monster(5))).state();
        assertEquals(20, next.health());
    }

    /** With no weapon equipped, an armed fight is neither offered nor accepted. */
    @Test
    void fightingWithNoWeaponEquippedIsIllegal() {
        GameState s = state().room(monster(7), weapon(2), weapon(3), weapon(4)).build();
        assertFalse(movesFor(engine, s, monster(7)).contains(new FightWithWeapon(monster(7))));
        assertThrows(IllegalMoveException.class,
                () -> engine.apply(s, new FightWithWeapon(monster(7))));
    }

    /** Taking a weapon replaces the equipped one, along with the monsters stacked on it. */
    @Test
    void equippingANewWeaponDiscardsTheOldOneAndItsStack() {
        GameState s = state().room(weapon(7), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(5), monster(12)).build();
        GameState next = engine.apply(s, new TakeWeapon(weapon(7))).state();
        assertEquals(weapon(7), next.weapon().weapon());
        assertEquals(List.of(), next.weapon().slain());
    }

    /** A weapon card offers exactly one move: equipping it. */
    @Test
    void equippingIsBindingTheOnlyMoveForAWeaponCard() {
        GameState s = state().room(weapon(7), monster(2), monster(3), monster(4)).build();
        assertEquals(List.of(new TakeWeapon(weapon(7))), movesFor(engine, s, weapon(7)));
    }
}
