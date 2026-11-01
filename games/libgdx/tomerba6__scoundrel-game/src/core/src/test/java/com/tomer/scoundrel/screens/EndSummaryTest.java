package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.Status;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * What the run-end panel says, decided before anything is drawn. One layout
 * covers both outcomes — the death variant is the same panel with the gold
 * accents swapped to dried blood — so the only thing that can go wrong here is
 * the wording and the colours, which is exactly what a test can hold and a
 * screenshot cannot.
 */
class EndSummaryTest {

    /** A cleared dungeon reads THE DUNGEON RAN OUT and CLEARED, with gold accents. */
    @Test
    void clearingTheDungeonReadsAsAnAchievementNotAnEnding() {
        EndSummary won = EndSummary.of(Status.WON, 17, 252, true, 12, 47);
        assertEquals("THE DUNGEON RAN OUT", won.eyebrow());
        assertEquals("CLEARED", won.headline());
        assertEquals(ScreenArt.GOLD, won.accent());
    }

    /** A death reads YOU DIED, with the dried-blood accent instead of gold. */
    @Test
    void dyingSwapsEveryGoldAccentForDriedBlood() {
        EndSummary lost = EndSummary.of(Status.LOST, -63, 158, false, 12, 47);
        assertEquals("YOU DIED", lost.headline());
        assertEquals(ScreenArt.OUTCOME_LOST, lost.accent());
        assertNotEquals(ScreenArt.GOLD, lost.accent());
    }

    /** Three cells, always, so the shared frame never has a hole in it. */
    @Test
    void thereAreAlwaysExactlyThreeStatCells() {
        for (EndSummary summary : new EndSummary[] {
                EndSummary.of(Status.WON, 17, 252, true, 12, 47),
                EndSummary.of(Status.LOST, -63, 158, false, 12, 47)}) {
            assertEquals(3, summary.cells().size());
            for (EndSummary.Cell cell : summary.cells()) {
                assertFalse(cell.label().isBlank());
                assertFalse(cell.value().isBlank());
            }
        }
    }

    /**
     * Clearing the dungeon scores the health you kept, so a HEALTH LEFT cell
     * beside the score would be the same number twice. What it costs to get out is
     * the figure the score cannot carry: two runs that both end on 17 are not
     * the same run if one of them bled 60 along the way.
     */
    @Test
    void aWonRunShowsWhatTheClearCostRatherThanRepeatingTheScore() {
        EndSummary won = EndSummary.of(Status.WON, 17, 252, false, 12, 47);
        assertEquals("SCORE", won.cells().get(0).label());
        assertEquals("17", won.cells().get(0).value());
        assertEquals(ScreenArt.OUTCOME_WON, won.cells().get(0).colour(),
                "what a clear is worth is the panel's headline figure, and reads as one");
        assertEquals("DAMAGE TAKEN", won.cells().get(1).label());
        assertEquals("47", won.cells().get(1).value());
        assertNotEquals(won.cells().get(0).value(), won.cells().get(1).value(),
                "the panel is saying the same number twice again");
        // The health bar already paints damage in this red, so the stat follows
        // the bar, not the panel's green.
        assertEquals(ScreenArt.OUTCOME_LOST, won.cells().get(1).colour());
        assertEquals("TIME", won.cells().get(2).label());
        assertEquals("4:12", won.cells().get(2).value());
    }

    /** A clear taken without a scratch says so rather than leaving a hole. */
    @Test
    void anUntouchedClearReportsNoDamageAtAll() {
        EndSummary won = EndSummary.of(Status.WON, 20, 300, false, 0, 0);
        assertEquals("DAMAGE TAKEN", won.cells().get(1).label());
        assertEquals("0", won.cells().get(1).value());
    }

    /**
     * A death has no health left to report, so the middle cell says what the
     * dungeon still had in it — the count of monsters still face-down, which is
     * exactly what the loss score was charged for.
     *
     * <p>Repeating the score there would say nothing twice. The count is the one
     * figure that explains why the number is as far below zero as it is: falling
     * early with the deck still full is the worst score there is.
     */
    @Test
    void aLostRunCountsWhatWasStillWaitingRatherThanRepeatingTheScore() {
        EndSummary lost = EndSummary.of(Status.LOST, -63, 158, false, 21, 47);
        assertEquals("-63", lost.cells().get(0).value());
        assertEquals(ScreenArt.BODY, lost.cells().get(0).colour(),
                "only a clear's score is worth colouring; a death's is just the damage done");
        assertEquals("STILL DOWN THERE", lost.cells().get(1).label());
        assertEquals("21", lost.cells().get(1).value());
        assertNotEquals(lost.cells().get(0).value(), lost.cells().get(1).value(),
                "the panel is saying the same number twice again");
        assertEquals(ScreenArt.OUTCOME_LOST, lost.cells().get(1).colour());
        assertEquals("2:38", lost.cells().get(2).value());
    }

    /** Dying on the very last card is a different story, and reads as one. */
    @Test
    void aDeathWithAnEmptyDungeonSaysNoneWereLeft() {
        EndSummary lost = EndSummary.of(Status.LOST, -2, 300, false, 0, 47);
        assertEquals("0", lost.cells().get(1).value());
    }

    /**
     * The two outcomes ask different questions — how much dungeon was left, and
     * what the clear cost — so each ignores the other's figure entirely.
     */
    @Test
    void eachOutcomeIgnoresTheFigureThatBelongsToTheOther() {
        EndSummary won = EndSummary.of(Status.WON, 17, 252, false, 9, 47);
        assertEquals("47", won.cells().get(1).value(), "a win never counts the dungeon");
        EndSummary lost = EndSummary.of(Status.LOST, -63, 158, false, 9, 47);
        assertEquals("9", lost.cells().get(1).value(), "a death never reports the damage");
    }

    /**
     * CLEARED is green and YOU DIED is blood — the two outcome colours the game
     * already uses everywhere else, on the ledger's rows and in the health bar.
     * The headline takes the outcome colour rather than cream, so the panel's
     * verdict reads the same colour here as it will on the ledger row this run
     * becomes.
     */
    @Test
    void theHeadlineTakesTheOutcomeColourEitherWay() {
        assertEquals(ScreenArt.OUTCOME_WON, EndSummary.of(Status.WON, 17, 252, true, 12, 47).headlineColour());
        assertEquals(ScreenArt.OUTCOME_LOST,
                EndSummary.of(Status.LOST, -63, 158, false, 12, 47).headlineColour());
    }

    /**
     * The tutorial ends on the same panel with its own words. It never claims a
     * best or a trophy — nothing about it is recorded.
     */
    @Test
    void theTutorialEndsOnTheSamePanelWithoutClaimingAnything() {
        EndSummary done = EndSummary.tutorial(8, 8);
        assertEquals("THAT IS THE WHOLE GAME", done.eyebrow());
        assertEquals("TUTORIAL DONE", done.headline());
        assertEquals(ScreenArt.GOLD, done.accent());
        assertFalse(done.newBest(), "the tutorial is never a record");
        assertEquals(3, done.cells().size());
    }

    /**
     * It reports no time. The board hides the clock for the whole tutorial —
     * it is not a timed run — so a TIME cell could only ever read 0:00, since
     * nothing is recording.
     *
     * <p>What it shows instead is the worked example the last beat just taught:
     * score and health left, side by side and equal. It is the one panel that
     * still reports health, and deliberately — teaching that equality is the
     * whole point of the beat, where on a real run it would be redundant.
     */
    @Test
    void theTutorialShowsTheScoringLessonRatherThanATimeItNeverKept() {
        EndSummary done = EndSummary.tutorial(10, 10);
        for (EndSummary.Cell cell : done.cells()) {
            assertNotEquals("TIME", cell.label());
            assertNotEquals("0:00", cell.value());
        }
        assertEquals("SCORE", done.cells().get(0).label());
        assertEquals("10", done.cells().get(0).value());
        assertEquals("HEALTH LEFT", done.cells().get(1).label());
        assertEquals("10", done.cells().get(1).value(),
                "clearing scores the health you kept — the two must read the same");
        assertEquals(ScreenArt.OUTCOME_WON, done.cells().get(1).colour());
        assertEquals("CLEARED", done.cells().get(2).label());
        assertEquals("YES", done.cells().get(2).value());
    }

    /** NEW BEST shows only when the run is one, a death included. */
    @Test
    void newBestOnlyShowsWhenItIsOne() {
        assertTrue(EndSummary.of(Status.WON, 17, 252, true, 12, 47).newBest());
        assertFalse(EndSummary.of(Status.WON, 17, 252, false, 12, 47).newBest());
        assertTrue(EndSummary.of(Status.LOST, -3, 100, true, 12, 47).newBest(),
                "a least-bad death is still a record");
    }

    /**
     * The one scoring edge case the game has: clearing on full health with a
     * potion last takes the score above the cap. Reporting the cost instead of
     * the health settles it — a 27 beside a 20 would look like an error, where a
     * 27 beside what it cost simply is the run.
     */
    @Test
    void aScoreAboveTheHealthCapIsShownAsItStands() {
        EndSummary won = EndSummary.of(Status.WON, 27, 300, true, 12, 31);
        assertEquals("27", won.cells().get(0).value());
        assertEquals("DAMAGE TAKEN", won.cells().get(1).label());
        assertEquals("31", won.cells().get(1).value());
    }
}
