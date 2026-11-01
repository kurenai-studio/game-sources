package com.tomer.scoundrel.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;
import com.tomer.scoundrel.ScoundrelGame;
import com.tomer.scoundrel.audio.AudioSettings;
import com.tomer.scoundrel.runs.HighScores;
import com.tomer.scoundrel.runs.RunLog;
import com.tomer.scoundrel.runs.RunRecord;
import com.tomer.scoundrel.runs.RunTotals;

import java.util.List;
import java.util.OptionalInt;

/**
 * The launch screen and navigation anchor. Drawn in immediate mode from the
 * menu kit ({@link Chrome}, {@link ScreenArt}) rather than by a layout engine,
 * for the same reason the board is: the art is specified as pixels at fixed
 * positions, and a layout engine's job is to compute positions.
 *
 * <p>It is the only menu carrying a sprite — The Debt, idling at ×3 in its
 * well. It is what makes the screen read as <em>this</em> game rather than a
 * card game in general, so it is not
 * decoration and should not be cut for tidiness.
 */
public final class TitleScreen extends PixelScreen {

    private static final String WORDMARK = "SCOUNDREL";
    /**
     * Forty-four: this game removes the six red face cards and the two red aces
     * from a standard deck, leaving 44 — asserted by
     * {@code StandardDeckTest.deckHasExactly44Cards}. A title screen that
     * miscounts its own deck is the first thing a player would catch.
     */
    private static final String EYEBROW = "FORTY-FOUR CARDS · ONE DESCENT";
    private static final String CAPTION = "WHAT WAITS AT THE BOTTOM";
    private static final String CREDIT =
            "DESIGNED BY ZACH GAGE & KURT BIEG — AN UNOFFICIAL IMPLEMENTATION";
    /**
     * The Debt: the Ace, and the thing at the bottom of the dungeon. The clubs
     * drawing, the red-coated one — the two suits are separate drawings, not a
     * recolour.
     */
    private static final String PORTRAIT_STEM = "creature_14_the_debt_clubs_idle";

    /** The volume plates' targets, after the menu's four in the same index space. */
    private static final int MUSIC_PLATE = 4;
    private static final int SOUND_PLATE = 5;

    private final Sprites sprites;
    private final RunLog runLog;

    private final List<Entry> menu;
    private final String bestLine;
    private float elapsed;
    /** The one-time first-run prompt, over the menu. */
    private boolean offeringTutorial;

    /** One menu row: what it says and what it does. */
    private record Entry(String label, Runnable action) {
    }

    /**
     * The title, without the first-run prompt: the way back from any other screen.
     *
     * @param game    the navigator the menu rows call
     * @param theme   the shared fonts and textures
     * @param sprites the atlas The Debt's portrait is drawn from
     * @param runLog  where the cleared count and best score under the wordmark are read
     */
    public TitleScreen(ScoundrelGame game, Theme theme, Sprites sprites, RunLog runLog) {
        this(game, theme, sprites, runLog, false);
    }

    /**
     * {@code offerTutorial} pops the one-time first-run prompt over the menu.
     *
     * @param game          the navigator the menu rows call
     * @param theme         the shared fonts and textures
     * @param sprites       the atlas The Debt's portrait is drawn from
     * @param runLog        where the cleared count and best score under the wordmark are read
     * @param offerTutorial true on the very first launch, to offer the tutorial
     */
    public TitleScreen(ScoundrelGame game, Theme theme, Sprites sprites, RunLog runLog,
                       boolean offerTutorial) {
        super(game, theme);
        this.sprites = sprites;
        this.runLog = runLog;
        this.offeringTutorial = offerTutorial;
        this.menu = List.of(
                new Entry("NEW GAME", game::showModeSelect),
                new Entry("HOW TO PLAY", game::showTutorial),
                new Entry("THE LEDGER", game::showRecords),
                new Entry("TROPHIES", game::showTrophies));
        this.bestLine = readBestLine();
    }

    /**
     * The line under the wordmark. Reading the log can fail on a corrupt file
     * and a menu must still come up, so a failure simply says nothing rather
     * than taking the screen down with it.
     */
    private String readBestLine() {
        try {
            List<RunRecord> all = runLog.readAll();
            if (all.isEmpty()) {
                return "NO RUNS YET";
            }
            // Cleared, not finished. Finishing a run is not an achievement —
            // every run finishes, most of them by dying — so counting them
            // flatters the number and says nothing. Getting out says something.
            int cleared = RunTotals.of(all).wins();
            OptionalInt best = HighScores.best(all);
            String runs = cleared == 1 ? "1 RUN CLEARED" : cleared + " RUNS CLEARED";
            return best.isPresent() ? "BEST " + best.getAsInt() + " · " + runs : runs;
        } catch (RuntimeException e) {
            Gdx.app.error("scoundrel", "could not read the run log for the title", e);
            return "";
        }
    }

    /**
     * Which button a window-space point is on, in whichever column is live —
     * the prompt is modal, so it is the only one that answers while it is up.
     * The two columns therefore share one index space.
     */
    @Override
    protected int hit(int screenX, int screenY) {
        Vector2 point = unproject(screenX, screenY);
        if (offeringTutorial) {
            return ScreenArt.promptButtonAt(point.x, point.y);
        }
        int button = ScreenArt.buttonAt(ScreenArt.COLUMN_X, menu.size(), point.x, point.y);
        if (button >= 0) {
            return button;
        }
        int plate = ScreenArt.audioPlateAt(point.x, point.y);
        return plate < 0 ? PressGesture.NONE : MUSIC_PLATE + plate;
    }

    /**
     * Every button clicks as it goes down but SOUND, which clicks when it acts, at
     * the level it has just been turned to: the click is how you hear the level
     * you chose, and at OFF it is silent.
     */
    @Override
    protected boolean clicks(int target) {
        return offeringTutorial || target != SOUND_PLATE;
    }

    /**
     * While the first-run prompt is up, nothing behind it responds — to a press
     * that misses its two buttons either.
     */
    @Override
    protected boolean modal() {
        return offeringTutorial;
    }

    /**
     * The title is where ESC goes, so here it does nothing. Every other screen
     * inherits the base's leave-to-title; this one would only rebuild itself.
     */
    @Override
    protected void escape() {
    }

    /** What a released button does. Only reached once its press has been seen. */
    @Override
    protected void activate(int index) {
        if (offeringTutorial) {
            if (index == 0) {
                game.showTutorial();
            } else {
                game.markTutorialSeen();
                offeringTutorial = false;
            }
            return;
        }
        switch (index) {
            case MUSIC_PLATE -> game.cycleMusic();
            case SOUND_PLATE -> game.cycleSound();
            default -> menu.get(index).action().run();
        }
    }

    /** The Debt's idle runs off this screen's own clock, not the backdrop's. */
    @Override
    protected void advance(float delta) {
        super.advance(delta);
        elapsed += delta;
    }

    @Override
    protected void drawContent(float delta) {
        drawPortrait();
        drawColumn();
        if (offeringTutorial) {
            drawPrompt();
        }
    }

    /** The Debt in its well, breathing on the same 6 fps clock the board uses. */
    private void drawPortrait() {
        chrome.frame(batch, ScreenArt.WELL_X, ScreenArt.WELL_Y,
                ScreenArt.wellW(), ScreenArt.wellH());
        chrome.face(batch, ScreenArt.fieldX(), ScreenArt.fieldY(),
                ScreenArt.FIELD, ScreenArt.FIELD, ScreenArt.PORTRAIT_FIELD);
        chrome.face(batch, ScreenArt.fieldX(), ScreenArt.captionY(),
                ScreenArt.FIELD, ScreenArt.CAPTION_H, ScreenArt.FRAME);

        Array<TextureRegion> frames = sprites.frames(PORTRAIT_STEM);
        TextureRegion frame = frames.get(IdleCycle.frameIndex(elapsed, 0f, frames.size, true));
        batch.draw(frame, ScreenArt.portraitX(),
                CardArt.toWorldY(ScreenArt.portraitY(), ScreenArt.PORTRAIT),
                ScreenArt.PORTRAIT, ScreenArt.PORTRAIT);

        chrome.centredOn(batch, theme.pixelSmall, CAPTION,
                ScreenArt.fieldX() + ScreenArt.FIELD / 2,
                ScreenArt.captionY() + 6, ScreenArt.CAPTION, 1f);
    }

    private void drawColumn() {
        int x = ScreenArt.COLUMN_X;
        chrome.text(batch, theme.pixelLabel, EYEBROW, x, ScreenArt.EYEBROW_TOP,
                ScreenArt.HEADING);

        // 52px is the 26px face at x2 -- a whole multiple, so the wordmark is
        // pixel-exact without a sixth font size. The shadow is the same glyphs
        // moved down four whole pixels, not a blur.
        theme.pixelTitle.getData().setScale(2f);
        chrome.text(batch, theme.pixelTitle, WORDMARK, x,
                ScreenArt.WORDMARK_TOP + ScreenArt.WORDMARK_SHADOW_DY,
                ScreenArt.WORDMARK_SHADOW);
        chrome.text(batch, theme.pixelTitle, WORDMARK, x, ScreenArt.WORDMARK_TOP,
                ScreenArt.BODY);
        theme.pixelTitle.getData().setScale(1f);

        chrome.rule(batch, x, ScreenArt.TITLE_RULE_Y, ScreenArt.BUTTON_W,
                ScreenArt.TITLE_RULE);
        chrome.text(batch, theme.pixelLabel, bestLine, x, ScreenArt.BEST_TOP,
                ScreenArt.BODY, ScreenArt.BODY_ALPHA);

        // The prompt owns the press while it is up, and the two columns share an
        // index space, so the menu behind it must not sink a button of its own.
        int sunk = offeringTutorial ? PressGesture.NONE : press.sunk();
        for (int i = 0; i < menu.size(); i++) {
            // The first is gold, the rest dark: one thing to do, and three
            // places to look at first.
            chrome.plate(batch, x, ScreenArt.buttonY(i), ScreenArt.BUTTON_W,
                    ScreenArt.BUTTON_H, menu.get(i).label(),
                    i == 0 ? Chrome.Plate.GOLD : Chrome.Plate.DARK, i == sunk);
        }
        drawVolume(sunk);

        chrome.centredOn(batch, theme.pixelSmall, CREDIT, (int) (Theme.WORLD_WIDTH / 2),
                ScreenArt.CREDIT_TOP, ScreenArt.BODY, ScreenArt.CREDIT_ALPHA);
    }

    /**
     * MUSIC and SOUND, one row under the menu, each showing its level as pips, and
     * under them the line that says what M does, built from the menu's own
     * measures and parts.
     */
    private void drawVolume(int sunk) {
        AudioSettings volume = game.audioSettings();
        chrome.levelPlate(batch, ScreenArt.audioPlateX(0), "MUSIC", volume.music(), volume.muted(),
                sunk == MUSIC_PLATE);
        chrome.levelPlate(batch, ScreenArt.audioPlateX(1), "SOUND", volume.sound(), volume.muted(),
                sunk == SOUND_PLATE);
        chrome.centredOn(batch, theme.pixelSmall, Labels.muteHint(volume.muted()),
                ScreenArt.COLUMN_X + ScreenArt.BUTTON_W / 2, ScreenArt.MUTE_HINT_TOP,
                ScreenArt.BODY, ScreenArt.BODY_ALPHA);
    }

    // --- the first-run prompt ---

    /**
     * The one-time welcome, shown over the menu on the very first launch. Both
     * choices mark the tutorial seen, so it never nags twice.
     *
     * <p>It is built from the same five parts as everything else, with its own
     * geometry in {@link ScreenArt} rather than the menu column's: the column's
     * {@code buttonY} would put the first plate straight through the second line
     * of its own copy.
     */
    private void drawPrompt() {
        // The menu behind has to stop competing — the prompt is a question, and
        // there are four other things on screen inviting a click.
        chrome.dim(batch);
        int x = ScreenArt.promptX();
        chrome.frame(batch, x, ScreenArt.PROMPT_Y, ScreenArt.PROMPT_W, ScreenArt.PROMPT_H);
        chrome.face(batch, x + ScreenArt.THICK, ScreenArt.PROMPT_Y + ScreenArt.THICK,
                ScreenArt.PROMPT_W - 2 * ScreenArt.THICK,
                ScreenArt.PROMPT_H - 2 * ScreenArt.THICK, ScreenArt.FACE_PANEL);
        int centre = (int) (Theme.WORLD_WIDTH / 2);
        chrome.centredOn(batch, theme.pixelBody, "NEW HERE?", centre,
                ScreenArt.PROMPT_Y + ScreenArt.PROMPT_HEADING_DY, ScreenArt.HEADING, 1f);
        chrome.centredOn(batch, theme.pixelLabel,
                "SCOUNDREL HAS A FEW RULES WORTH KNOWING.", centre,
                ScreenArt.PROMPT_Y + ScreenArt.PROMPT_LINE_DY,
                ScreenArt.BODY, ScreenArt.BODY_ALPHA);
        chrome.centredOn(batch, theme.pixelLabel,
                "A SHORT GUIDED RUN WALKS THROUGH ALL OF THEM.", centre,
                ScreenArt.PROMPT_Y + ScreenArt.PROMPT_LINE_DY + ScreenArt.PROMPT_LINE_GAP,
                ScreenArt.BODY, ScreenArt.BODY_ALPHA);
        int sunk = press.sunk();
        chrome.plate(batch, ScreenArt.promptButtonX(), ScreenArt.promptButtonY(0),
                ScreenArt.BUTTON_W, ScreenArt.BUTTON_H, "PLAY TUTORIAL",
                Chrome.Plate.GOLD, sunk == 0);
        chrome.plate(batch, ScreenArt.promptButtonX(), ScreenArt.promptButtonY(1),
                ScreenArt.BUTTON_W, ScreenArt.BUTTON_H, "MAYBE LATER",
                Chrome.Plate.DARK, sunk == 1);
    }

}
