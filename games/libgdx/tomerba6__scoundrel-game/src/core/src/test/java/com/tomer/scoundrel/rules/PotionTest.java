package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.rules.Move.FightBarehanded;
import com.tomer.scoundrel.rules.Move.TakePotion;
import org.junit.jupiter.api.Test;

import java.util.List;

import static com.tomer.scoundrel.rules.Cards.monster;
import static com.tomer.scoundrel.rules.Cards.potion;
import static com.tomer.scoundrel.rules.Cards.weapon;
import static com.tomer.scoundrel.rules.StateBuilder.state;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Drinking potions: the heal, the cap and the one-per-turn allowance. */
class PotionTest {

    private final ScoundrelEngine engine = new ScoundrelEngine(Rulesets.standard());

    /** The turn's first potion heals its full value and is discarded. */
    @Test
    void firstPotionHealsItsValue() {
        GameState s = state().health(10).room(potion(7), weapon(2), weapon(3), weapon(4)).build();
        GameState next = engine.apply(s, new TakePotion(potion(7))).state();
        assertEquals(17, next.health());
        assertFalse(next.room().contains(potion(7)));
        assertEquals(1, next.potionsUsedThisRoom());
    }

    /** Healing stops at the cap of 20. */
    @Test
    void healingIsCappedAt20() {
        GameState s = state().health(18).room(potion(7), weapon(2), weapon(3), weapon(4)).build();
        assertEquals(20, engine.apply(s, new TakePotion(potion(7))).state().health());
    }

    /** A heal that lands exactly on 20 is not cut short. */
    @Test
    void healingToExactly20IsFine() {
        GameState s = state().health(18).room(potion(2), weapon(3), weapon(4), weapon(5)).build();
        assertEquals(20, engine.apply(s, new TakePotion(potion(2))).state().health());
    }

    /** A second potion in the same turn heals nothing, and is discarded anyway. */
    @Test
    void secondPotionInTheSameRoomHealsNothing() {
        GameState s = state().health(10).room(potion(7), potion(3), weapon(2), weapon(4)).build();
        GameState afterFirst = engine.apply(s, new TakePotion(potion(7))).state();
        assertEquals(17, afterFirst.health());
        GameState afterSecond = engine.apply(afterFirst, new TakePotion(potion(3))).state();
        assertEquals(17, afterSecond.health());
        assertFalse(afterSecond.room().contains(potion(3))); // discarded anyway
    }

    /** A wasted potion still uses up one of the turn's three resolutions. */
    @Test
    void wastedPotionsStillCountAsResolvedCards() {
        // Room: three potions + a weapon; wasted second/third potions must consume
        // resolution slots, so after taking all three the turn is over and refilled.
        GameState g = engine.newGame(List.of(
                potion(7), potion(3), potion(5), weapon(9),
                monster(2), monster(3), monster(4)));
        g = engine.apply(g, new TakePotion(potion(7))).state();
        g = engine.apply(g, new TakePotion(potion(3))).state();
        g = engine.apply(g, new TakePotion(potion(5))).state();
        assertEquals(List.of(weapon(9), monster(2), monster(3), monster(4)), g.room());
        assertTrue(g.dungeon().isEmpty());
    }

    /** The potion allowance resets when the next room is dealt. */
    @Test
    void potionAllowanceResetsEachRoom() {
        GameState s = state().health(5)
                .room(potion(7), monster(2), monster(3), potion(5))
                .dungeon(potion(4), weapon(2), weapon(3))
                .build();
        GameState g = engine.apply(s, new TakePotion(potion(7))).state();      // 12
        g = engine.apply(g, new FightBarehanded(monster(2))).state();          // 10
        g = engine.apply(g, new FightBarehanded(monster(3))).state();          // 7, turn over
        assertEquals(0, g.potionsUsedThisRoom());
        assertEquals(List.of(potion(5), potion(4), weapon(2), weapon(3)), g.room());
        g = engine.apply(g, new TakePotion(potion(5))).state();
        assertEquals(12, g.health()); // heals again in the new room
    }

    /** A potion drunk at full health heals nothing but still uses the turn's allowance. */
    @Test
    void potionAtFullHealthHealsZeroButConsumesTheAllowance() {
        GameState s = state().room(potion(7), potion(3), weapon(2), weapon(4)).build(); // health 20
        MoveResult first = engine.apply(s, new TakePotion(potion(7)));
        assertEquals(20, first.state().health());
        assertEquals(1, first.state().potionsUsedThisRoom());
        assertTrue(first.events().contains(new GameEvent.PotionUsed(potion(7), 0)));
        MoveResult second = engine.apply(first.state(), new TakePotion(potion(3)));
        assertEquals(20, second.state().health());
        assertTrue(second.events().contains(new GameEvent.PotionWasted(potion(3))));
    }
}
