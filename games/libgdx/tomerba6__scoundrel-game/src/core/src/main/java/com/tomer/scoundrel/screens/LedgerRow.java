package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.GameMode;
import com.tomer.scoundrel.rules.GameModes;
import com.tomer.scoundrel.runs.RunRecord;

import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

/**
 * One row of THE LEDGER, worked out before anything is drawn: the seven strings
 * the columns hold, the two colours that carry meaning, and which stripe the row
 * sits on.
 *
 * <p>Pure, so the decisions are asserted rather than screenshotted — a score
 * that coloured itself wrong, or an outcome that read "cleared" for a death,
 * would be almost invisible in a render and obvious in a test. The screen is
 * left with nothing but the placing.
 *
 * @param numeral       the rank as a Roman numeral, {@code I} to {@code X}
 * @param score         the score as printed
 * @param scoreColour   {@code 0xRRGGBB}: {@link ScreenArt#SCORE_NEGATIVE} below zero,
 *                      {@link ScreenArt#SCORE_POSITIVE} from zero up
 * @param outcome       {@code CLEARED} or {@code DEFEATED}
 * @param outcomeColour {@code 0xRRGGBB} for the outcome word
 * @param mode          the mode's title, upper-cased, or the raw id if it is unknown
 * @param date          the day it ended, e.g. {@code SEP 29}, in the local zone
 * @param time          the run's length, as {@link ClockText} prints it
 * @param slain         monsters defeated, as printed
 * @param stripe        {@code 0xRRGGBB} of the row's background, alternating
 */
record LedgerRow(String numeral, String score, int scoreColour, String outcome,
                 int outcomeColour, String mode, String date, String time,
                 String slain, int stripe) {

    /**
     * Ten, because the table draws ten. Beyond that a numeral would be a silent
     * blank, so there is deliberately no rule for continuing the sequence — if
     * the table ever grows, this has to be extended on purpose.
     */
    private static final String[] NUMERALS =
            {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"};

    private static final DateTimeFormatter DAY =
            DateTimeFormatter.ofPattern("MMM d", Locale.ENGLISH).withZone(ZoneId.systemDefault());

    /**
     * The row for one run.
     *
     * @param index the run's place in the table, from 0 (the best) to 9
     * @param run   the run
     * @return everything the table draws for it
     * @throws ArrayIndexOutOfBoundsException if {@code index} is past the tenth row
     */
    static LedgerRow of(int index, RunRecord run) {
        boolean won = run.outcome() == Status.WON;
        return new LedgerRow(
                NUMERALS[index],
                String.valueOf(run.score()),
                // Zero is not a loss: it is only reachable by clearing the
                // dungeon on the last point of health, which is the best story
                // the table has to tell.
                run.score() < 0 ? ScreenArt.SCORE_NEGATIVE : ScreenArt.SCORE_POSITIVE,
                won ? "CLEARED" : "DEFEATED",
                won ? ScreenArt.OUTCOME_WON : ScreenArt.OUTCOME_LOST,
                modeLabel(run.rulesetId()),
                DAY.format(run.endedAt()).toUpperCase(Locale.ROOT),
                ClockText.format(run.seconds()),
                String.valueOf(run.monstersDefeated()),
                index % 2 == 0 ? ScreenArt.ROW_ODD : ScreenArt.ROW_EVEN);
    }

    /**
     * Scores are ranked per mode, so a row has to say which one it was set in.
     * A retired or unknown id survives as itself rather than taking the screen
     * down — a ledger that will not open is worse than a row reading {@code
     * chaos}.
     */
    private static String modeLabel(String rulesetId) {
        return GameModes.byId(rulesetId).map(GameMode::title).orElse(rulesetId)
                .toUpperCase(Locale.ROOT);
    }
}
