package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.rules.Move.AvoidRoom;
import com.tomer.scoundrel.rules.Move.FightBarehanded;
import com.tomer.scoundrel.rules.Move.FightWithWeapon;
import com.tomer.scoundrel.rules.Move.TakePotion;
import org.junit.jupiter.api.Test;

import java.util.List;

import static com.tomer.scoundrel.rules.Cards.monster;
import static com.tomer.scoundrel.rules.Cards.potion;
import static com.tomer.scoundrel.rules.Cards.weapon;
import static com.tomer.scoundrel.rules.StateBuilder.state;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The events each move reports alongside its new state. */
class EventsTest {

    private final ScoundrelEngine engine = new ScoundrelEngine(Rulesets.standard());

    /** A fight reports MonsterDefeated with whether a weapon was used and the damage taken. */
    @Test
    void fightsEmitMonsterDefeatedWithWeaponInfoAndDamage() {
        GameState bare = state().room(monster(7), weapon(2), weapon(3), weapon(4)).build();
        assertTrue(engine.apply(bare, new FightBarehanded(monster(7))).events()
                .contains(new GameEvent.MonsterDefeated(monster(7), false, 7)));

        GameState armed = state().room(monster(11), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(5)).build();
        assertTrue(engine.apply(armed, new FightWithWeapon(monster(11))).events()
                .contains(new GameEvent.MonsterDefeated(monster(11), true, 6)));
    }

    /** PotionUsed carries the health actually gained after the cap, not the potion's value. */
    @Test
    void potionUsedCarriesTheActualCapClippedHeal() {
        GameState s = state().health(19).room(potion(7), weapon(2), weapon(3), weapon(4)).build();
        assertTrue(engine.apply(s, new TakePotion(potion(7))).events()
                .contains(new GameEvent.PotionUsed(potion(7), 1)));
    }

    /** A potion past the turn's allowance reports PotionWasted and no PotionUsed. */
    @Test
    void secondPotionEmitsWastedNotUsed() {
        GameState s = state().health(10).potionsUsed(1).started()
                .room(potion(3), weapon(2), weapon(4), weapon(5)).build();
        List<GameEvent> events = engine.apply(s, new TakePotion(potion(3))).events();
        assertTrue(events.contains(new GameEvent.PotionWasted(potion(3))));
        assertTrue(events.stream().noneMatch(e -> e instanceof GameEvent.PotionUsed));
    }

    /** A weapon kill reports WeaponDegraded with the slain monster's value as the new limit. */
    @Test
    void weaponKillsEmitWeaponDegradedWithTheNewThreshold() {
        GameState s = state().room(monster(11), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(5)).build();
        assertTrue(engine.apply(s, new FightWithWeapon(monster(11))).events()
                .contains(new GameEvent.WeaponDegraded(weapon(5), 11)));
    }

    /**
     * Avoiding reports RoomAvoided and the RoomDealt that replaces it; finishing a
     * turn reports the next RoomDealt.
     */
    @Test
    void refillsAndAvoidsEmitRoomEvents() {
        GameState g = engine.newGame(List.of(
                potion(2), potion(3), potion(4), potion(5),
                potion(6), potion(7), potion(8), potion(9)));

        MoveResult avoided = engine.apply(g, new AvoidRoom());
        assertTrue(avoided.events().contains(
                new GameEvent.RoomAvoided(List.of(potion(2), potion(3), potion(4), potion(5)))));
        assertTrue(avoided.events().contains(
                new GameEvent.RoomDealt(List.of(potion(6), potion(7), potion(8), potion(9)))));

        GameState r = avoided.state();
        r = engine.apply(r, new TakePotion(potion(6))).state();
        r = engine.apply(r, new TakePotion(potion(7))).state();
        MoveResult third = engine.apply(r, new TakePotion(potion(8)));
        assertTrue(third.events().contains(
                new GameEvent.RoomDealt(List.of(potion(9), potion(2), potion(3), potion(4)))));
    }

    /** The move that ends a game reports GameWon or GameLost with the final score. */
    @Test
    void terminalMovesEmitGameWonOrGameLostWithTheScore() {
        MoveResult win = engine.apply(state().health(13).room(monster(2)).build(),
                new FightBarehanded(monster(2)));
        assertTrue(win.events().contains(new GameEvent.GameWon(11)));
        assertEquals(11, win.state().score());

        MoveResult loss = engine.apply(
                state().health(4).room(monster(7), weapon(2), weapon(3), weapon(4))
                        .dungeon(monster(12)).build(),
                new FightBarehanded(monster(7)));
        assertTrue(loss.events().contains(new GameEvent.GameLost(-15)));
        assertEquals(-15, loss.state().score());
    }
}
