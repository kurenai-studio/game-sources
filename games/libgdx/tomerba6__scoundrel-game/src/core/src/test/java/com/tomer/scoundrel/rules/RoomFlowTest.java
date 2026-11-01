package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.rules.Move.AvoidRoom;
import com.tomer.scoundrel.rules.Move.TakePotion;
import org.junit.jupiter.api.Test;

import java.util.List;

import static com.tomer.scoundrel.rules.Cards.monster;
import static com.tomer.scoundrel.rules.Cards.potion;
import static com.tomer.scoundrel.rules.Cards.weapon;
import static com.tomer.scoundrel.rules.Moves.movesFor;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** How rooms are dealt, carried over and avoided. */
class RoomFlowTest {

    private final ScoundrelEngine engine = new ScoundrelEngine(Rulesets.standard());

    private static List<Card> eightPotions() {
        return List.of(potion(2), potion(3), potion(4), potion(5),
                potion(6), potion(7), potion(8), potion(9));
    }

    /** A new game deals the top four cards as the first room, at 20 health. */
    @Test
    void newGameDealsAFullFirstRoom() {
        GameState g = engine.newGame(List.of(
                potion(2), potion(3), potion(4), potion(5), potion(6), potion(7)));
        assertEquals(List.of(potion(2), potion(3), potion(4), potion(5)), g.room());
        assertEquals(List.of(potion(6), potion(7)), g.dungeon());
        assertEquals(20, g.health());
    }

    /** After three cards are resolved, the fourth leads the next room, refilled from the dungeon. */
    @Test
    void afterThreeResolutionsTheFourthCarriesIntoTheNextRoom() {
        GameState g = engine.newGame(List.of(
                potion(2), potion(3), potion(4), weapon(5),
                potion(6), potion(7), potion(8), monster(2), monster(3)));
        g = engine.apply(g, new TakePotion(potion(2))).state();
        g = engine.apply(g, new TakePotion(potion(3))).state();
        assertEquals(2, g.room().size()); // mid-turn: no refill yet
        g = engine.apply(g, new TakePotion(potion(4))).state();
        assertEquals(List.of(weapon(5), potion(6), potion(7), potion(8)), g.room());
        assertEquals(List.of(monster(2), monster(3)), g.dungeon());
        assertFalse(g.roomResolutionStarted()); // fresh turn
    }

    /** Every card of a fresh room offers at least one move. */
    @Test
    void anyOfTheFourRoomCardsCanBeResolvedFirst() {
        GameState g = engine.newGame(List.of(
                potion(2), monster(3), weapon(4), potion(5), potion(6)));
        for (Card card : g.room()) {
            assertFalse(movesFor(engine, g, card).isEmpty(), "no moves for " + card.id());
        }
    }

    /** Avoiding sends the room to the bottom of the dungeon, deals a fresh one and reports RoomAvoided. */
    @Test
    void avoidingPutsTheRoomAtTheBottomAndDealsAFreshOne() {
        GameState g = engine.newGame(eightPotions());
        MoveResult r = engine.apply(g, new AvoidRoom());
        assertEquals(List.of(potion(6), potion(7), potion(8), potion(9)), r.state().room());
        assertEquals(List.of(potion(2), potion(3), potion(4), potion(5)), r.state().dungeon());
        assertTrue(r.state().previousRoomAvoided());
        assertTrue(r.events().contains(
                new GameEvent.RoomAvoided(List.of(potion(2), potion(3), potion(4), potion(5)))));
    }

    /** The very first room can be avoided. */
    @Test
    void firstRoomOfAGameCanBeAvoided() {
        GameState g = engine.newGame(eightPotions());
        assertTrue(engine.legalMoves(g).contains(new AvoidRoom()));
    }

    /** A room cannot be avoided once one of its cards has been resolved. */
    @Test
    void avoidingAfterACardWasResolvedIsIllegal() {
        GameState g = engine.newGame(eightPotions());
        g = engine.apply(g, new TakePotion(potion(2))).state();
        assertFalse(engine.legalMoves(g).contains(new AvoidRoom()));
        GameState started = g;
        assertThrows(IllegalMoveException.class, () -> engine.apply(started, new AvoidRoom()));
    }

    /** The room after an avoided one cannot be avoided. */
    @Test
    void avoidingTwoRoomsInARowIsIllegal() {
        GameState g = engine.apply(engine.newGame(eightPotions()), new AvoidRoom()).state();
        assertFalse(engine.legalMoves(g).contains(new AvoidRoom()));
        GameState avoided = g;
        assertThrows(IllegalMoveException.class, () -> engine.apply(avoided, new AvoidRoom()));
    }

    /** Avoiding is allowed again once a room has been played through. */
    @Test
    void avoidingIsLegalAgainAfterResolvingARoom() {
        List<Card> order = List.of(
                potion(2), potion(3), potion(4), potion(5),
                potion(6), potion(7), potion(8), potion(9),
                weapon(2), weapon(3), weapon(4));
        GameState g = engine.apply(engine.newGame(order), new AvoidRoom()).state();
        // room: 6H 7H 8H 9H — resolve the turn
        g = engine.apply(g, new TakePotion(potion(6))).state();
        g = engine.apply(g, new TakePotion(potion(7))).state();
        g = engine.apply(g, new TakePotion(potion(8))).state();
        assertFalse(g.previousRoomAvoided());
        assertTrue(engine.legalMoves(g).contains(new AvoidRoom()));
        engine.apply(g, new AvoidRoom()); // must not throw
    }

    /** The potion and resolution counts reset when the next room is dealt. */
    @Test
    void perRoomFlagsResetWhenANewRoomIsDealt() {
        GameState g = engine.newGame(List.of(
                potion(2), monster(2), monster(3), potion(5),
                weapon(2), weapon(3), weapon(4)));
        g = engine.apply(g, new TakePotion(potion(2))).state();
        assertEquals(1, g.potionsUsedThisRoom());
        assertEquals(1, g.cardsResolvedThisTurn());
        assertTrue(g.roomResolutionStarted());
        g = engine.apply(g, new Move.FightBarehanded(monster(2))).state();
        assertEquals(2, g.cardsResolvedThisTurn());
        g = engine.apply(g, new Move.FightBarehanded(monster(3))).state(); // turn over
        assertEquals(0, g.potionsUsedThisRoom());
        assertEquals(0, g.cardsResolvedThisTurn());
        assertFalse(g.roomResolutionStarted());
        assertEquals(4, g.room().size());
    }
}
