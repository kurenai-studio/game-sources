package com.tomer.scoundrel.runs;

import com.tomer.scoundrel.model.Status;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.OptionalInt;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** Ranking runs into the high-score table, and the best score overall and per mode. */
class HighScoresTest {

    private static RunRecord run(int score, String endedAt) {
        return run("standard", score, endedAt);
    }

    private static RunRecord run(String rulesetId, int score, String endedAt) {
        return new RunRecord(null, rulesetId, score >= 0 ? Status.WON : Status.LOST,
                score, Instant.parse(endedAt), 60, 0, 0, 0, 0, 0, 0, 0);
    }

    /** The table is sorted highest score first and cut to the limit. */
    @Test
    void topSortsByScoreDescendingAndLimits() {
        RunRecord low = run(-24, "2026-07-06T10:00:00Z");
        RunRecord mid = run(11, "2026-07-06T11:00:00Z");
        RunRecord high = run(23, "2026-07-06T12:00:00Z");
        assertEquals(List.of(high, mid), HighScores.top(List.of(low, mid, high), 2));
    }

    /** Of two equal scores, the earlier run ranks first. */
    @Test
    void tiesGoToTheEarlierRun() {
        RunRecord later = run(20, "2026-07-06T12:00:00Z");
        RunRecord earlier = run(20, "2026-07-06T10:00:00Z");
        assertEquals(List.of(earlier, later), HighScores.top(List.of(later, earlier), 5));
    }

    /** The best score is empty with no runs, and the highest score otherwise. */
    @Test
    void bestIsEmptyWithoutRunsAndMaxWithThem() {
        assertEquals(OptionalInt.empty(), HighScores.best(List.of()));
        assertEquals(OptionalInt.of(23),
                HighScores.best(List.of(run(-24, "2026-07-06T10:00:00Z"), run(23, "2026-07-06T11:00:00Z"))));
    }

    /** A mode's best counts only that mode's runs, and is empty for a mode with none. */
    @Test
    void bestForRulesetConsidersOnlyThatModeAndIsEmptyWhenItHasNoRuns() {
        List<RunRecord> runs = List.of(
                run("standard", 23, "2026-07-06T10:00:00Z"),
                run("frail", 14, "2026-07-06T11:00:00Z"),
                run("frail", -8, "2026-07-06T12:00:00Z"));
        assertEquals(OptionalInt.of(23), HighScores.bestForRuleset(runs, "standard"));
        assertEquals(OptionalInt.of(14), HighScores.bestForRuleset(runs, "frail"));
        // Standard's higher 23 must not leak into a mode that has no runs yet.
        assertEquals(OptionalInt.empty(), HighScores.bestForRuleset(runs, "relentless"));
    }
}
