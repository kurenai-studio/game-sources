package com.tomer.scoundrel.achievements;

import com.tomer.scoundrel.runs.RunRecord;
import com.tomer.scoundrel.runs.RunTotals;

import java.util.List;

/**
 * Everything an achievement rule may read: the just-finished run's rich
 * {@link RunSummary}, and the full run history including that run as its last
 * element, so milestone rules can sum lifetime totals. Progress is derived
 * here, never stored — see {@link RunTotals}.
 *
 * @param run     the facts of the run that just ended
 * @param history every recorded run, oldest first, ending with this one; copied
 */
public record AchievementContext(RunSummary run, List<RunRecord> history) {

    /**
     * Copies the history, so a rule sees the list as it was when the run ended.
     *
     * @throws NullPointerException if {@code history} is null or holds a null
     */
    public AchievementContext {
        history = List.copyOf(history);
    }

    /**
     * Lifetime sums over the whole history, for the milestone rules.
     *
     * @return the totals, recomputed on every call
     */
    public RunTotals totals() {
        return RunTotals.of(history);
    }
}
