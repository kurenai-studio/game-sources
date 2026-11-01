package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.runs.RunRecord;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * One row of THE LEDGER: everything the table draws about a run, worked out
 * away from the GL class so the decisions can be asserted rather than
 * screenshotted. Only the placing of the strings is left to the screen.
 */
class LedgerRowTest {

    private static RunRecord run(int score, Status outcome, String mode, long seconds) {
        return new RunRecord(null, mode, outcome, score,
                ZonedDateTime.of(2026, 7, 24, 13, 5, 0, 0, ZoneId.systemDefault()).toInstant(),
                seconds, 12, 8, 6, 3, 1, 2, 1);
    }

    /** The run number is a Roman numeral, counted from I. */
    @Test
    void theRunNumberIsARomanNumeral() {
        assertEquals("I", LedgerRow.of(0, run(17, Status.WON, "standard", 252)).numeral());
        assertEquals("IV", LedgerRow.of(3, run(9, Status.WON, "standard", 381)).numeral());
        assertEquals("IX", LedgerRow.of(8, run(-63, Status.LOST, "standard", 158)).numeral());
        assertEquals("X", LedgerRow.of(9, run(-104, Status.LOST, "frail", 112)).numeral());
    }

    /** A negative score is the whole point of the column; it must not read as a win. */
    @Test
    void aNegativeScoreIsDriedBloodAndAPositiveOneIsCream() {
        assertEquals(ScreenArt.SCORE_NEGATIVE, LedgerRow.of(0, run(-3, Status.LOST, "standard", 187)).scoreColour());
        assertEquals(ScreenArt.SCORE_POSITIVE, LedgerRow.of(0, run(17, Status.WON, "standard", 252)).scoreColour());
        // Zero is not a loss. It is only reachable by clearing the dungeon on
        // the last point of health, which is the best story the table can tell.
        assertEquals(ScreenArt.SCORE_POSITIVE, LedgerRow.of(0, run(0, Status.WON, "standard", 252)).scoreColour());
    }

    /** A row reads CLEARED or DEFEATED, each in its own outcome colour. */
    @Test
    void theOutcomeSaysWhichAndColoursItself() {
        LedgerRow won = LedgerRow.of(0, run(17, Status.WON, "standard", 252));
        LedgerRow lost = LedgerRow.of(1, run(-12, Status.LOST, "standard", 199));
        assertEquals("CLEARED", won.outcome());
        assertEquals("DEFEATED", lost.outcome());
        assertEquals(ScreenArt.OUTCOME_WON, won.outcomeColour());
        assertEquals(ScreenArt.OUTCOME_LOST, lost.outcomeColour());
        assertNotEquals(won.outcomeColour(), lost.outcomeColour());
    }

    /** Scores are ranked per mode, so a row has to say which one it was set in. */
    @Test
    void theModeIsItsMenuNameAndAnUnknownIdSurvivesAsItself() {
        assertEquals("STANDARD", LedgerRow.of(0, run(17, Status.WON, "standard", 252)).mode());
        assertEquals("RELENTLESS", LedgerRow.of(0, run(11, Status.WON, "relentless", 228)).mode());
        // A retired mode must still draw a row rather than take the screen down.
        assertEquals("CHAOS", LedgerRow.of(0, run(5, Status.WON, "chaos", 100)).mode());
    }

    /** A row's date reads like JUL 24, its time like 4:12, and its slain count as the bare number. */
    @Test
    void theDateAndClockAreTheirOwnColumns() {
        LedgerRow row = LedgerRow.of(0, run(17, Status.WON, "standard", 252));
        assertEquals("JUL 24", row.date());
        assertEquals("4:12", row.time());
        assertEquals("12", row.slain(), "the header already says SLAIN");
    }

    /**
     * Rows stripe by flat colour, never alpha, because a translucent stripe over
     * the torchlit backdrop would shift down the table as the gradient does.
     */
    @Test
    void rowsStripeByFlatColourAndAlternate() {
        int[] stripes = new int[4];
        for (int i = 0; i < 4; i++) {
            stripes[i] = LedgerRow.of(i, run(1, Status.WON, "standard", 60)).stripe();
        }
        assertEquals(ScreenArt.ROW_ODD, stripes[0]);
        assertEquals(ScreenArt.ROW_EVEN, stripes[1]);
        assertEquals(stripes[0], stripes[2]);
        assertEquals(stripes[1], stripes[3]);
        assertNotEquals(stripes[0], stripes[1]);
    }

    /** The table draws ten rows; a numeral past that would be a silent blank. */
    @Test
    void everyDrawableRowHasANumeral() {
        for (int i = 0; i < ScreenArt.LEDGER_ROWS; i++) {
            assertTrue(LedgerRow.of(i, run(1, Status.WON, "standard", 60)).numeral().length() > 0);
        }
    }
}
