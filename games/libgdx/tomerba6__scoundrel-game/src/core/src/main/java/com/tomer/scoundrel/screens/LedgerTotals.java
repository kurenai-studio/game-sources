package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.runs.RunRecord;
import com.tomer.scoundrel.runs.RunTotals;

import java.util.List;
import java.util.OptionalLong;

/**
 * The eight lifetime figures beside the table, as label/value pairs in the order
 * the panel draws them.
 *
 * <p>There is deliberately no WEAPONS BROKEN: weapons never break in Scoundrel
 * — they degrade and stay equipped for weaker monsters, which is the rule the
 * whole game turns on. The eight rows are figures the game actually keeps.
 * Three of them, the best and worst score and the fastest clear, are derived
 * here rather than stored — {@link RunTotals} sums, and these are extremes.
 */
final class LedgerTotals {

    /**
     * A row of the panel: a dim label on the left, a bright value on the right.
     *
     * @param label what the figure is, upper-cased, e.g. {@code MONSTERS SLAIN}
     * @param value the figure as it is printed, or an em dash when there is none
     */
    record Stat(String label, String value) {
    }

    /** What a figure reads as when there is nothing to compute it from. */
    private static final String NONE = "—";

    private LedgerTotals() {
    }

    /**
     * The eight figures for a history.
     *
     * @param records every recorded run, all modes together
     * @return eight rows, best score first and total time last
     */
    static List<Stat> of(List<RunRecord> records) {
        RunTotals totals = RunTotals.of(records);
        return List.of(
                new Stat("BEST SCORE", extreme(records, true)),
                new Stat("WORST", extreme(records, false)),
                // A count of wins says nothing without the count it came out of.
                new Stat("CLEARED", totals.wins() + " OF " + totals.runs()),
                new Stat("MONSTERS SLAIN", String.valueOf(totals.monstersDefeated())),
                new Stat("POTIONS DRUNK", String.valueOf(totals.potionsDrunk())),
                new Stat("WEAPONS EQUIPPED", String.valueOf(totals.weaponsEquipped())),
                new Stat("FASTEST CLEAR", fastestClear(records)),
                new Stat("TOTAL TIME", ClockText.format(totals.secondsPlayed())));
    }

    private static String extreme(List<RunRecord> records, boolean highest) {
        return records.stream()
                .mapToInt(RunRecord::score)
                .reduce((a, b) -> highest ? Math.max(a, b) : Math.min(a, b))
                .stream().mapToObj(String::valueOf).findFirst().orElse(NONE);
    }

    /** Only a cleared run has a clear time — a fast death is not a fast clear. */
    private static String fastestClear(List<RunRecord> records) {
        OptionalLong fastest = records.stream()
                .filter(run -> run.outcome() == Status.WON)
                .mapToLong(RunRecord::seconds)
                .min();
        return fastest.isPresent() ? ClockText.format(fastest.getAsLong()) : NONE;
    }
}
