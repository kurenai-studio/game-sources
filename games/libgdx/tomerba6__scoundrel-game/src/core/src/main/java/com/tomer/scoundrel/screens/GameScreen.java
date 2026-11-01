package com.tomer.scoundrel.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Align;
import com.tomer.scoundrel.ScoundrelGame;
import com.tomer.scoundrel.achievements.Achievement;
import com.tomer.scoundrel.achievements.AchievementContext;
import com.tomer.scoundrel.achievements.AchievementService;
import com.tomer.scoundrel.achievements.AchievementStore;
import com.tomer.scoundrel.achievements.AchievementTracker;
import com.tomer.scoundrel.achievements.Achievements;
import com.tomer.scoundrel.achievements.RunSummary;
import com.tomer.scoundrel.achievements.UnlockedAchievement;
import com.tomer.scoundrel.audio.Sfx;
import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.model.EquippedWeapon;
import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.GameEvent;
import com.tomer.scoundrel.rules.GameMode;
import com.tomer.scoundrel.rules.Move;
import com.tomer.scoundrel.rules.MoveResult;
import com.tomer.scoundrel.rules.Ruleset;
import com.tomer.scoundrel.rules.ScoundrelEngine;
import com.tomer.scoundrel.runs.HighScores;
import com.tomer.scoundrel.runs.RunLog;
import com.tomer.scoundrel.runs.RunRecord;
import com.tomer.scoundrel.runs.RunRecorder;
import com.tomer.scoundrel.tutorial.TutorialGuide;
import com.tomer.scoundrel.tutorial.TutorialScript;
import com.tomer.scoundrel.tutorial.TutorialStep;

import java.time.Clock;
import java.util.List;
import java.util.Locale;
import java.util.OptionalInt;
import java.util.Random;


/**
 * The one in-game screen: draws the current GameState and translates clicks
 * into engine moves. Contains no rule logic — everything it knows about the
 * game comes from the state, the ruleset, and legalMoves().
 *
 * <p>The board itself is drawn in immediate mode, straight onto a batch at the
 * design resolution, because the art is specified as pixels at fixed positions
 * and a layout engine's job is to compute positions. The overlays with buttons —
 * the end panel, the move chooser, the tutorial callout — are drawn the same
 * way on the menu kit ({@link Chrome}) and hit-tested by this screen; there is
 * no stage under any of them.
 */
public final class GameScreen extends PixelScreen {

    /** Dried blood, the one colour YOU DIED is ever set in. */
    private static final Color DEATH_TITLE = new Color((0x8c2f22 << 8) | 0xff);
    private static final String DEATH_TITLE_TEXT = "YOU DIED";

    private final GameMode mode;
    private final Ruleset rules;
    private final ScoundrelEngine engine;
    private final RunLog runLog;
    private final AchievementStore achievements;
    private final TutorialGuide tutorial; // null unless this is the guided tutorial

    private final BoardView board;
    private final BoardHud hud;
    private final Sprites sprites;
    private final Feed feed = new Feed();
    /** Measures the death title, so it can be placed by its centre. */
    private final GlyphLayout titleLayout = new GlyphLayout();

    private GameState state;
    private RunRecorder recorder;
    /** Frozen off the finished record, so the panel quotes exactly what was filed. */
    private long finalRunSeconds;
    private int finalDamageTaken;
    private AchievementTracker tracker;
    private String endBestLine;
    private List<Achievement> newlyUnlocked = List.of();
    /** The run-end panel, built once the run settles; null while it is still on. */
    private EndSummary endSummary;
    /** The tutorial's callout is up whenever the guide has a beat left to show. */
    private boolean calloutUp;
    /** ESC asked whether to abandon the run, and the question is still up. */
    private boolean asking;
    /** The open move chooser: the moves offered, and the card they are about. */
    private List<Move> chooserMoves = List.of();
    private Card chooserCard;
    private int chooserPlateW;
    /** The last potion drunk, which is what the marker shows once one has been. */
    private Card lastPotion;
    /** What was in the rail before this move, for as long as the new one is in the air. */
    private EquippedWeapon weaponBeforeMove;

    // --- what the health bar is doing, and the death ---

    /** What the health bar is doing, what it is doing it between, and since when. */
    private HealthReadout.Phase barPhase = HealthReadout.Phase.REST;
    private HealthReadout.Change barChange = HealthReadout.Change.NONE;
    private float barElapsed;
    /** The death cinematic's clock and the slot the fatal blow landed in. */
    private float deathElapsed = -1f;
    private int killerSlotX = -1;
    /** Withheld until the cinematic ends, so the score does not pre-empt it. */
    private boolean endPending;

    /**
     * A normal run in the given mode, recorded to the run log.
     *
     * @param game         the navigator, for the sounds, the music and the way out
     * @param theme        the shared fonts and textures
     * @param sprites      the shared sprite atlas
     * @param runLog       where the finished run is appended
     * @param achievements where newly earned trophies are latched, if the mode tracks them
     * @param mode         the difficulty, whose ruleset the run is played on
     */
    public GameScreen(ScoundrelGame game, Theme theme, Sprites sprites, RunLog runLog,
                      AchievementStore achievements, GameMode mode) {
        this(game, theme, sprites, runLog, achievements, mode, null);
    }

    /**
     * The guided tutorial: a scripted deck with narration, never recorded.
     *
     * @param game     the navigator, for the sounds, the music and the way out
     * @param theme    the shared fonts and textures
     * @param sprites  the shared sprite atlas
     * @param mode     the ruleset to play the script on (Standard)
     * @param tutorial the guide that narrates the script and gates the moves
     */
    public GameScreen(ScoundrelGame game, Theme theme, Sprites sprites,
                      GameMode mode, TutorialGuide tutorial) {
        this(game, theme, sprites, null, null, mode, tutorial);
    }

    private GameScreen(ScoundrelGame game, Theme theme, Sprites sprites, RunLog runLog,
                       AchievementStore achievements, GameMode mode, TutorialGuide tutorial) {
        super(game, theme);
        this.sprites = sprites;
        this.runLog = runLog;
        this.achievements = achievements;
        this.mode = mode;
        this.tutorial = tutorial;
        this.rules = mode.ruleset();
        this.engine = new ScoundrelEngine(rules);
        this.board = new BoardView(theme, sprites, game.sounds());
        this.hud = new BoardHud(theme);
        startRun();
        board.dealFresh(state.room());
        syncBoard();
    }

    @Override
    public void show() {
        // One processor: the overlays are drawn by this screen, so they are
        // hit-tested by it too, ahead of the board.
        Gdx.input.setInputProcessor(new BoardInput());
    }

    /** Clicks on an overlay first, then the board: a card, or the Avoid plate. */
    private final class BoardInput extends InputAdapter {
        @Override
        public boolean touchDown(int screenX, int screenY, int pointer, int button) {
            if (button != Input.Buttons.LEFT) {
                return false;
            }
            // A click through a cinematic settles it. The state underneath is
            // already final, so skipping is always safe — and the same click
            // still resolves whatever it landed on, so none is ever spent
            // purely on dismissing motion.
            if (deathElapsed >= 0f) {
                settleEnd();
                return true;
            }
            // The overlays are buttons, so they act on release like every other
            // button — but only the run end and the abandon question are modal.
            // The tutorial's callout deliberately lets everything except Skip and
            // Next through, since playing the board is the whole point of it.
            if (pressAt(overlayHit(screenX, screenY)) || endSummary != null || asking) {
                return true;
            }
            Vector2 point = viewport.unproject(new Vector2(screenX, screenY));
            // An open chooser takes the press first. One that lands on a plate
            // resolves it; one that lands anywhere else dismisses the chooser
            // AND still resolves whatever card it hit, so a press is never
            // spent merely closing the popup.
            if (chooserCard != null) {
                int picked = ChooserArt.indexAt(chooserSlotX(), chooserPlateW,
                        chooserMoves.size(), point.x, point.y);
                List<Move> offered = chooserMoves;
                closeChooser();
                if (picked >= 0) {
                    applyMove(offered.get(picked));
                    return true;
                }
            }
            if (board.isPlaying()) {
                board.skip();
            }
            if (state.status() != Status.IN_PROGRESS) {
                return false;
            }
            if (HudArt.avoidContains(point.x, point.y) && avoidAllowed()) {
                applyMove(new Move.AvoidRoom());
                return true;
            }
            Card card = board.cardAt(point.x, point.y);
            if (card != null) {
                onCardClicked(card);
                return true;
            }
            return false;
        }

        @Override
        public boolean touchDragged(int screenX, int screenY, int pointer) {
            press.moveOver(overlayHit(screenX, screenY));
            return false;
        }

        @Override
        public boolean touchUp(int screenX, int screenY, int pointer, int button) {
            if (button != Input.Buttons.LEFT) {
                return false;
            }
            return press.release(overlayHit(screenX, screenY)) || endSummary != null || asking;
        }

        /**
         * This processor replaces the frame's, so ESC is routed here by hand —
         * without it, a run could only be left by finishing it.
         */
        @Override
        public boolean keyDown(int keycode) {
            if (keycode != Input.Keys.ESCAPE) {
                return false;
            }
            escape();
            return true;
        }
    }

    /**
     * Backs out of the innermost thing first, and never throws a live run away
     * on one press — {@link BoardEscape} decides which, and is tested for it.
     */
    @Override
    protected void escape() {
        BoardEscape.Action action = BoardEscape.of(asking, deathElapsed >= 0f,
                state.status() != Status.IN_PROGRESS, chooserCard != null, tutorial != null);
        switch (action) {
            case ASK -> {
                asking = true;
                press.cancel();
            }
            case CLOSE_DIALOG -> {
                asking = false;
                press.cancel();
            }
            case CLOSE_CHOOSER -> closeChooser();
            case SETTLE -> settleEnd();
            case LEAVE -> game.showTitle();
        }
    }

    // --- what the overlays offer, and what a press on one does ---

    private static final int SKIP = -3;
    private static final int NEXT = -4;
    /** The abandon question's two plates, safe one first. */
    private static final int KEEP_PLAYING = -5;
    private static final int ABANDON = -6;

    /** The four ways on from a finished run, left to right. */
    private static final List<String> END_BUTTONS =
            List.of("NEW GAME", "MAIN MENU", "TROPHIES", "THE LEDGER");
    /** The tutorial's own two, which go somewhere gentler than a fresh run. */
    private static final List<String> TUTORIAL_END_BUTTONS =
            List.of("PLAY FOR REAL", "MAIN MENU");

    private List<String> endButtons() {
        return tutorial != null ? TUTORIAL_END_BUTTONS : END_BUTTONS;
    }

    private List<ButtonRow.Slot> endSlots() {
        return ButtonRow.lay(endButtons(), ScreenArt.END_X, ScreenArt.END_W,
                ScreenArt.END_BUTTON_GAP,
                label -> chrome.width(theme.pixelLabel, label) + 2 * ScreenArt.END_BUTTON_PAD_X);
    }

    /**
     * What a window-space point is on, in whichever overlay is up. One id space:
     * the end panel's buttons are their own index, the tutorial's two controls
     * and the abandon question's two take the negatives below {@code -1}.
     */
    private int overlayHit(int screenX, int screenY) {
        Vector2 point = unproject(screenX, screenY);
        if (asking) {
            int button = ScreenArt.dialogButtonAt(point.x, point.y);
            return button == 0 ? KEEP_PLAYING : button == 1 ? ABANDON : PressGesture.NONE;
        }
        if (endSummary != null) {
            float bottom = CardArt.toWorldY(
                    ScreenArt.endButtonsY(!newlyUnlocked.isEmpty()), ScreenArt.END_BUTTON_H);
            return ButtonRow.indexAt(endSlots(), bottom, ScreenArt.END_BUTTON_H,
                    point.x, point.y);
        }
        if (calloutUp) {
            if (contains(point, ScreenArt.skipX(), ScreenArt.SKIP_Y,
                    ScreenArt.SKIP_W, ScreenArt.SKIP_H)) {
                return SKIP;
            }
            CalloutPlacement.Plate next = nextPlate();
            if (next != null
                    && contains(point, next.x(), next.y(), next.w(), next.h())) {
                return NEXT;
            }
        }
        return PressGesture.NONE;
    }

    private static boolean contains(Vector2 point, int x, int y, int w, int h) {
        float bottom = CardArt.toWorldY(y, h);
        return point.x >= x && point.x < x + w && point.y >= bottom && point.y < bottom + h;
    }

    /** What a released overlay button does. Only reached once its press has been seen. */
    private void activateOverlay(int target) {
        if (target == KEEP_PLAYING) {
            asking = false;
            return;
        }
        // Nothing is recorded: a run is filed only when it ends, so walking away
        // leaves the ledger and the trophies exactly as closing the window would.
        if (target == SKIP || target == ABANDON) {
            game.showTitle();
            return;
        }
        if (target == NEXT) {
            tutorial.next();
            syncBoard();
            return;
        }
        String label = endButtons().get(target);
        switch (label) {
            case "NEW GAME" -> startNewGame();
            case "PLAY FOR REAL" -> game.showModeSelect();
            case "MAIN MENU" -> game.showTitle();
            case "TROPHIES" -> game.showTrophies();
            default -> game.showRecords();
        }
    }

    @Override
    protected int hit(int screenX, int screenY) {
        return overlayHit(screenX, screenY);
    }

    /**
     * The end panel's buttons click, like any menu's: the run is over. The
     * tutorial callout's SKIP and NEXT do not — they are pressed mid-run, where
     * buttons are silent (the ids below {@code -1}).
     */
    @Override
    protected boolean clicks(int target) {
        return target >= 0;
    }

    @Override
    protected void activate(int target) {
        activateOverlay(target);
    }

    /** The torch gutters out as the death plays; every other screen burns at 1. */
    @Override
    protected float backdropLight() {
        return deathElapsed >= 0f ? DeathCinematic.torchLight(deathElapsed) : 1f;
    }

    @Override
    protected void drawContent(float delta) {
        // The death shakes the board but not the dark it happens in, so the
        // backdrop — drawn by the base, before this — never takes the jolt.
        int shake = deathElapsed >= 0f ? DeathCinematic.shakeX(deathElapsed) : 0;
        batch.getTransformMatrix().translate(shake, 0, 0);
        batch.setTransformMatrix(batch.getTransformMatrix());
        drawHud();
        board.draw(batch);
        drawChooser();
        drawFeed();
        batch.getTransformMatrix().translate(-shake, 0, 0);
        batch.setTransformMatrix(batch.getTransformMatrix());
        if (deathElapsed >= 0f) {
            drawDeath();
        }
        // The overlays are drawn onto the surface with everything else, so they
        // land on the same pixel grid the board does; drawn to the window, they
        // would sit at a different scale and miss the board's edges.
        if (endSummary != null) {
            drawEndPanel();
        } else if (calloutUp) {
            drawTutorialOverlay();
        }
        if (asking) {
            int sunk = press.sunk();
            chrome.confirmation(batch, "ABANDON THIS RUN?",
                    "IT WILL NOT BE RECORDED IN THE LEDGER,",
                    "AND IT CANNOT EARN ANY TROPHIES.",
                    "KEEP PLAYING", "ABANDON RUN",
                    sunk == KEEP_PLAYING ? 0 : sunk == ABANDON ? 1 : PressGesture.NONE);
        }
    }

    /**
     * Moves every clock on: the board, the bar, the feed and the death. Named
     * apart from the base's {@code advance} hook, which this overrides to call
     * it — the backdrop is one of the clocks it already moves.
     */
    @Override
    protected void advance(float delta) {
        advanceClocks(delta);
    }

    private void advanceClocks(float delta) {
        backdrop.advance(delta);
        board.update(delta);
        feed.update(delta);
        board.setHovered(hoveredCard());
        advanceBar(delta);
        if (deathElapsed >= 0f) {
            deathElapsed += delta;
            if (DeathCinematic.finished(deathElapsed)) {
                deathElapsed = -1f;
                settleEnd();
            }
        }
    }

    /** The card under the pointer, so only it animates. */
    private Card hoveredCard() {
        if (state.status() != Status.IN_PROGRESS || endSummary != null || asking) {
            return null;
        }
        Vector2 point = viewport.unproject(
                new Vector2(Gdx.input.getX(), Gdx.input.getY()));
        return board.cardAt(point.x, point.y);
    }

    private void drawHud() {
        drawHealth();
        drawDepthGauge();
        hud.drawAvoid(batch, avoidAllowed());
        drawRail();
        hud.drawPotionMarker(batch, potionMarkerRegion(),
                state.potionsUsedThisRoom() >= rules.potionsPerTurn());
    }

    /** The ticks and the line under them — the one gauge of how far you got. */
    private void drawDepthGauge() {
        int depth = shownDepth();
        hud.drawTicker(batch, depth, rules.deck().cards().size());
        hud.drawDepthLine(batch, depth,
                tutorial == null ? ClockText.format(currentRunSeconds()) : null);
    }

    /**
     * How deep the dungeon looks, which is not always how deep it is. The engine
     * settles the whole move at once, so its count drops before a single card
     * has moved; on screen a card is only back in the deck once it has flown
     * there, and only out of it once it has landed on the table.
     *
     * <p>Both corrections are needed and they run in opposite directions, which
     * is what makes an avoided room read properly: the strip grows by four as
     * the old room goes in, then shrinks by four as the new one comes out, and
     * ends exactly where the engine says it should.
     */
    private int shownDepth() {
        return state.dungeon().size() + board.rising() - board.sweeping();
    }

    /**
     * The bar's clock. Only a change runs one — a bar at rest, or one holding
     * for a bottle that has not landed, has nothing to advance.
     */
    private void advanceBar(float delta) {
        if (barPhase != HealthReadout.Phase.HEALING
                && barPhase != HealthReadout.Phase.BLEEDING) {
            return;
        }
        barElapsed += delta;
        boolean over = barPhase == HealthReadout.Phase.HEALING
                ? HpPulse.healFinished(barChange.fromWidth(), barChange.toWidth(), barElapsed)
                : HpPulse.damageFinished(barChange.fromWidth(), barChange.toWidth(), barElapsed);
        if (over) {
            barPhase = HealthReadout.Phase.REST;
        }
    }

    /** The bar, mid-change, holding, or at rest — the decision is out in {@link HealthReadout}. */
    private void drawHealth() {
        HealthReadout readout = HealthReadout.of(
                barPhase, state.health(), rules.healthCap(), barChange, barElapsed);
        hud.drawHealth(batch, readout.number(), rules.healthCap(),
                readout.healing(), readout.bleeding(), readout.offsetX(), readout.fill());
    }

    /**
     * Dying: a red flare over whatever killed you, the board shaking (applied
     * by the caller), and the screen going out by ordered dither with YOU DIED
     * growing over it. Pattern, never alpha — the board thins out rather than
     * dimming, so it reads as the game failing and not as a dialog covering it.
     */
    private void drawDeath() {
        if (DeathCinematic.flaring(deathElapsed) && killerSlotX >= 0) {
            batch.setColor(0.55f, 0.18f, 0.13f, DeathCinematic.flareStrength(deathElapsed));
            batch.draw(theme.whiteRegion(), killerSlotX,
                    CardArt.toWorldY(CardArt.SLOT_Y, CardArt.CARD_H),
                    CardArt.CARD_W, CardArt.CARD_H);
            batch.setColor(1f, 1f, 1f, 1f);
        }
        int level = DeathCinematic.ditherLevel(deathElapsed);
        if (level > 0) {
            batch.draw(board.dither(level, (int) Theme.WORLD_WIDTH, (int) Theme.WORLD_HEIGHT),
                    0, 0, Theme.WORLD_WIDTH, Theme.WORLD_HEIGHT);
        }
        // Over the dither, not under it: the dark takes the whole board and
        // leaves the gauge that says how close you got, until that goes too.
        if (DeathCinematic.tickerShowing(deathElapsed)) {
            drawDepthGauge();
        }
        if (DeathCinematic.titleShowing(deathElapsed)) {
            // Whole multiples only, and placed by its own centre so it grows
            // outward from a fixed line instead of downward from a fixed top.
            // The smallest face in the game, blown up by a whole number. The
            // multiples are the only clean sizes there are, so the smaller the
            // face the more of them fit between "far away" and "in your face".
            BitmapFont font = theme.pixelSmall;
            font.getData().setScale(DeathCinematic.titleZoom(deathElapsed));
            titleLayout.setText(font, DEATH_TITLE_TEXT);
            int top = BoardArt.DEATH_TITLE_CENTRE_Y - Math.round(titleLayout.height / 2f);
            font.setColor(DEATH_TITLE);
            font.draw(batch, DEATH_TITLE_TEXT, 0, CardArt.toWorldY(top, 0),
                    Theme.WORLD_WIDTH, Align.center, false);
            font.getData().setScale(1f);
            font.setColor(Color.WHITE);
        }
    }

    /** The cinematic is over (or was clicked through): show the score. */
    private void settleEnd() {
        game.music().settled(); // the end panel is up: the death cue now, if it has not played
        deathElapsed = -1f;
        if (endPending) {
            endPending = false;
            syncBoard();
        }
    }

    /**
     * Equipped weapon, its slain stack, and how much bite it has left — as the
     * board shows it, not as the engine has already settled it. A weapon still
     * hopping down to the well has not arrived, and a monster still being
     * cleaved has not died, so neither the icon nor the chip beside it may
     * appear yet.
     */
    private void drawRail() {
        EquippedWeapon weapon = board.railAhead() ? weaponBeforeMove : state.weapon();
        if (weapon == null) {
            hud.drawRail(batch, null, "BAREHANDED", null, null);
            return;
        }
        Card held = weapon.weapon();
        hud.drawRail(batch, sprites.region(CardSprites.regionName(held)),
                CardSprites.displayName(held) + " " + held.value(),
                weapon.slain(),
                Labels.weaponThreshold(weapon).toUpperCase(Locale.ROOT));
    }

    /**
     * The marker shows the potion you drank once you have drunk one, and a
     * plain draught while the room's is still going. Never dimmed: an alpha
     * over the dark board would make colours that are on no ramp.
     */
    private TextureRegion potionMarkerRegion() {
        Card shown = lastPotion != null && state.potionsUsedThisRoom() > 0
                ? lastPotion
                : new Card("5H", CardType.POTION, 5);
        return sprites.region(CardSprites.regionName(shown));
    }

    private void drawFeed() {
        for (int i = 0; i < feed.size(); i++) {
            hud.drawFeedLine(batch, feed.textAt(i), i, feed.alphaAt(i));
        }
    }

    @Override
    public void dispose() {
        // This screen's own first, then the frame's — the base frees the surface
        // and the batch the board was drawing into.
        board.dispose();
        super.dispose();
    }

    /**
     * Pushes the current state onto the board and rebuilds whichever overlay
     * belongs on top of it. Called after every move; the board itself is drawn
     * from the state each frame, so there is nothing else to rebuild.
     */
    private void syncBoard() {
        board.setRoom(state.room());
        // The room it was anchored to has just changed under it.
        closeChooser();
        // A press held on the old overlay must not act on whatever replaces it.
        press.cancel();
        endSummary = null;
        calloutUp = false;
        if (state.status() != Status.IN_PROGRESS) {
            endSummary = tutorial != null
                    ? EndSummary.tutorial(state.score(), state.health())
                    : EndSummary.of(state.status(), state.score(), finalRunSeconds,
                            "New best!".equals(endBestLine),
                            state.monstersRemaining(), finalDamageTaken);
        } else {
            calloutUp = tutorial != null && !tutorial.isComplete();
        }
    }

    /** Whether Avoid is live: the tutorial gates it, otherwise the rules do. */
    private boolean avoidAllowed() {
        return tutorial != null
                ? tutorialExpects(new Move.AvoidRoom())
                : engine.legalMoves(state).contains(new Move.AvoidRoom());
    }


    private void startNewGame() {
        startRun();
        feed.clear();
        board.dealFresh(state.room());
        syncBoard();
        game.music().enterRun(); // from the end panel: the run track from the top
    }

    // --- the run-end panel ---

    /**
     * One panel over the modal dim, covering both outcomes — a death is the
     * same layout with the gold accents swapped to dried blood, so there is one
     * method here and not two.
     */
    private void drawEndPanel() {
        boolean withTrophies = !newlyUnlocked.isEmpty();
        int top = ScreenArt.endY(withTrophies);
        int h = ScreenArt.endH(withTrophies);
        chrome.dim(batch);
        chrome.frame(batch, ScreenArt.END_X, top, ScreenArt.END_W, h);
        chrome.face(batch, ScreenArt.END_X + ScreenArt.THICK, top + ScreenArt.THICK,
                ScreenArt.END_W - 2 * ScreenArt.THICK, h - 2 * ScreenArt.THICK,
                ScreenArt.FACE_PANEL);

        int centre = ScreenArt.END_X + ScreenArt.END_W / 2;
        chrome.centredOn(batch, theme.pixelLabel, endSummary.eyebrow(), centre,
                top + ScreenArt.END_EYEBROW_DY, endSummary.accent(), 1f);
        // A hard offset, not a blur — the same rule the wordmark follows.
        chrome.centredOn(batch, theme.pixelDisplay, endSummary.headline(), centre,
                top + ScreenArt.END_HEADLINE_DY + ScreenArt.END_HEADLINE_SHADOW_DY,
                ScreenArt.WORDMARK_SHADOW, 1f);
        chrome.centredOn(batch, theme.pixelDisplay, endSummary.headline(), centre,
                top + ScreenArt.END_HEADLINE_DY, endSummary.headlineColour(), 1f);

        drawEndStats(top);
        if (endSummary.newBest()) {
            String badge = "NEW BEST";
            int w = chrome.width(theme.pixelLabel, badge) + 2 * ScreenArt.END_BADGE_PAD_X;
            int x = centre - w / 2;
            int y = top + ScreenArt.END_BADGE_DY;
            chrome.face(batch, x, y, w, ScreenArt.END_BADGE_H, endSummary.accent());
            chrome.centred(batch, theme.pixelLabel, badge, x, y, w,
                    ScreenArt.END_BADGE_H, ScreenArt.GOLD_LABEL, 1f);
        }
        // The rule only separates the trophy band from what is above it, so with
        // no trophies there is nothing for it to separate.
        if (withTrophies) {
            chrome.rule(batch, ScreenArt.END_RULE_X, top + ScreenArt.END_RULE_DY,
                    ScreenArt.END_RULE_W);
            drawUnlocked(top);
        }

        int sunk = press.sunk();
        List<ButtonRow.Slot> slots = endSlots();
        int buttonsY = ScreenArt.endButtonsY(withTrophies);
        for (int i = 0; i < slots.size(); i++) {
            ButtonRow.Slot slot = slots.get(i);
            chrome.plate(batch, slot.x(), buttonsY, slot.width(),
                    ScreenArt.END_BUTTON_H, slot.label(),
                    i == 0 ? Chrome.Plate.GOLD : Chrome.Plate.DARK, i == sunk);
        }
    }

    /** Three figures in one shared frame, split by 2px dividers. */
    private void drawEndStats(int top) {
        int y = top + ScreenArt.END_STATS_DY;
        chrome.frame(batch, ScreenArt.END_STATS_X, y,
                ScreenArt.END_STATS_W, ScreenArt.END_STATS_H);
        chrome.face(batch, ScreenArt.END_STATS_X + ScreenArt.THICK, y + ScreenArt.THICK,
                ScreenArt.END_STATS_W - 2 * ScreenArt.THICK,
                ScreenArt.END_STATS_H - 2 * ScreenArt.THICK, ScreenArt.FACE_TABLE);
        List<EndSummary.Cell> cells = endSummary.cells();
        for (int i = 0; i < cells.size(); i++) {
            int x = ScreenArt.endCellX(i);
            int w = ScreenArt.endCellW();
            if (i > 0) {
                chrome.face(batch, x - ScreenArt.THICK, y + ScreenArt.THICK,
                        ScreenArt.THICK, ScreenArt.END_STATS_H - 2 * ScreenArt.THICK,
                        ScreenArt.FRAME);
            }
            chrome.centred(batch, theme.pixelSmall, cells.get(i).label(), x,
                    y + ScreenArt.END_STAT_LABEL_DY, w, 12, ScreenArt.CELL_QUIET, 1f);
            chrome.centred(batch, theme.pixelTitle, cells.get(i).value(), x,
                    y + ScreenArt.END_STAT_VALUE_DY, w, 26, cells.get(i).colour(), 1f);
        }
    }

    /**
     * The trophies this run just earned. A hidden one is revealed here the
     * moment it is won — hiding only ever applies to the not-yet-earned on the
     * trophies screen.
     */
    private void drawUnlocked(int top) {
        chrome.centredOn(batch, theme.pixelSmall, "TROPHIES UNLOCKED",
                ScreenArt.END_X + ScreenArt.END_W / 2, top + ScreenArt.END_UNLOCKED_DY,
                endSummary.accent(), 1f);
        int shown = Math.min(newlyUnlocked.size(), ScreenArt.END_TROPHIES_SHOWN);
        for (int i = 0; i < shown; i++) {
            Achievement earned = newlyUnlocked.get(i);
            int y = ScreenArt.endTrophyY(i);
            chrome.face(batch, ScreenArt.END_UNLOCKED_X, y, ScreenArt.END_TROPHY_SEAL,
                    ScreenArt.END_TROPHY_SEAL, endSummary.accent());
            String name = earned.title().toUpperCase(Locale.ROOT);
            int nameX = ScreenArt.END_UNLOCKED_X + ScreenArt.END_TROPHY_NAME_DX;
            chrome.textInRow(batch, theme.pixelLabel, name, nameX, y,
                    ScreenArt.END_TROPHY_SEAL, ScreenArt.BODY, 1f);
            // Wrapped to the panel's margin: one unbounded line once ran off it.
            int descX = nameX + chrome.width(theme.pixelLabel, name) + ScreenArt.END_TROPHY_DESC_GAP;
            List<String> lines = TextWrap.wrap(earned.description().toUpperCase(Locale.ROOT),
                    ScreenArt.endTrophyDescWidth(descX), ScreenArt.END_TROPHY_DESC_LINES,
                    s -> chrome.width(theme.pixelSmall, s));
            for (int line = 0; line < lines.size(); line++) {
                chrome.textInRow(batch, theme.pixelSmall, lines.get(line), descX,
                        ScreenArt.endTrophyLineY(y, line, lines.size()),
                        ScreenArt.endTrophyLineH(lines.size()), ScreenArt.CELL_QUIET, 1f);
            }
        }
    }

    // --- the tutorial overlay: screen six ---

    /**
     * The board rectangle the current step points at — a room card, the Avoid
     * plate, or none for an explanation beat. Design space with y downward,
     * because that is what the ticks and the callout are specified in.
     */
    private int[] tutorialTarget(TutorialStep step) {
        if (step.expectedMove() instanceof Move.CardMove cardMove) {
            int index = state.room().indexOf(cardMove.targetCard());
            if (index < 0) {
                return null;
            }
            return new int[] {(int) board.slotX(index), CardArt.SLOT_Y,
                    CardArt.CARD_W, CardArt.CARD_H};
        }
        if (step.expectedMove() instanceof Move.AvoidRoom) {
            return new int[] {HudArt.AVOID_X, HudArt.AVOID_Y, HudArt.AVOID_W, HudArt.AVOID_H};
        }
        return null; // an explanation beat with no single focus
    }

    /** The narration, already broken into the lines the callout will hold. */
    private List<String> calloutLines(TutorialStep step) {
        return TextWrap.wrap(step.narration().toUpperCase(Locale.ROOT),
                ScreenArt.calloutTextWidth(), ScreenArt.CALLOUT_MAX_LINES,
                s -> chrome.width(theme.pixelBody, s));
    }

    private int calloutH(TutorialStep step) {
        return ScreenArt.calloutH(calloutLines(step).size(), !step.isAction());
    }

    private CalloutPlacement.Placement calloutPlacement() {
        TutorialStep step = tutorial.current();
        int[] target = tutorialTarget(step);
        int h = calloutH(step);
        if (target == null) {
            return CalloutPlacement.belowRow(CardArt.SLOT_Y, CardArt.CARD_H,
                    ScreenArt.CALLOUT_W, h, ScreenArt.CALLOUT_GAP,
                    (int) Theme.WORLD_WIDTH, (int) Theme.WORLD_HEIGHT);
        }
        return CalloutPlacement.place(target[0], target[1], target[2], target[3],
                ScreenArt.CALLOUT_W, h, ScreenArt.CALLOUT_GAP, (int) Theme.WORLD_WIDTH);
    }

    /** The Next plate on an explanation beat, or null on an action beat. */
    private CalloutPlacement.Plate nextPlate() {
        if (!calloutUp || tutorial.current().isAction()) {
            return null;
        }
        CalloutPlacement.Placement at = calloutPlacement();
        return CalloutPlacement.nextPlate(at.x(), at.y(), calloutH(tutorial.current()),
                chrome.width(theme.pixelLabel, "NEXT"));
    }

    /**
     * The board dims under the dither, the card being taught keeps a viewfinder
     * of eight corner ticks, and the narration sits in a callout pointing at it.
     */
    private void drawTutorialOverlay() {
        // Only the opening beat veils the board. That step is pure introduction —
        // there is nothing on the board to do yet, so pulling the eye to the
        // words is right. From step two on the board is left exactly as it looks
        // in a real run, because the point of a tutorial is to teach *this*
        // game, and a permanently dimmed board teaches a game nobody plays. The
        // corner ticks do the pointing from there.
        if (tutorial.stepNumber() == 1) {
            chrome.veil(batch);
        }
        TutorialStep step = tutorial.current();
        int[] target = tutorialTarget(step);
        if (target != null) {
            for (CornerTicks.Tick tick : CornerTicks.around(target[0], target[1],
                    target[2], target[3])) {
                chrome.face(batch, tick.x(), tick.y(), tick.w(), tick.h(),
                        ScreenArt.TICK_COLOUR);
            }
        }
        drawCallout(step);
        chrome.plate(batch, ScreenArt.skipX(), ScreenArt.SKIP_Y, ScreenArt.SKIP_W,
                ScreenArt.SKIP_H, "SKIP TUTORIAL", Chrome.Plate.DARK, press.sunk() == SKIP);
    }

    private void drawCallout(TutorialStep step) {
        CalloutPlacement.Placement at = calloutPlacement();
        int h = calloutH(step);
        chrome.frame(batch, at.x(), at.y(), ScreenArt.CALLOUT_W, h);
        chrome.face(batch, at.x() + ScreenArt.THICK, at.y() + ScreenArt.THICK,
                ScreenArt.CALLOUT_W - 2 * ScreenArt.THICK, h - 2 * ScreenArt.THICK,
                ScreenArt.FACE_PANEL);
        if (at.hasNotch()) {
            drawNotch(at, h);
        }

        int textX = at.x() + ScreenArt.CALLOUT_PAD_X;
        chrome.text(batch, theme.pixelSmall,
                "STEP " + tutorial.stepNumber() + " OF " + tutorial.stepCount(),
                textX, at.y() + ScreenArt.CALLOUT_STEP_TOP, ScreenArt.HEADING);
        drawStepDots(at);

        List<String> lines = calloutLines(step);
        for (int i = 0; i < lines.size(); i++) {
            chrome.text(batch, theme.pixelBody, lines.get(i), textX,
                    at.y() + ScreenArt.CALLOUT_TEXT_TOP + i * ScreenArt.CALLOUT_LINE_H,
                    ScreenArt.BODY);
        }
        CalloutPlacement.Plate next = nextPlate();
        if (next != null) {
            chrome.plate(batch, next.x(), next.y(), next.w(), next.h(), "NEXT",
                    Chrome.Plate.GOLD, press.sunk() == NEXT);
        }
    }

    /**
     * A staircase, not a triangle: the notch steps in two pixels a row so it is
     * built from whole blocks. A real triangle would need a rotation, and a
     * rotated pixel is a blurred pixel.
     */
    private void drawNotch(CalloutPlacement.Placement at, int h) {
        int rows = CalloutPlacement.NOTCH_H / 2;
        int step = CalloutPlacement.NOTCH_W / (2 * rows);
        for (int row = 0; row < rows; row++) {
            int w = CalloutPlacement.NOTCH_W - 2 * row * step;
            if (w <= 0) {
                break;
            }
            int x = at.notchX() + (CalloutPlacement.NOTCH_W - w) / 2;
            // Above the callout when it sits below the card, below it when above.
            int y = at.below() ? at.y() - 2 * (row + 1) : at.y() + h + 2 * row;
            chrome.face(batch, x, y, w, 2, ScreenArt.FACE_PANEL);
        }
    }

    /** One dot a beat, filled up to the current one — progress you can count. */
    private void drawStepDots(CalloutPlacement.Placement at) {
        int count = tutorial.stepCount();
        int span = count * ScreenArt.DOT_PITCH - (ScreenArt.DOT_PITCH - ScreenArt.DOT_SIZE);
        int x = at.x() + ScreenArt.CALLOUT_W - ScreenArt.CALLOUT_PAD_X - span;
        int y = at.y() + ScreenArt.CALLOUT_STEP_TOP;
        for (int i = 0; i < count; i++) {
            chrome.face(batch, x + i * ScreenArt.DOT_PITCH, y,
                    ScreenArt.DOT_SIZE, ScreenArt.DOT_SIZE,
                    i < tutorial.stepNumber() ? ScreenArt.DOT_ON : ScreenArt.DOT_OFF);
        }
    }

    /** True when the tutorial's current step expects exactly this move. */
    private boolean tutorialExpects(Move move) {
        return tutorial != null && !tutorial.isComplete()
                && move.equals(tutorial.current().expectedMove());
    }

    /** Seconds shown by the timer: live while a run is in progress, frozen after. */
    private long currentRunSeconds() {
        if (state.status() != Status.IN_PROGRESS) {
            return finalRunSeconds;
        }
        return recorder != null ? recorder.elapsedSeconds() : 0;
    }

    // --- resolving a card ---

    /** One legal move plays immediately; two or more open the chooser. */
    private void onCardClicked(Card card) {
        if (tutorial != null) {
            // In the tutorial only the highlighted card responds, and it makes
            // exactly the scripted move — no chooser to wander into.
            if (!tutorial.isComplete()
                    && tutorial.current().expectedMove() instanceof Move.CardMove cm
                    && cm.targetCard().equals(card)) {
                applyMove(cm);
            }
            return;
        }
        List<Move> moves = engine.legalMoves(state).stream()
                .filter(m -> m instanceof Move.CardMove cm && cm.targetCard().equals(card))
                .toList();
        if (moves.size() == 1) {
            applyMove(moves.get(0));
        } else if (moves.size() > 1) {
            showChooser(moves, card);
        }
    }

    /**
     * A stack of the board's own gold plates over the pressed card, one per
     * legal move. Every plate takes the widest label's width, measured once
     * here rather than per frame — a ragged stack reads as two unrelated
     * buttons instead of as a choice between two things.
     */
    private void showChooser(List<Move> moves, Card card) {
        chooserMoves = List.copyOf(moves);
        chooserCard = card;
        int widest = 0;
        for (Move move : chooserMoves) {
            widest = Math.max(widest, hud.labelWidth(chooserLabel(move)));
        }
        chooserPlateW = ChooserArt.plateW(widest);
    }

    /** Uppercase, like every other label the pixel board sets. */
    private static String chooserLabel(Move move) {
        return Labels.move(move).toUpperCase(Locale.ROOT);
    }

    /** The slot the chooser is anchored to, following its card if the room moves. */
    private int chooserSlotX() {
        int index = state.room().indexOf(chooserCard);
        return board.slotX(Math.max(0, index));
    }

    private void drawChooser() {
        if (chooserCard == null) {
            return;
        }
        int x = chooserSlotX();
        for (int i = 0; i < chooserMoves.size(); i++) {
            hud.drawPlate(batch, ChooserArt.plateX(x, chooserPlateW),
                    ChooserArt.plateY(i, chooserMoves.size()),
                    chooserPlateW, ChooserArt.PLATE_H,
                    chooserLabel(chooserMoves.get(i)), true);
        }
    }

    private void closeChooser() {
        chooserMoves = List.of();
        chooserCard = null;
    }

    /** Fresh run. The tutorial plays its scripted deck and records nothing. */
    private void startRun() {
        if (tutorial != null) {
            state = engine.newGame(TutorialScript.deck());
        } else {
            long seed = new Random().nextLong();
            state = engine.newGame(seed);
            recorder = new RunRecorder(seed, mode.id(), Clock.systemUTC());
            tracker = new AchievementTracker(rules.cardsResolvedPerTurn());
        }
        endBestLine = null;
        // Cleared per run: if the record ever fails to build, the panel must
        // show zeroes rather than the previous run's figures.
        finalRunSeconds = 0;
        finalDamageTaken = 0;
        lastPotion = null;
        weaponBeforeMove = null;
        newlyUnlocked = List.of();
        barPhase = HealthReadout.Phase.REST;
        barChange = HealthReadout.Change.NONE;
    }

    /**
     * End of game: persist the run, then evaluate and persist achievements.
     * Each is independently guarded — neither storage step may break play, and
     * a failure in one must not stop the other.
     */
    private void finishRun() {
        RunRecord record;
        try {
            record = recorder.toRecord();
        } catch (RuntimeException e) {
            Gdx.app.error("scoundrel", "failed to build the run record", e);
            endBestLine = null;
            newlyUnlocked = List.of();
            return;
        }
        // The timer freezes here, and the damage total with it — both exactly as recorded.
        finalRunSeconds = record.seconds();
        finalDamageTaken = record.damageTaken();
        try {
            OptionalInt bestBefore = HighScores.bestForRuleset(runLog.readAll(), mode.id());
            runLog.append(record);
            endBestLine = bestBefore.isEmpty() || state.score() > bestBefore.getAsInt()
                    ? "New best!"
                    : "best " + bestBefore.getAsInt();
        } catch (RuntimeException e) {
            Gdx.app.error("scoundrel", "failed to record the run", e);
            endBestLine = null;
        }
        // Achievements are earned in ranked (Standard) mode only; variants still
        // recorded their run above. The history must include the run just
        // appended, so milestone achievements (finish N runs, defeat N monsters)
        // see this game.
        if (mode.tracksAchievements()) {
            try {
                RunSummary summary = tracker.toSummary(record.seconds());
                AchievementContext context = new AchievementContext(summary, runLog.readAll());
                newlyUnlocked = AchievementService.newlyEarned(
                        Achievements.all(), context, achievements.unlockedIds());
                for (Achievement earned : newlyUnlocked) {
                    achievements.append(new UnlockedAchievement(earned.id(), record.endedAt()));
                }
            } catch (RuntimeException e) {
                Gdx.app.error("scoundrel", "failed to evaluate achievements", e);
                newlyUnlocked = List.of();
            }
        }
        if (!newlyUnlocked.isEmpty()) {
            game.music().trophiesUnlocked(); // the chime, once the panel and the cue are done
        }
    }

    private void applyMove(Move move) {
        if (tutorial != null && !tutorial.accepts(move)) {
            return; // only the current step's highlighted move is allowed
        }
        if (move instanceof Move.TakePotion potion) {
            lastPotion = potion.targetCard();
        }
        int healthBefore = state.health();
        List<Card> roomBefore = state.room();
        weaponBeforeMove = state.weapon();
        board.beginMove();

        MoveResult result = engine.apply(state, move);
        state = result.state();
        if (tutorial != null) {
            tutorial.onMoveApplied(move);
        } else {
            recorder.observe(result);
            tracker.observe(result);
            if (state.status() != Status.IN_PROGRESS) {
                finishRun();
            }
        }
        for (GameEvent event : result.events()) {
            String line = FeedText.line(event);
            if (line != null) {
                feed.push(line);
            }
        }

        boolean died = tutorial == null && state.status() == Status.LOST;
        board.setRoom(state.room());
        playEffect(move, result, roomBefore, died);
        pulseHealth(healthBefore, ResolveEffect.damageTaken(result.events()),
                ResolveEffect.healed(result.events()));

        if (died) {
            // Withhold the score: the cinematic runs over the dead board first.
            endPending = true;
            deathElapsed = 0f;
            killerSlotX = move instanceof Move.CardMove cm
                    ? orMinusOne(board.previousSlotX(cm.targetCard().id()))
                    : -1;
            // The music dies with the torch, on the cinematic's own clock: left alone
            // through the settle, out across the gutter, the cue as YOU DIED grows in.
            game.music().dying(DeathCinematic.DITHER_START, DeathCinematic.DITHER_END,
                    DeathCinematic.TITLE_START);
        } else {
            syncBoard();
            endOfRunMusic();
        }
    }

    /**
     * A run that ended without the death cinematic. A win: the director waits for
     * the winning blow to land before the run music gives way to the cue. A loss in
     * the tutorial, which has no cinematic to gutter the torch over: the music just
     * goes, and the cue plays.
     */
    private void endOfRunMusic() {
        if (state.status() == Status.WON) {
            game.music().won();
        } else if (state.status() == Status.LOST) {
            game.music().dying(0f, 0f, 0f);
            game.music().settled();
        }
    }

    /**
     * Whether the board has finished animating — the win's music waits for it.
     *
     * @return true when no effect is running and the room is neither dealing nor closing up
     */
    public boolean boardIdle() {
        return !board.isPlaying();
    }

    /**
     * M was pressed: nothing on the board changes, so the feed says what it did.
     *
     * @param muted whether the press muted (true) or unmuted
     */
    public void announceMute(boolean muted) {
        feed.push(FeedText.mute(muted));
    }

    private static int orMinusOne(Integer value) {
        return value == null ? -1 : value;
    }

    /**
     * The effect is chosen purely by move type; the rest is the wiring. Every
     * one of them ends by dealing the room back in, so a refill follows without
     * being asked for.
     *
     * <p>So is the sound: what the move sounds like is decided from its events
     * ({@code SfxChoice}), the blade weighted by the weapon that was held when the
     * move was made, and the board holds it for the effect's beat.
     */
    private void playEffect(Move move, MoveResult result, List<Card> roomBefore, boolean fatal) {
        List<Sfx> sfx = game.sounds().choice().forEvents(result.events(),
                weaponBeforeMove == null ? 0 : weaponBeforeMove.weapon().value());
        switch (ResolveEffect.of(move)) {
            case AVOID -> board.playSweep(roomBefore, sfx);
            case STRIKE -> board.playStrike(((Move.FightBarehanded) move).targetCard(), fatal, sfx);
            case SLICE -> board.playSlice(((Move.FightWithWeapon) move).targetCard(), fatal, sfx);
            case EQUIP -> board.playEquip(((Move.TakeWeapon) move).targetCard(), sfx);
            case POTION -> {
                Card drunk = ((Move.TakePotion) move).targetCard();
                boolean wasted = result.events().stream()
                        .anyMatch(e -> e instanceof GameEvent.PotionWasted);
                // A wasted potion goes nowhere near the bar: it spills where it
                // stood. Sending it to a bar that then does not move read as the
                // heal being broken rather than as the potion being wasted.
                if (wasted) {
                    board.playSpill(drunk, sfx);
                } else {
                    board.playPotion(drunk, this::startHeal, sfx);
                }
            }
        }
    }

    /**
     * Damage drains the bar straight away — the blow has already landed. A
     * drink does not: the bar holds its old reading until {@link BoardView}
     * calls back to say the bottle has poured, so the fill has a visible cause
     * and is only ever shown once.
     */
    private void pulseHealth(int before, int damage, int healed) {
        barElapsed = 0f;
        if (damage > 0) {
            setBarChange(before, state.health());
            barPhase = HealthReadout.Phase.BLEEDING;
        } else if (healed > 0) {
            setBarChange(before, state.health());
            barPhase = HealthReadout.Phase.HELD;
        } else {
            barPhase = HealthReadout.Phase.REST;
        }
    }

    private void setBarChange(int from, int to) {
        barChange = new HealthReadout.Change(
                HudArt.barFillWidth(from, rules.healthCap()),
                HudArt.barFillWidth(to, rules.healthCap()), from, to);
    }

    /** The bottle has tipped: release the reading the bar has been holding. */
    private void startHeal() {
        barPhase = HealthReadout.Phase.HEALING;
        barElapsed = 0f;
    }
}
