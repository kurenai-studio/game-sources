package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.runs.RunRecord;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The eight lifetime figures beside the table.
 *
 * <p>The panel keeps eight rows, each a figure the game actually keeps; there is
 * no WEAPONS BROKEN, since weapons never break in Scoundrel — they degrade and
 * stay equipped.
 */
class LedgerTotalsTest {

    private static RunRecord run(Status outcome, int score, long seconds, int slain, int drunk) {
        return new RunRecord(null, "standard", outcome, score, Instant.ofEpochSecond(1_753_000_000L),
                seconds, slain, 5, 4, drunk, 1, 2, 1);
    }

    private static String value(List<LedgerTotals.Stat> stats, String label) {
        return stats.stream().filter(s -> s.label().equals(label)).findFirst()
                .orElseThrow(() -> new AssertionError("no row labelled " + label)).value();
    }

    /** The panel has exactly its eight rows, each labelled in capitals. */
    @Test
    void thePanelIsExactlyTheEightRowsTheRenderHasRoomFor() {
        List<LedgerTotals.Stat> stats = LedgerTotals.of(List.of(run(Status.WON, 17, 252, 12, 3)));
        assertEquals(ScreenArt.TOTALS_ROWS, stats.size());
        for (LedgerTotals.Stat stat : stats) {
            assertEquals(stat.label().toUpperCase(java.util.Locale.ROOT), stat.label(),
                    "the panel is set in Silkscreen caps");
        }
    }

    /** BEST SCORE and WORST are the highest and lowest scores. */
    @Test
    void theBestAndWorstAreTheEndsOfTheScoreRange() {
        List<LedgerTotals.Stat> stats = LedgerTotals.of(List.of(
                run(Status.WON, 17, 252, 12, 3),
                run(Status.LOST, -104, 112, 4, 1),
                run(Status.WON, 4, 295, 16, 2)));
        assertEquals("17", value(stats, "BEST SCORE"));
        assertEquals("-104", value(stats, "WORST"));
    }

    /** Cleared is a fraction, because five wins means nothing without the count. */
    @Test
    void clearedReadsAsAFractionOfEveryFinishedRun() {
        List<LedgerTotals.Stat> stats = LedgerTotals.of(List.of(
                run(Status.WON, 17, 252, 12, 3),
                run(Status.LOST, -3, 187, 11, 2),
                run(Status.LOST, -12, 199, 9, 1)));
        assertEquals("1 OF 3", value(stats, "CLEARED"));
    }

    /** Monsters slain, potions drunk and total time are summed across every run. */
    @Test
    void theLifetimeCountsAreSummedAcrossEveryRun() {
        List<LedgerTotals.Stat> stats = LedgerTotals.of(List.of(
                run(Status.WON, 17, 252, 12, 3),
                run(Status.LOST, -3, 187, 11, 2)));
        assertEquals("23", value(stats, "MONSTERS SLAIN"));
        assertEquals("5", value(stats, "POTIONS DRUNK"));
        assertEquals("7:19", value(stats, "TOTAL TIME"), "252 + 187 seconds");
    }

    /** Only a cleared run has a clear time; a fast death is not a fast clear. */
    @Test
    void theFastestClearIgnoresEveryRunThatDidNotClear() {
        List<LedgerTotals.Stat> stats = LedgerTotals.of(List.of(
                run(Status.WON, 17, 252, 12, 3),
                run(Status.LOST, -104, 40, 4, 1),
                run(Status.WON, 4, 228, 16, 2)));
        assertEquals("3:48", value(stats, "FASTEST CLEAR"));
    }

    /** With no clears, FASTEST CLEAR reads "—" and CLEARED "0 OF 1". */
    @Test
    void withNoClearsTheFastestClearIsBlankRatherThanZero() {
        List<LedgerTotals.Stat> stats = LedgerTotals.of(List.of(run(Status.LOST, -12, 199, 9, 1)));
        assertEquals("—", value(stats, "FASTEST CLEAR"));
        assertEquals("0 OF 1", value(stats, "CLEARED"));
    }

    /**
     * The screen shows an empty state instead of this panel, but a totals panel
     * that divides by zero would take the screen down with it.
     */
    @Test
    void anEmptyLogProducesEightBlankRowsRatherThanThrowing() {
        List<LedgerTotals.Stat> stats = LedgerTotals.of(List.of());
        assertEquals(ScreenArt.TOTALS_ROWS, stats.size());
        assertEquals("—", value(stats, "BEST SCORE"));
        assertEquals("—", value(stats, "WORST"));
        assertEquals("0 OF 0", value(stats, "CLEARED"));
        assertTrue(stats.stream().allMatch(s -> !s.value().isBlank()));
    }
}
