package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.Move.FightBarehanded;
import com.tomer.scoundrel.rules.Move.FightWithWeapon;
import com.tomer.scoundrel.rules.Move.TakePotion;
import org.junit.jupiter.api.Test;

import java.util.List;

import static com.tomer.scoundrel.rules.Cards.monster;
import static com.tomer.scoundrel.rules.Cards.monster2;
import static com.tomer.scoundrel.rules.Cards.potion;
import static com.tomer.scoundrel.rules.Cards.weapon;
import static com.tomer.scoundrel.rules.StateBuilder.state;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** How a game ends and what it scores. */
class ScoringTest {

    private final ScoundrelEngine engine = new ScoundrelEngine(Rulesets.standard());

    /** Dropping to zero health or below ends the game as a loss, with no moves left. */
    @Test
    void reachingZeroHealthLosesImmediately() {
        GameState s = state().health(5).room(monster2(12), weapon(2), weapon(3), weapon(4)).build();
        GameState lost = engine.apply(s, new FightBarehanded(monster2(12))).state();
        assertEquals(Status.LOST, lost.status());
        assertEquals(-7, lost.health());
        assertTrue(engine.legalMoves(lost).isEmpty());
    }

    /**
     * The run-end panel explains a death by saying how many monsters were still
     * face-down, so the state has to be able to count them. It counts the same
     * cards the loss score charges for: monsters in the dungeon, not the room
     * and not the weapons and potions down there with them.
     */
    @Test
    void theStateCountsTheMonstersStillFaceDown() {
        GameState s = state().health(4)
                .room(monster(7), weapon(2), weapon(3), weapon(4))
                .dungeon(monster(12), monster2(9), weapon(5), potion(3))
                .build();
        assertEquals(2, s.monstersRemaining(), "only the dungeon's monsters count");
        assertEquals(0, state().health(4).room(monster(7)).build().monstersRemaining(),
                "an empty dungeon has none left, whatever is in the room");
    }

    /** The count and the score have to agree about which cards they are about. */
    @Test
    void theCountMatchesWhatTheLossScoreCharedFor() {
        GameState s = state().health(4)
                .room(monster(7), weapon(2), weapon(3), weapon(4))
                .dungeon(monster(12), monster2(9))
                .build();
        GameState lost = engine.apply(s, new FightBarehanded(monster(7))).state();
        assertEquals(Status.LOST, lost.status());
        assertEquals(2, lost.monstersRemaining());
        // -3 health, less the 12 and the 9 it counted: the two the panel names.
        assertEquals(-24, lost.score());
    }

    /** A loss scores the final health minus every monster still in the dungeon. */
    @Test
    void lossScoreIsNegativeHealthMinusDungeonMonsters() {
        // Die at -3 with Q(12) + 9 still face-down: -3 - 21 = -24.
        GameState s = state().health(4)
                .room(monster(7), weapon(2), weapon(3), weapon(4))
                .dungeon(monster(12), monster2(9))
                .build();
        GameState lost = engine.apply(s, new FightBarehanded(monster(7))).state();
        assertEquals(-24, lost.score());
    }

    /** Monsters left in the room are not charged against a loss score. */
    @Test
    void unresolvedRoomMonstersDoNotCountTowardTheLossPenalty() {
        GameState s = state().health(4)
                .room(monster(7), monster2(13), monster2(14), potion(2))
                .dungeon(monster(12), monster2(9))
                .build();
        GameState lost = engine.apply(s, new FightBarehanded(monster(7))).state();
        assertEquals(-24, lost.score()); // K and A in the room are ignored
    }

    /** Weapons and potions left in the dungeon are not charged against a loss score. */
    @Test
    void weaponsAndPotionsInTheDungeonAddNothingToTheLossPenalty() {
        GameState s = state().health(4)
                .room(monster(7), weapon(2), weapon(3), weapon(4))
                .dungeon(weapon(9), potion(8), monster(12))
                .build();
        GameState lost = engine.apply(s, new FightBarehanded(monster(7))).state();
        assertEquals(-3 - 12, lost.score());
    }

    /** Clearing the dungeon wins, scoring the health left. */
    @Test
    void clearingEverythingWinsWithRemainingHealthAsScore() {
        GameState s = state().health(13).room(monster(2)).build();
        GameState won = engine.apply(s, new FightBarehanded(monster(2))).state();
        assertEquals(Status.WON, won.status());
        assertEquals(11, won.score());
    }

    /** Winning at 20 health with a potion as the last card scores 20 plus that potion. */
    @Test
    void winningAtExactly20WithAPotionLastScores20PlusItsValue() {
        GameState s = state().health(16).room(potion(4)).build();
        GameState won = engine.apply(s, new TakePotion(potion(4))).state();
        assertEquals(20, won.health());
        assertEquals(24, won.score());
    }

    /** Winning at 20 with a monster as the last card scores just 20. */
    @Test
    void winningAt20WithAMonsterLastScoresJust20() {
        GameState s = state().health(20).room(monster(3)).weapon(weapon(10)).build();
        GameState won = engine.apply(s, new FightWithWeapon(monster(3))).state();
        assertEquals(20, won.health());
        assertEquals(20, won.score());
    }

    /** Winning below 20 with a potion last scores only the health left. */
    @Test
    void winningBelow20WithAPotionLastGetsNoBonus() {
        GameState s = state().health(15).room(potion(4)).build();
        GameState won = engine.apply(s, new TakePotion(potion(4))).state();
        assertEquals(19, won.score());
    }

    /** A last potion drunk at full health, healing nothing, still earns the bonus. */
    @Test
    void capWastedFinalPotionStillTriggersTheBonus() {
        GameState s = state().health(20).room(potion(9)).build();
        GameState won = engine.apply(s, new TakePotion(potion(9))).state();
        assertEquals(20, won.health());
        assertEquals(29, won.score());
    }

    /** Dying on the last card is a loss, scored on health alone when the dungeon is empty. */
    @Test
    void dyingOnTheVeryLastCardIsALoss() {
        GameState s = state().health(3).room(monster(5)).build();
        GameState lost = engine.apply(s, new FightBarehanded(monster(5))).state();
        assertEquals(Status.LOST, lost.status());
        assertEquals(-2, lost.score()); // empty dungeon adds no penalty
    }

    /** Exactly zero health is a loss, not a survival. */
    @Test
    void hittingExactlyZeroHealthIsALossNotASurvival() {
        // The boundary: 0 is death, not 1-hp survival. A 5 barehanded at 5 hp.
        GameState s = state().health(5).room(monster(5), weapon(2), weapon(3), weapon(4)).build();
        GameState lost = engine.apply(s, new FightBarehanded(monster(5))).state();
        assertEquals(Status.LOST, lost.status());
        assertEquals(0, lost.health());
        assertEquals(0, lost.score()); // 0 health, empty dungeon
        assertTrue(engine.legalMoves(lost).isEmpty());
    }

    /** A fatal armed fight still stacks the monster, degrades the weapon and scores the loss as usual. */
    @Test
    void aFatalWeaponFightStillStacksDegradesAndScores() {
        // Death by the weapon, not barehanded: the excess damage kills you, but
        // the blow still lands fully — monster stacked, weapon degraded — and the
        // loss score counts the dungeon as usual.
        GameState s = state().health(3)
                .room(monster(11), weapon(2), weapon(3), weapon(4))
                .weapon(weapon(5))
                .dungeon(monster2(9))
                .build();
        MoveResult r = engine.apply(s, new FightWithWeapon(monster(11)));
        GameState lost = r.state();
        assertEquals(Status.LOST, lost.status());
        assertEquals(-3, lost.health()); // 11 - weapon 5 = 6 damage; 3 - 6 = -3
        assertEquals(List.of(monster(11)), lost.weapon().slain()); // still stacked
        assertTrue(r.events().contains(new GameEvent.MonsterDefeated(monster(11), true, 6)));
        assertTrue(r.events().contains(new GameEvent.WeaponDegraded(weapon(5), 11)));
        assertEquals(-3 - 9, lost.score());
    }

    /** Once a game is won or lost, no move is offered and any move is refused. */
    @Test
    void noMovesAreLegalAfterTheGameEnds() {
        GameState won = engine.apply(
                state().health(13).room(monster(2)).build(),
                new FightBarehanded(monster(2))).state();
        assertTrue(engine.legalMoves(won).isEmpty());
        assertThrows(IllegalMoveException.class,
                () -> engine.apply(won, new FightBarehanded(monster(3))));

        GameState lost = engine.apply(
                state().health(3).room(monster(5)).build(),
                new FightBarehanded(monster(5))).state();
        assertTrue(engine.legalMoves(lost).isEmpty());
        assertThrows(IllegalMoveException.class,
                () -> engine.apply(lost, new Move.AvoidRoom()));
    }
}
