package com.tomer.scoundrel.tutorial;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.rules.Move;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The guide that walks the tutorial's beats and decides which moves are allowed. */
class TutorialGuideTest {

    private static final Card GOBLIN = new Card("2C", CardType.MONSTER, 2);
    private static final Move FIGHT = new Move.FightBarehanded(GOBLIN);

    private static TutorialGuide guide() {
        return new TutorialGuide(List.of(
                TutorialStep.say("intro"),
                TutorialStep.act("fight it", FIGHT),
                TutorialStep.say("done")));
    }

    /** An explanation beat accepts no move, and Next moves on from it. */
    @Test
    void anExplanationBeatAcceptsNoMoveAndAdvancesOnNext() {
        TutorialGuide g = guide();
        assertFalse(g.accepts(FIGHT), "explanation steps gate all moves");
        g.next();
        assertTrue(g.current().isAction(), "Next moved on to the action beat");
    }

    /** An action beat accepts only the move it asks for. */
    @Test
    void anActionBeatAcceptsOnlyItsExpectedMove() {
        TutorialGuide g = guide();
        g.next();
        assertTrue(g.accepts(FIGHT));
        assertFalse(g.accepts(new Move.AvoidRoom()));
        assertFalse(g.accepts(new Move.TakePotion(GOBLIN)));
    }

    /** Next does not move past an action beat. */
    @Test
    void nextDoesNotSkipAnActionBeat() {
        TutorialGuide g = guide();
        g.next();          // onto the action beat
        g.next();          // must not advance past it
        assertTrue(g.accepts(FIGHT), "still waiting on the action");
    }

    /** An action beat advances on its expected move and on no other. */
    @Test
    void onlyTheExpectedMoveAdvancesAnActionBeat() {
        TutorialGuide g = guide();
        g.next();
        g.onMoveApplied(new Move.AvoidRoom()); // wrong move: no advance
        assertTrue(g.accepts(FIGHT));
        g.onMoveApplied(FIGHT);                // right move: advances
        assertFalse(g.isComplete());
        assertFalse(g.current().isAction(), "now on the closing explanation beat");
    }

    /**
     * Once every beat is done the guide is complete, and asking for the current
     * step throws IllegalStateException.
     */
    @Test
    void runsToCompletionAndThenHasNoCurrentStep() {
        TutorialGuide g = guide();
        g.next();
        g.onMoveApplied(FIGHT);
        g.next();
        assertTrue(g.isComplete());
        assertThrows(IllegalStateException.class, g::current);
    }

    /**
     * The callout says STEP n OF m and draws a dot per beat, so the guide has to
     * be able to count. One-based, because it is read by a player and not an
     * index — "step 0 of 3" is a bug report waiting to happen.
     */
    @Test
    void theStepNumberIsOneBasedAndTheCountIsEveryBeat() {
        TutorialGuide g = guide();
        assertEquals(3, g.stepCount());
        assertEquals(1, g.stepNumber());
        g.next();
        assertEquals(2, g.stepNumber());
        g.onMoveApplied(FIGHT);
        assertEquals(3, g.stepNumber());
        assertEquals(3, g.stepCount(), "the count never moves");
    }

    /**
     * A finished tutorial must still answer, because the completion panel is
     * drawn from the same guide the callout was.
     */
    @Test
    void aFinishedGuideStillReportsItsLastStepRatherThanRunningOff() {
        TutorialGuide g = guide();
        g.next();
        g.onMoveApplied(FIGHT);
        g.next();
        assertTrue(g.isComplete());
        assertEquals(3, g.stepNumber(), "clamped to the last beat, not 4");
        assertEquals(3, g.stepCount());
    }
}
