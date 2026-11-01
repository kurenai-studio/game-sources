package dev.luchoc.littlespaceship.game;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import dev.luchoc.littlespaceship.game.adapter.audio.AudioSystem;
import dev.luchoc.littlespaceship.game.adapter.audio.MusicTrack;
import dev.luchoc.littlespaceship.game.screen.MenuScreen;
import dev.luchoc.littlespaceship.game.screen.PlayScreen;
import dev.luchoc.littlespaceship.game.screen.TestMode;
import dev.luchoc.littlespaceship.game.ui.GameSkin;

/**
 * The composition root: the one place that assembles {@code core} with the libGDX adapters, and now
 * also the one place that owns what every screen shares — the {@link Skin} built once in {@link
 * #create()}, {@link GameSettings}, the run seed, and the level id every run plays.
 *
 * <p>Desktop and web share this class unchanged; only the launcher that constructs the backend
 * differs, per {@code docs/planning/12-architecture.md}.
 *
 * <p>Extending {@link Game} instead of {@code ApplicationAdapter} is what phase 06 task 13 needed:
 * the flow of six screens — menu, ship selection, options, pause, victory, defeat — is libGDX's own
 * {@link com.badlogic.gdx.Screen} abstraction, not a framework built for this project.
 * {@code dev.luchoc.littlespaceship.game.screen} holds one class per screen; gameplay itself moved
 * to {@code screen.PlayScreen} unchanged from what this class used to render directly.
 */
public final class LittleSpaceshipGame extends Game {

    /** Logical resolution width, per {@code docs/planning/10-mvp-initial-values.md}. */
    public static final int LOGICAL_WIDTH = 480;

    /** Logical resolution height, per {@code docs/planning/10-mvp-initial-values.md}. */
    public static final int LOGICAL_HEIGHT = 270;

    private final int seed;

    /**
     * The level this run plays. There is no level-selection flow yet, so every run plays the same
     * one — a constant on the game object, not a mechanism, per invariant 6. Both {@code PlayScreen}
     * and {@code ShipSelectScreen} already read session-wide state off this class ({@link #seed()},
     * {@link #skin()}, {@link #audio()}); a level id is the same shape of value, and the day a
     * level-select flow exists, this field is the one place that changes.
     */
    private static final String LEVEL_ID = "level-01";

    /**
     * Set only by the {@code -Ptests} build flavour's TESTS menu ({@code TestMenuScreen}, present
     * only in that flavour — see {@code game/build.gradle.kts}) to start a scenario other than
     * {@link #LEVEL_ID}. {@code null} for the whole run otherwise, which is every build that
     * reaches a player.
     */
    private String levelIdOverride;

    private Skin skin;
    private final GameSettings settings = new GameSettings();
    private AudioSystem audio;

    public LittleSpaceshipGame() {
        this((int) System.currentTimeMillis());
    }

    /** @param seed the run's seed; exposed so a specific run can be reproduced */
    public LittleSpaceshipGame(int seed) {
        this.seed = seed;
    }

    @Override
    public void create() {
        skin = GameSkin.build();
        settings.load();
        audio = new AudioSystem(settings);
        // TestMode.startScreen answers "no test mode" (null) in every build that reaches a
        // player, so this falls back to the ordinary MenuScreen unchanged. Only the -Ptests
        // flavour's own variant returns a screen, per issue #250: that build exists for exactly
        // one purpose, so it boots straight into the TESTS submenu instead of the main menu.
        Screen testScreen = TestMode.startScreen(this);
        setScreen(testScreen != null ? testScreen : new MenuScreen(this));
    }

    /**
     * Disposes the outgoing screen once the new one is in place. {@link Game#setScreen} never does
     * this on its own — it only calls {@code hide()} — and every screen here owns a texture or two,
     * so leaving that to the caller is how a session that walks menu -> ship select -> play -> menu
     * a few times leaks a batch and a stage per hop.
     *
     * <p>Also the one place that decides which music loop, if any, fits the screen being entered —
     * {@link PlayScreen} gets {@link MusicTrack#LEVEL}, {@link MenuScreen} and every other screen get
     * silence. {@link AudioSystem#playMusic} restarting the same already-playing track is a no-op, so
     * navigating Options -> Back -> menu again does not restart the loop mid-bar. Nothing plays here
     * before {@link AudioSystem#unlock()} has been called at least once — see its javadoc — so the
     * very first {@code MenuScreen}, set from {@link #create()} with no user gesture behind it yet,
     * asks for silence and gets exactly that.
     */
    @Override
    public void setScreen(com.badlogic.gdx.Screen screen) {
        com.badlogic.gdx.Screen previous = getScreen();
        super.setScreen(screen);
        if (previous != null) {
            previous.dispose();
        }
        if (audio != null) {
            if (screen instanceof PlayScreen) {
                audio.playMusic(MusicTrack.LEVEL);
            } else {
                audio.stopMusic();
            }
        }
    }

    /** @return the skin every screen styles its widgets from, built once for the whole run */
    public Skin skin() {
        return skin;
    }

    /** @return the options the flow's Options screen edits */
    public GameSettings settings() {
        return settings;
    }

    /** @return the sound effects and music every screen plays through */
    public AudioSystem audio() {
        return audio;
    }

    /** @return the seed this run was created with */
    public int seed() {
        return seed;
    }

    /** @return the content id of the level this run plays */
    public String levelId() {
        return levelIdOverride != null ? levelIdOverride : LEVEL_ID;
    }

    /**
     * Overrides which level {@link #levelId()} returns until the main menu is entered again — see
     * {@link #clearLevelIdOverride()}. Only the {@code -Ptests} flavour's {@code TestMenuScreen}
     * calls this; the ordinary build never does, so {@link #levelId()} always returns
     * {@link #LEVEL_ID} in every build that reaches a player.
     *
     * @param levelId the content id of the scenario to start, an existing level file's own id
     */
    public void overrideLevelId(String levelId) {
        this.levelIdOverride = levelId;
    }

    /**
     * Clears whatever {@link #overrideLevelId(String)} set, so {@link #levelId()} goes back to
     * {@link #LEVEL_ID}. Called from {@link MenuScreen}'s constructor rather than from wherever
     * PLAY is chosen: entering the main menu is the broader boundary, so it also clears a
     * scenario left behind by defeat or victory, not only by choosing PLAY next. A no-op in every
     * build that reaches a player, since {@link #levelIdOverride} is already always {@code null}
     * there — see issue #305.
     */
    public void clearLevelIdOverride() {
        this.levelIdOverride = null;
    }

    @Override
    public void dispose() {
        super.dispose();
        if (skin != null) {
            skin.dispose();
        }
        if (audio != null) {
            audio.dispose();
        }
    }
}
