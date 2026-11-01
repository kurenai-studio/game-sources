package com.tomer.scoundrel.runs;

import com.tomer.scoundrel.model.Status;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** Lifetime totals summed across every run. */
class RunTotalsTest {

    private static RunRecord run(Status outcome, int score, long seconds,
                                 int monsters, int damage, int healed,
                                 int drunk, int wasted, int equips, int avoids) {
        return new RunRecord(1L, "standard", outcome, score,
                Instant.parse("2026-07-06T10:00:00Z"), seconds,
                monsters, damage, healed, drunk, wasted, equips, avoids);
    }

    /** With no runs every total is zero, and the win rate is 0 rather than a division by zero. */
    @Test
    void noRunsMeansAllZerosAndNoDivisionByZero() {
        RunTotals totals = RunTotals.of(List.of());
        assertEquals(0, totals.runs());
        assertEquals(0, totals.wins());
        assertEquals(0, totals.monstersDefeated());
        assertEquals(0, totals.secondsPlayed());
        assertEquals(0.0, totals.winRate());
    }

    /** Every counter, plus wins, losses and time played, is summed across runs. */
    @Test
    void sumsEveryCounterAcrossRuns() {
        RunTotals totals = RunTotals.of(List.of(
                run(Status.WON, 23, 300, 16, 27, 15, 5, 2, 3, 4),
                run(Status.LOST, -24, 120, 5, 23, 0, 1, 1, 1, 0)));
        assertEquals(2, totals.runs());
        assertEquals(1, totals.wins());
        assertEquals(1, totals.losses());
        assertEquals(21, totals.monstersDefeated());
        assertEquals(50, totals.damageTaken());
        assertEquals(15, totals.healthHealed());
        assertEquals(6, totals.potionsDrunk());
        assertEquals(3, totals.potionsWasted());
        assertEquals(4, totals.weaponsEquipped());
        assertEquals(4, totals.roomsAvoided());
        assertEquals(420, totals.secondsPlayed());
    }

    /** The win rate is wins over all runs. */
    @Test
    void winRateIsWinsOverAllRuns() {
        RunTotals totals = RunTotals.of(List.of(
                run(Status.WON, 20, 60, 0, 0, 0, 0, 0, 0, 0),
                run(Status.LOST, -5, 60, 0, 0, 0, 0, 0, 0, 0),
                run(Status.LOST, -9, 60, 0, 0, 0, 0, 0, 0, 0),
                run(Status.LOST, -1, 60, 0, 0, 0, 0, 0, 0, 0)));
        assertEquals(0.25, totals.winRate());
    }
}
