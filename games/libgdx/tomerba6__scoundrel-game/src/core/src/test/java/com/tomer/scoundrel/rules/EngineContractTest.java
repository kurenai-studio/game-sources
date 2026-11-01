package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.Move.FightBarehanded;
import com.tomer.scoundrel.rules.Move.TakePotion;
import com.tomer.scoundrel.rules.Move.TakeWeapon;
import org.junit.jupiter.api.Test;

import java.util.List;

import static com.tomer.scoundrel.rules.Cards.monster;
import static com.tomer.scoundrel.rules.Cards.monster2;
import static com.tomer.scoundrel.rules.Cards.potion;
import static com.tomer.scoundrel.rules.Cards.weapon;
import static com.tomer.scoundrel.rules.StateBuilder.state;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * What the engine promises any caller: bad moves are refused, inputs are never
 * changed, and results are repeatable.
 */
class EngineContractTest {

    private final ScoundrelEngine engine = new ScoundrelEngine(Rulesets.standard());

    /** A move of the wrong kind for its card is refused with an IllegalMoveException. */
    @Test
    void movesOfTheWrongTypeForACardAreRejected() {
        GameState s = state().room(monster2(12), weapon(5), potion(5), weapon(2)).build();
        assertThrows(IllegalMoveException.class, () -> engine.apply(s, new TakeWeapon(monster2(12))));
        assertThrows(IllegalMoveException.class, () -> engine.apply(s, new TakePotion(weapon(5))));
        assertThrows(IllegalMoveException.class, () -> engine.apply(s, new FightBarehanded(potion(5))));
    }

    /** A move on a card outside the room, in the dungeon or not in the game at all, is refused. */
    @Test
    void movesTargetingCardsNotInTheRoomAreRejected() {
        GameState s = state().room(potion(2), potion(3), potion(4), potion(5))
                .dungeon(monster(9)).build();
        // in the dungeon, not the room
        assertThrows(IllegalMoveException.class, () -> engine.apply(s, new FightBarehanded(monster(9))));
        // not in this game at all
        assertThrows(IllegalMoveException.class, () -> engine.apply(s, new FightBarehanded(monster(13))));
    }

    /** Playing only offered moves, a seeded game runs to an end with a score and no moves left. */
    @Test
    void everyLegalMoveAppliesCleanlyOverAFullSeededGame() {
        GameState g = engine.newGame(42L);
        int steps = 0;
        while (g.status() == Status.IN_PROGRESS) {
            List<Move> moves = engine.legalMoves(g);
            assertFalse(moves.isEmpty(), "in-progress game must offer moves");
            g = engine.apply(g, moves.get(steps % moves.size())).state();
            assertTrue(++steps < 500, "game did not terminate");
        }
        assertNotNull(g.score());
        assertTrue(engine.legalMoves(g).isEmpty());
    }

    /** Applying a move leaves the state it was given unchanged. */
    @Test
    void applyNeverMutatesItsInputState() {
        GameState s = state().health(10)
                .room(potion(7), weapon(2), weapon(3), weapon(4))
                .dungeon(monster(2)).build();
        GameState snapshot = new GameState(s.dungeon(), s.room(), s.weapon(), s.health(),
                s.potionsUsedThisRoom(), s.cardsResolvedThisTurn(), s.previousRoomAvoided(),
                s.lastResolvedCard(), s.status(), s.score());
        engine.apply(s, new TakePotion(potion(7)));
        assertEquals(snapshot, s);
    }

    /** The same move on the same state gives equal results, events included. */
    @Test
    void applyingTheSameMoveToTheSameStateTwiceGivesEqualResults() {
        GameState s = state().health(10)
                .room(monster(6), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(9)).build();
        MoveResult first = engine.apply(s, new Move.FightWithWeapon(monster(6)));
        MoveResult second = engine.apply(s, new Move.FightWithWeapon(monster(6)));
        assertEquals(first, second);
    }
}
