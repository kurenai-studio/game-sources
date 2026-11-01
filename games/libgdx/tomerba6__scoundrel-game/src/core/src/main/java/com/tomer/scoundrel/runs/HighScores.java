package com.tomer.scoundrel.runs;

import java.util.Comparator;
import java.util.List;
import java.util.OptionalInt;

/** Pure views over the run history; no I/O. */
public final class HighScores {

    private HighScores() {
    }

    /**
     * Highest score first; ties go to the run that reached it first.
     *
     * @param runs  the history, in any order; not modified
     * @param limit the most runs to return, 0 or more
     * @return up to {@code limit} runs, best first
     * @throws IllegalArgumentException if {@code limit} is negative
     */
    public static List<RunRecord> top(List<RunRecord> runs, int limit) {
        return runs.stream()
                .sorted(Comparator.comparingInt(RunRecord::score).reversed()
                        .thenComparing(RunRecord::endedAt))
                .limit(limit)
                .toList();
    }

    /**
     * The best score on record; empty when no runs exist.
     *
     * @param runs the history, every mode together
     * @return the highest score, or empty
     */
    public static OptionalInt best(List<RunRecord> runs) {
        return runs.stream().mapToInt(RunRecord::score).max();
    }

    /**
     * The best score among runs of one ruleset; empty when that mode has no runs
     * yet. Modes aren't comparable — a Frail 14 shouldn't be buried by a Standard
     * 20 — so each is ranked against its own.
     *
     * @param runs      the history, every mode together
     * @param rulesetId the mode id to rank within
     * @return the highest score among that mode's runs, or empty
     */
    public static OptionalInt bestForRuleset(List<RunRecord> runs, String rulesetId) {
        return runs.stream()
                .filter(run -> run.rulesetId().equals(rulesetId))
                .mapToInt(RunRecord::score)
                .max();
    }
}
