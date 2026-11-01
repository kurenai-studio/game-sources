package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputMultiplexer;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Slider;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.utils.ScreenUtils;
import com.badlogic.gdx.utils.viewport.Viewport;
import dev.luchoc.littlespaceship.core.application.GameLoop;
import dev.luchoc.littlespaceship.core.application.Simulation;
import dev.luchoc.littlespaceship.core.port.CompletionBonus;
import dev.luchoc.littlespaceship.core.port.ContentSource;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.LevelOutcome;
import dev.luchoc.littlespaceship.core.port.PlayerStatus;
import dev.luchoc.littlespaceship.core.port.WorldView;
import dev.luchoc.littlespaceship.game.GameSettings;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;
import dev.luchoc.littlespaceship.game.adapter.audio.AudioDirector;
import dev.luchoc.littlespaceship.game.adapter.content.JsonContentSource;
import dev.luchoc.littlespaceship.game.adapter.input.InputAdapter;
import dev.luchoc.littlespaceship.game.adapter.render.CheckerboardBackground;
import dev.luchoc.littlespaceship.game.adapter.render.HudRenderer;
import dev.luchoc.littlespaceship.game.adapter.render.PackedSpriteAtlas;
import dev.luchoc.littlespaceship.game.adapter.render.PixelPerfectViewport;
import dev.luchoc.littlespaceship.game.adapter.render.SpriteAtlas;
import dev.luchoc.littlespaceship.game.adapter.render.WorldRenderer;
import dev.luchoc.littlespaceship.game.ui.Palette;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

/**
 * Level 1: the gameplay canvas plus the HUD plates and the pause overlay, in one screen because the
 * spec's pause freezes the very playfield it appears over rather than replacing it with a menu.
 *
 * <p>What renders here is exactly what {@link LittleSpaceshipGame} rendered before this phase
 * introduced a screen flow; nothing about the simulation or the drawing changed, only where the
 * loop lives.
 *
 * <p>The HUD reads {@link WorldView#player()} once per frame — a fresh snapshot, not cached —
 * and {@link #render} checks {@link WorldView#outcome()} right after advancing the tick, switching
 * to {@link VictoryScreen} or {@link DefeatScreen} the moment it leaves {@link
 * LevelOutcome#IN_PROGRESS}. Both signals arrived from {@code core-domain} after this class first
 * shipped with a fixed placeholder state and a debug-key stand-in for the two end screens; neither
 * survives in this version.
 *
 * <p><b>The pause panel's OPTIONS entry (issue #42) swaps this same panel's content in place rather
 * than pushing {@link OptionsScreen}.</b> {@code OptionsScreen} is a full screen built on its own
 * {@link Stage}; showing it here would mean either running two stages at once or replacing this
 * screen entirely, and the latter is what {@link LittleSpaceshipGame#setScreen} always does — it
 * disposes the outgoing screen, which would tear down {@link #simulation} and the run underneath it
 * just to change a slider. Reusing this panel keeps the playfield frozen and the pointer-lock state
 * exactly as {@link #pauseGameplay()} left it, with nothing to restore on the way back. Only the three
 * volumes are exposed here, matching the one thing issue #42 named; mouse control and credits stay
 * menu-only, see {@link #buildPauseOptionsPanel()}'s javadoc for why.
 */
public final class PlayScreen implements Screen {

    private static final float PLAYFIELD_WIDTH = 208f;
    private static final float PLAYFIELD_LEFT =
        (LittleSpaceshipGame.LOGICAL_WIDTH - PLAYFIELD_WIDTH) / 2f;

    private final LittleSpaceshipGame game;

    private SpriteBatch batch;
    private OrthographicCamera camera;
    private Viewport viewport;

    private SpriteAtlas atlas;
    private CheckerboardBackground checkerboard;
    private WorldRenderer worldRenderer;
    private HudRenderer hudRenderer;
    private InputAdapter input;

    private ContentSource content;
    private Simulation simulation;
    private GameLoop loop;
    private AudioDirector audioDirector;

    private boolean paused;
    private Stage pauseStage;
    private Texture dimTexture;
    private Table pausePanel;

    public PlayScreen(LittleSpaceshipGame game) {
        this.game = game;
    }

    @Override
    public void show() {
        batch = new SpriteBatch();
        camera = new OrthographicCamera();
        viewport = new PixelPerfectViewport(
            LittleSpaceshipGame.LOGICAL_WIDTH, LittleSpaceshipGame.LOGICAL_HEIGHT, camera);

        atlas = PackedSpriteAtlas.load(Gdx.files.internal(""));
        checkerboard = new CheckerboardBackground();
        worldRenderer = new WorldRenderer(atlas, PLAYFIELD_LEFT);
        input = new InputAdapter(viewport);

        content = new JsonContentSource(Gdx.files.internal("data"), game.levelId());
        hudRenderer = new HudRenderer(game.skin(), content.balance(), atlas);
        // AudioDirector doubles as the simulation's GameEventSink — see its javadoc — so it must
        // exist before Simulation does.
        audioDirector = new AudioDirector(game.audio());
        simulation = new Simulation(content, audioDirector, game.seed(), game.levelId());
        loop = new GameLoop(simulation);

        buildPauseStage();
    }

    private void buildPauseStage() {
        pauseStage = new Stage(viewport, new SpriteBatch());
        Table root = new Table();
        root.setFillParent(true);
        pauseStage.addActor(root);

        // Plate behind the panel, per docs/design/mockups/src/05-screens.js's pause screen: N2 fill,
        // N3 frame, so the panel reads as a surface over the frozen playfield instead of text
        // floating on it. Width fixed, height left to the content: the pause-menu state and the
        // options state hold different amounts of content, and letting the table size itself avoids
        // clipped sliders on one state or a lopsided plate on the other.
        pausePanel = new Table();
        pausePanel.setBackground(game.skin().getDrawable("n2-panel"));
        pausePanel.pad(16f);
        root.add(pausePanel).width(200f).center();

        buildPauseMenuPanel();

        Pixmap pm = new Pixmap(1, 1, Pixmap.Format.RGBA8888);
        pm.setColor(new Color(0f, 0f, 0f, 0.55f));
        pm.fill();
        dimTexture = new Texture(pm);
        pm.dispose();
    }

    /**
     * The RESUME/OPTIONS/QUIT TO MENU state of {@link #pausePanel}. Rebuilds the panel's children
     * and replaces its {@link MenuNavigator} rather than keeping one navigator alive across both
     * states, because {@link MenuNavigator} owns a fixed, ordered list handed to it once in its
     * constructor — the options panel's list is a different length and its own list, not this one
     * grown or shrunk in place.
     */
    private void buildPauseMenuPanel() {
        pausePanel.clearChildren();
        pausePanel.add(new Label("PAUSED", game.skin(), "title")).padBottom(16f).row();
        List<KeyboardFocusable> focusables = new ArrayList<>();
        MenuEntries.add(pausePanel, game, game.skin(), "RESUME", this::resumeGameplay, focusables);
        MenuEntries.add(pausePanel, game, game.skin(), "OPTIONS", this::buildPauseOptionsPanel, focusables);
        MenuEntries.add(pausePanel, game, game.skin(), "QUIT TO MENU",
            () -> game.setScreen(new MenuScreen(game)), focusables);
        pauseStage.getRoot().clearListeners();
        new MenuNavigator(pauseStage, focusables);
    }

    /**
     * The volume-only state of {@link #pausePanel}, reached from its OPTIONS entry. Master, music
     * and effects volume only — issue #42 names volume as the one setting worth reaching without
     * abandoning the run. Mouse control changes what {@link InputAdapter#sample} reads and would
     * need to be re-tested against a live pointer-lock state to be sure it behaves mid-run rather
     * than only from the menu's already-idle input; credits and licences have nothing to do with a
     * paused run. Both stay reachable exactly where they already are, from the main menu.
     */
    private void buildPauseOptionsPanel() {
        pausePanel.clearChildren();
        GameSettings settings = game.settings();
        pausePanel.add(new Label("OPTIONS", game.skin(), "title")).padBottom(16f).row();
        List<KeyboardFocusable> focusables = new ArrayList<>();
        addPauseVolumeSlider(pausePanel, "MASTER VOLUME", settings.masterVolume(),
            value -> { settings.masterVolume(value); game.audio().refreshVolume(); }, focusables);
        addPauseVolumeSlider(pausePanel, "MUSIC VOLUME", settings.musicVolume(),
            value -> { settings.musicVolume(value); game.audio().refreshVolume(); }, focusables);
        addPauseVolumeSlider(pausePanel, "EFFECTS VOLUME", settings.effectsVolume(),
            settings::effectsVolume, focusables);
        MenuEntries.add(pausePanel, game, game.skin(), "BACK", this::buildPauseMenuPanel, focusables);
        pauseStage.getRoot().clearListeners();
        new MenuNavigator(pauseStage, focusables);
    }

    /**
     * A slimmed-down copy of {@link OptionsScreen#addSlider}: same widget shape, no percentage
     * label and a narrower row, because this panel shares {@link #pausePanel}'s 200 px width with
     * the pause menu's own entries rather than {@code OptionsScreen}'s full safe area.
     */
    private void addPauseVolumeSlider(Table table, String labelText, float initial,
            Consumer<Float> onChange, List<KeyboardFocusable> focusables) {
        Table row = new Table();
        Label label = new Label(labelText, game.skin(), "hud-label");
        Slider slider = new Slider(0f, 1f, 0.01f, false, game.skin());
        slider.setValue(initial);
        slider.addListener(event -> {
            onChange.accept(slider.getValue());
            return false;
        });
        row.add(label).left().row();
        row.add(slider).width(160f).padTop(2f);
        table.add(row).left().padBottom(12f).row();

        focusables.add(new KeyboardFocusable() {
            @Override
            public void setFocused(boolean focused) {
                row.setBackground(focused ? game.skin().getDrawable("n1-panel") : null);
            }

            @Override
            public void activate() {
                slider.setValue(Math.min(1f, slider.getValue() + 0.05f));
            }

            @Override
            public void adjust(int direction) {
                slider.setValue(Math.max(0f, Math.min(1f, slider.getValue() + direction * 0.05f)));
            }
        });
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true);
    }

    @Override
    public void render(float delta) {
        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            if (paused) {
                resumeGameplay();
            } else {
                pauseGameplay();
            }
        }
        if (!paused) {
            InputFrame frame = input.sample(delta, content.balance(), game.settings().mouseEnabled());
            if (input.pointerCaptureLostUnexpectedly()) {
                // The browser revoked pointer lock on its own — a notification, alt-tab, or a click
                // outside the canvas — not the player pressing Escape. Issue #41: without this, the
                // ship kept reading deltas from a now-free cursor, losing its centring and then
                // losing movement entirely once the cursor hit a screen edge. Pausing, rather than
                // falling back to keyboard-only or a click-to-resume prompt, means a player who
                // alt-tabs mid-fight comes back to a game waiting for them instead of a ship that
                // silently drifted while they were away. This frame's mouse-derived deltas in
                // `frame` are discarded along with it.
                pauseGameplay();
            } else {
                loop.advance(delta, frame);

                WorldView view = simulation.view();
                audioDirector.update(view, view.player());
                LevelOutcome outcome = view.outcome();
                if (outcome != LevelOutcome.IN_PROGRESS) {
                    PlayerStatus status = view.player();
                    if (outcome == LevelOutcome.DEFEATED) {
                        game.setScreen(new DefeatScreen(game, status.score()));
                    } else {
                        CompletionBonus bonus = view.completionBonus();
                        game.setScreen(new VictoryScreen(
                            game, status.score(), bonus.livesBonus(), bonus.bombsBonus()));
                    }
                    return;
                }
            }
        }

        ScreenUtils.clear(Palette.N0.r, Palette.N0.g, Palette.N0.b, 1f);
        viewport.apply();
        batch.setProjectionMatrix(camera.combined);

        WorldView drawView = simulation.view();
        PlayerStatus drawStatus = drawView.player();
        batch.begin();
        checkerboard.draw(batch, PLAYFIELD_LEFT, 0f, PLAYFIELD_WIDTH, LittleSpaceshipGame.LOGICAL_HEIGHT);
        worldRenderer.draw(drawView, batch, drawStatus);
        hudRenderer.draw(batch, drawStatus, drawView.bossStatus());
        if (paused) {
            batch.setColor(1f, 1f, 1f, 1f);
            batch.draw(dimTexture, 0f, 0f,
                LittleSpaceshipGame.LOGICAL_WIDTH, LittleSpaceshipGame.LOGICAL_HEIGHT);
        }
        batch.end();

        if (paused) {
            pauseStage.act(delta);
            pauseStage.draw();
        }
    }

    /**
     * The spec's pause: freezes the tick and shows the {@code RESUME}/{@code QUIT TO MENU} panel.
     * Not named {@code pause()}/{@code resume()} — those are {@link Screen}'s own lifecycle hooks,
     * which the backend calls on focus loss independently of the player's own Escape key, and
     * reusing them here would conflate the two.
     */
    private void pauseGameplay() {
        if (!paused) {
            paused = true;
            // Always the RESUME/OPTIONS/QUIT state on entry, never whichever panel was showing the
            // last time the game was paused — a player who leaves the options panel open, resumes,
            // dies and re-enters pause should not find a volume slider where RESUME belongs.
            buildPauseMenuPanel();
            Gdx.input.setInputProcessor(new InputMultiplexer(pauseStage));
        }
    }

    private void resumeGameplay() {
        if (paused) {
            paused = false;
            Gdx.input.setInputProcessor(null);
        }
    }

    @Override
    public void pause() {
        // Intentionally empty; see the note on pauseGameplay().
    }

    @Override
    public void resume() {
        // Intentionally empty; see the note on pauseGameplay().
    }

    @Override
    public void hide() {
        Gdx.input.setInputProcessor(null);
    }

    @Override
    public void dispose() {
        batch.dispose();
        atlas.dispose();
        checkerboard.dispose();
        worldRenderer.dispose();
        hudRenderer.dispose();
        if (pauseStage != null) {
            pauseStage.dispose();
        }
        if (dimTexture != null) {
            dimTexture.dispose();
        }
    }
}
