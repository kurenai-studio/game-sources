package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.Status;

import java.util.List;

/**
 * What the run-end panel says, worked out before anything is drawn.
 *
 * <p>One layout covers both outcomes — a death is the same panel with the gold
 * accents swapped to dried blood — so
 * everything that differs between a win and a death is decided here and the
 * screen draws whichever it is handed.
 *
 * @param eyebrow        the small line over the headline
 * @param headline       the verdict: {@code CLEARED}, {@code YOU DIED} or {@code TUTORIAL DONE}
 * @param accent         {@code 0xRRGGBB} of the panel's accents: gold, or dried blood for a death
 * @param headlineColour {@code 0xRRGGBB} of the headline
 * @param cells          the three figures, left to right
 * @param newBest        whether to show the new-best badge
 */
record EndSummary(String eyebrow, String headline, int accent, int headlineColour,
                  List<Cell> cells, boolean newBest) {

    /**
     * One of the three figures in the shared frame.
     *
     * @param label  what the figure is, upper-cased
     * @param value  the figure as printed
     * @param colour {@code 0xRRGGBB} of the value
     */
    record Cell(String label, String value, int colour) {
    }

    /**
     * The tutorial's ending, on the same panel with its own words. It never
     * claims a best or a trophy, because nothing about it is recorded.
     *
     * <p>And it reports no time: the board hides the clock for the whole
     * tutorial — it is not a timed run — so a TIME cell here could only ever
     * read 0:00. The three cells show the worked example the last beat just
     * taught instead. Score and health left sit side by side and equal, which
     * <em>is</em> the rule: clear the dungeon and you score the health you kept.
     * This is the one panel that still reports health, and deliberately —
     * teaching that equality is the point here, where on a real run it would
     * only be the same number twice.
     *
     * @param score  the tutorial's final score
     * @param health the health it ended on, which equals the score
     * @return the tutorial's panel: never a new best
     */
    static EndSummary tutorial(int score, int health) {
        return new EndSummary("THAT IS THE WHOLE GAME", "TUTORIAL DONE",
                ScreenArt.GOLD, ScreenArt.BODY,
                List.of(
                        new Cell("SCORE", String.valueOf(score), ScreenArt.BODY),
                        new Cell("HEALTH LEFT", String.valueOf(health), ScreenArt.OUTCOME_WON),
                        new Cell("CLEARED", "YES", ScreenArt.BODY)),
                false);
    }

    /**
     * The panel for a finished run: score, then what the clear cost or what was
     * still waiting, then the time.
     *
     * @param status        {@link Status#WON} or {@link Status#LOST}
     * @param score         the run's final score, which for a death is negative
     * @param seconds       how long the run took
     * @param newBest       whether it beat the best for its mode
     * @param monstersLeft  monsters still face-down, which is what a death is charged for
     * @param damageTaken   health lost across the whole run, which is what a clear cost
     * @return the panel, in the outcome's colours
     */
    static EndSummary of(Status status, int score, long seconds, boolean newBest,
                         int monstersLeft, int damageTaken) {
        boolean won = status == Status.WON;
        int accent = won ? ScreenArt.GOLD : ScreenArt.OUTCOME_LOST;
        // Neither outcome has a use for the health it ended on. A clear scores
        // exactly the health you kept, so a HEALTH LEFT cell beside the score
        // would be the same number twice; what the clear cost is the figure the
        // score cannot carry, since two runs that both end on 17 are not the same
        // run if one of them bled 60 getting there. A death has no health left at
        // all, so it counts what was still waiting instead — the one figure that
        // explains how far below zero the score is.
        //
        // Both are set in OUTCOME_LOST. For damage that is the colour the health
        // bar already uses: HudArt.FILL_BLOOD is the same red.
        Cell middle = won
                ? new Cell("DAMAGE TAKEN", String.valueOf(damageTaken), ScreenArt.OUTCOME_LOST)
                : new Cell("STILL DOWN THERE", String.valueOf(monstersLeft),
                        ScreenArt.OUTCOME_LOST);
        return new EndSummary(
                won ? "THE DUNGEON RAN OUT" : "THE DUNGEON KEPT YOU",
                won ? "CLEARED" : "YOU DIED",
                accent,
                // The verdict takes the outcome's own colour, the same green and
                // blood the ledger sets CLEARED and DEFEATED in, so a run reads
                // the same here as on the row it is about to become, and the hard
                // shadow still sits under it.
                won ? ScreenArt.OUTCOME_WON : ScreenArt.OUTCOME_LOST,
                List.of(
                        // A clear's score is the number the whole run was for, and
                        // is lit accordingly. A death's is just the damage done.
                        new Cell("SCORE", String.valueOf(score),
                                won ? ScreenArt.OUTCOME_WON : ScreenArt.BODY),
                        middle,
                        new Cell("TIME", ClockText.format(seconds), ScreenArt.BODY)),
                newBest);
    }
}
