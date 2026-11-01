package com.tomer.scoundrel.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.math.Vector2;
import com.tomer.scoundrel.ScoundrelGame;
import com.tomer.scoundrel.achievements.AchievementStore;
import com.tomer.scoundrel.runs.HighScores;
import com.tomer.scoundrel.runs.RunLog;
import com.tomer.scoundrel.runs.RunRecord;

import java.util.ArrayList;
import java.util.List;

/**
 * THE LEDGER — the top runs and the lifetime figures, read once from the run log
 * on entry. Totals are labelled "finished runs" deliberately: abandoned games are
 * never recorded, so finished games are the whole universe.
 *
 * <p>Drawn in immediate mode from the menu kit ({@link Chrome}, {@link
 * ScreenArt}) like every screen outside the board. The decisions a row makes —
 * what it says and what colour it says it in — are in the pure {@link LedgerRow}
 * and {@link LedgerTotals}, so this class only places things.
 */
public final class RecordsScreen extends PixelScreen {

    /** The quiet erase control, as a hit-test id alongside {@link ScreenArt#BACK}. */
    private static final int ERASE = -3;
    /**
     * While the confirmation is up, its two buttons are the only targets — and
     * they are its own indexes, as {@link ScreenArt#dialogButtonAt} numbers them.
     */
    private static final int KEEP = 0;
    private static final int WIPE = 1;

    private final List<LedgerRow> rows;
    private final List<LedgerTotals.Stat> totals;
    private final String caption;
    private final int runs;
    private final int trophies;
    private final boolean hasProgress;
    /** The destructive confirmation, over the ledger. */
    private boolean confirming;

    /**
     * The ledger, read once on entry. A store that cannot be read is logged and
     * shown as empty rather than taking the screen down.
     *
     * @param game         the navigator, for the way back and the erase
     * @param theme        the shared fonts and textures
     * @param runLog       where the runs are read from
     * @param achievements where the trophy count, named in the erase dialog, is read from
     */
    public RecordsScreen(ScoundrelGame game, Theme theme, RunLog runLog,
                         AchievementStore achievements) {
        super(game, theme);

        List<RunRecord> records = readSafely(runLog);
        List<RunRecord> top = HighScores.top(records, ScreenArt.LEDGER_ROWS);
        List<LedgerRow> built = new ArrayList<>(top.size());
        for (int i = 0; i < top.size(); i++) {
            built.add(LedgerRow.of(i, top.get(i)));
        }
        this.rows = List.copyOf(built);
        this.totals = LedgerTotals.of(records);
        this.runs = records.size();
        this.trophies = trophyCount(achievements);
        this.hasProgress = runs > 0 || trophies > 0;
        this.caption = runs == 1 ? "1 FINISHED RUN" : runs + " FINISHED RUNS";
    }

    private static List<RunRecord> readSafely(RunLog runLog) {
        try {
            return runLog.readAll();
        } catch (RuntimeException e) {
            Gdx.app.error("scoundrel", "failed to read the run log", e);
            return List.of();
        }
    }

    private static int trophyCount(AchievementStore achievements) {
        try {
            return achievements.unlockedIds().size();
        } catch (RuntimeException e) {
            Gdx.app.error("scoundrel", "failed to read achievements", e);
            return 0;
        }
    }

    /**
     * What a window-space point is on. While the confirmation is up it is the
     * only thing that answers — a destructive dialog that let the screen behind
     * it take a press would be the worst place in the game to get that wrong.
     * {@link #modal()} is the other half of that: a click on none of these is
     * swallowed rather than passed through.
     */
    @Override
    protected int hit(int screenX, int screenY) {
        Vector2 point = unproject(screenX, screenY);
        if (confirming) {
            int button = ScreenArt.dialogButtonAt(point.x, point.y);
            return button < 0 ? PressGesture.NONE : button;
        }
        if (ScreenArt.backContains(point.x, point.y)) {
            return ScreenArt.BACK;
        }
        if (hasProgress && eraseContains(point.x, point.y)) {
            return ERASE;
        }
        return PressGesture.NONE;
    }

    @Override
    protected void activate(int target) {
        switch (target) {
            case ScreenArt.BACK -> game.showTitle();
            case ERASE -> confirming = true;
            case KEEP -> confirming = false;
            case WIPE -> {
                game.eraseAllProgress();
                game.showRecords(); // rebuild, now showing the empty ledger
            }
            default -> {
            }
        }
    }

    /** A click on nothing is swallowed while the confirmation is up. */
    @Override
    protected boolean modal() {
        return confirming;
    }

    /** Escape backs out of the dialog before it backs out of the screen. */
    @Override
    protected void escape() {
        if (confirming) {
            confirming = false;
            press.cancel();
        } else {
            game.showTitle();
        }
    }

    @Override
    protected void drawContent(float delta) {
        chrome.header(batch, "THE LEDGER", caption,
                !confirming && press.sunk() == ScreenArt.BACK);
        if (rows.isEmpty()) {
            chrome.centredOn(batch, theme.pixelLabel,
                    "NO RUNS RECORDED YET — THE DUNGEON AWAITS",
                    (int) (Theme.WORLD_WIDTH / 2), ScreenArt.EMPTY_TOP,
                    ScreenArt.BODY, ScreenArt.BODY_ALPHA);
        } else {
            drawTable();
            drawTotals();
        }
        if (hasProgress) {
            chrome.plate(batch, ScreenArt.eraseX(), ScreenArt.ERASE_Y, ScreenArt.ERASE_W,
                    ScreenArt.ERASE_H, "ERASE ALL PROGRESS", Chrome.Plate.DARK,
                    !confirming && press.sunk() == ERASE);
        }
        if (confirming) {
            drawConfirmation();
        }
    }

    /** The ten best runs, one frame around the lot of them. */
    private void drawTable() {
        int x = ScreenArt.TABLE_X;
        int h = ScreenArt.tableH(rows.size());
        chrome.frame(batch, x, ScreenArt.TABLE_Y, ScreenArt.TABLE_W, h);
        chrome.face(batch, x + ScreenArt.THICK, ScreenArt.TABLE_Y + ScreenArt.THICK,
                ScreenArt.TABLE_W - 2 * ScreenArt.THICK,
                ScreenArt.TABLE_HEAD_H - ScreenArt.THICK, ScreenArt.FRAME);

        int headY = ScreenArt.TABLE_Y + ScreenArt.THICK;
        int headH = ScreenArt.TABLE_HEAD_H - ScreenArt.THICK;
        label("RUN", ScreenArt.COL_RUN, headY, headH);
        labelRight("SCORE", ScreenArt.COL_SCORE_RIGHT, headY, headH);
        label("OUTCOME", ScreenArt.COL_OUTCOME, headY, headH);
        label("MODE", ScreenArt.COL_MODE, headY, headH);
        label("DATE", ScreenArt.COL_DATE, headY, headH);
        label("TIME", ScreenArt.COL_TIME, headY, headH);
        labelRight("SLAIN", ScreenArt.COL_SLAIN_RIGHT, headY, headH);

        for (int i = 0; i < rows.size(); i++) {
            drawRow(rows.get(i), ScreenArt.ledgerRowY(i));
        }
    }

    /**
     * Column headings are gold held back. Silkscreen has no anti-aliasing, so a
     * full-strength gold at 8px has no softened edge to take the glare off it,
     * and reads louder than a heading should.
     */
    private static final float HEADING_ALPHA = 0.75f;

    private void label(String text, int x, int y, int h) {
        chrome.textInRow(batch, theme.pixelLabel, text, x, y, h, ScreenArt.HEADING, HEADING_ALPHA);
    }

    private void labelRight(String text, int right, int y, int h) {
        chrome.textRightInRow(batch, theme.pixelLabel, text, right, y, h,
                ScreenArt.HEADING, HEADING_ALPHA);
    }

    private void drawRow(LedgerRow row, int y) {
        int inset = ScreenArt.THICK;
        chrome.face(batch, ScreenArt.TABLE_X + inset, y, ScreenArt.TABLE_W - 2 * inset,
                ScreenArt.ROW_H, row.stripe());
        int h = ScreenArt.ROW_H;
        // The numeral is a place in the list, not a reading, so it is set as
        // quiet as the mode and the date and the eye lands on the score.
        chrome.textInRow(batch, theme.pixelLabel, row.numeral(), ScreenArt.COL_RUN, y, h,
                ScreenArt.CELL_QUIET, 1f);
        chrome.textRightInRow(batch, theme.pixelBody, row.score(), ScreenArt.COL_SCORE_RIGHT,
                y, h, row.scoreColour(), 1f);
        chrome.textInRow(batch, theme.pixelLabel, row.outcome(), ScreenArt.COL_OUTCOME, y, h,
                row.outcomeColour(), 1f);
        chrome.textInRow(batch, theme.pixelLabel, row.mode(), ScreenArt.COL_MODE, y, h,
                ScreenArt.CELL_QUIET, 1f);
        chrome.textInRow(batch, theme.pixelLabel, row.date(), ScreenArt.COL_DATE, y, h,
                ScreenArt.CELL_QUIET, 1f);
        chrome.textInRow(batch, theme.pixelLabel, row.time(), ScreenArt.COL_TIME, y, h,
                ScreenArt.CELL_QUIET, 1f);
        chrome.textRightInRow(batch, theme.pixelLabel, row.slain(), ScreenArt.COL_SLAIN_RIGHT,
                y, h, ScreenArt.CELL_QUIET, 1f);
    }

    /** The lifetime figures, a gold heading over eight rows split by rules. */
    private void drawTotals() {
        chrome.frame(batch, ScreenArt.TOTALS_X, ScreenArt.TABLE_Y, ScreenArt.TOTALS_W,
                ScreenArt.TOTALS_H);
        chrome.face(batch, ScreenArt.TOTALS_X + ScreenArt.THICK,
                ScreenArt.TABLE_Y + ScreenArt.THICK,
                ScreenArt.TOTALS_W - 2 * ScreenArt.THICK,
                ScreenArt.TOTALS_H - 2 * ScreenArt.THICK, ScreenArt.FACE_TABLE);
        chrome.text(batch, theme.pixelLabel, "ACROSS ALL RUNS", ScreenArt.TOTALS_LABEL_X,
                ScreenArt.TOTALS_HEADING_TOP, ScreenArt.HEADING);

        for (int i = 0; i < totals.size(); i++) {
            LedgerTotals.Stat stat = totals.get(i);
            int y = ScreenArt.totalsRowY(i);
            chrome.textInRow(batch, theme.pixelLabel, stat.label(), ScreenArt.TOTALS_LABEL_X,
                    y, ScreenArt.TOTALS_ROW_H, ScreenArt.BODY, ScreenArt.BODY_ALPHA);
            chrome.textRightInRow(batch, theme.pixelLabelBold, stat.value(),
                    ScreenArt.TOTALS_VALUE_RIGHT, y, ScreenArt.TOTALS_ROW_H,
                    ScreenArt.BODY, 1f);
            if (i < totals.size() - 1) {
                chrome.rule(batch, ScreenArt.TOTALS_LABEL_X,
                        y + ScreenArt.TOTALS_ROW_H - ScreenArt.THICK,
                        ScreenArt.TOTALS_VALUE_RIGHT - ScreenArt.TOTALS_LABEL_X);
            }
        }
    }

    // --- the erase confirmation ---

    private static boolean eraseContains(float worldX, float worldY) {
        float bottom = CardArt.toWorldY(ScreenArt.ERASE_Y, ScreenArt.ERASE_H);
        return worldX >= ScreenArt.eraseX()
                && worldX < ScreenArt.eraseX() + ScreenArt.ERASE_W
                && worldY >= bottom && worldY < bottom + ScreenArt.ERASE_H;
    }

    /**
     * A destructive erase is never one press. The dialog names exactly what
     * will be lost, and "keep it" is the prominent choice.
     */
    private void drawConfirmation() {
        chrome.confirmation(batch, "ERASE ALL PROGRESS?",
                "THIS CLEARS " + runs + " RECORDED " + plural(runs, "RUN", "RUNS")
                        + " AND " + trophies + " " + plural(trophies, "TROPHY", "TROPHIES") + ".",
                "A BACKUP IS KEPT ON DISK. THE GAME WILL NOT RESTORE IT.",
                "KEEP IT", "ERASE EVERYTHING", press.sunk());
    }

    private static String plural(int count, String one, String many) {
        return count == 1 ? one : many;
    }

}
