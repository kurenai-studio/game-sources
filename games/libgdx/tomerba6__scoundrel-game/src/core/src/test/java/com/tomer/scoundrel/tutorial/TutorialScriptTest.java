package com.tomer.scoundrel.tutorial;

import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.Move;
import com.tomer.scoundrel.rules.Rulesets;
import com.tomer.scoundrel.rules.ScoundrelEngine;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The scripted tutorial: its curated deck and narrated beats, checked against the real engine. */
class TutorialScriptTest {

    /**
     * The load-bearing test: play every action step's move through the real
     * engine, in order, and prove each is legal at that point, health never
     * hits zero, and the run ends in a win. If the curated deck and the scripted
     * moves ever fall out of sync, this fails with the offending beat.
     */
    @Test
    void theScriptedRunIsLegalStaysAliveAndWins() {
        ScoundrelEngine engine = new ScoundrelEngine(Rulesets.standard());
        GameState state = engine.newGame(TutorialScript.deck());
        TutorialGuide guide = new TutorialGuide(TutorialScript.steps());

        for (TutorialStep step : TutorialScript.steps()) {
            if (!step.isAction()) {
                guide.next();
                continue;
            }
            Move move = step.expectedMove();
            assertTrue(engine.legalMoves(state).contains(move),
                    "illegal at [" + step.narration() + "] -> " + move
                            + "  legal=" + engine.legalMoves(state));
            assertTrue(guide.accepts(move), "guide out of sync at [" + step.narration() + "]");
            state = engine.apply(state, move).state();
            guide.onMoveApplied(move);
            assertTrue(state.health() > 0 || state.status() == Status.WON,
                    "health hit " + state.health() + " at [" + step.narration() + "]");
        }

        assertTrue(guide.isComplete(), "every step should be consumed");
        assertEquals(Status.WON, state.status(), "the tutorial must end in a win");
        assertTrue(state.health() > 0, "should finish with health to spare, was " + state.health());
        // The scoring beat promises a cleared dungeon scores the health you kept.
        // If the deck ever ends on a potion at the cap, that beat and the
        // Tutorial-complete line would both be telling a different story.
        assertEquals(state.health(), state.score(),
                "the script's win-scoring beat promises score == health left");
    }

    /**
     * The font is generated for LibGDX's default character set plus
     * {@code Theme.EXTRA_CHARS}, and a glyph outside what it generated renders as
     * a blank gap on the board — silently, since nothing throws. The narration is
     * held to the safe subset: printable ASCII and those extras. A real minus sign
     * (U+2212) in arithmetic is the easy way to break it.
     */
    @Test
    void everyNarrationUsesCharactersTheFontCanRender() {
        String extras = "—–×•"; // must track Theme.EXTRA_CHARS
        for (TutorialStep step : TutorialScript.steps()) {
            for (char c : step.narration().toCharArray()) {
                boolean renderable = (c >= 0x20 && c <= 0x7E) || extras.indexOf(c) >= 0;
                assertTrue(renderable, "unrenderable U+"
                        + Integer.toHexString(c).toUpperCase() + " ('" + c + "') in: "
                        + step.narration());
            }
        }
    }

    /**
     * Scoring is the rule players find most confusing, so the script must name
     * both halves of it — the negative losing score and what a cleared dungeon
     * is worth. Keyword checks, deliberately loose about the exact prose.
     */
    @Test
    void theScriptTeachesBothHalvesOfScoring() {
        List<String> explanations = TutorialScript.steps().stream()
                .filter(step -> !step.isAction())
                .map(TutorialStep::narration)
                .toList();

        assertTrue(explanations.stream().anyMatch(n -> n.contains("negative") && n.contains("monster")),
                "no beat explains that dying scores negative, minus the monsters left");
        assertTrue(explanations.stream().anyMatch(n -> n.contains("score") && n.contains("20")),
                "no beat explains the cleared-dungeon score and the 20-plus-potion case");
    }

    /** Every beat has narration, and the deck holds all three card types. */
    @Test
    void thebeatsAreWellFormedAndTeachEachCardType() {
        assertFalse(TutorialScript.steps().isEmpty());
        for (TutorialStep step : TutorialScript.steps()) {
            assertFalse(step.narration().isBlank(), "every beat needs narration");
        }
        // The deck must actually contain all three card types to teach them.
        assertTrue(TutorialScript.deck().stream().anyMatch(c -> c.type() == CardType.MONSTER));
        assertTrue(TutorialScript.deck().stream().anyMatch(c -> c.type() == CardType.WEAPON));
        assertTrue(TutorialScript.deck().stream().anyMatch(c -> c.type() == CardType.POTION));
    }

    /** Every action beat's move targets a card the deck deals. */
    @Test
    void everyActionStepTargetsACardActuallyInTheDeck() {
        // A move against a card the deck never deals could never be made.
        for (TutorialStep step : TutorialScript.steps()) {
            if (step.expectedMove() instanceof Move.CardMove card) {
                assertTrue(TutorialScript.deck().contains(card.targetCard()),
                        "move targets a card not in the deck: " + card.targetCard());
            }
        }
    }
}
