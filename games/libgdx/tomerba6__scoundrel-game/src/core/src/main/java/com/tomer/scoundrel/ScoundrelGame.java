package com.tomer.scoundrel;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Graphics;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Screen;
import com.tomer.scoundrel.achievements.AchievementStore;
import com.tomer.scoundrel.audio.AudioControls;
import com.tomer.scoundrel.audio.AudioSettings;
import com.tomer.scoundrel.audio.AudioSettingsStore;
import com.tomer.scoundrel.audio.MusicDirector;
import com.tomer.scoundrel.rules.GameMode;
import com.tomer.scoundrel.rules.GameModes;
import com.tomer.scoundrel.runs.RunLog;
import com.tomer.scoundrel.tutorial.TutorialFlag;
import com.tomer.scoundrel.tutorial.TutorialGuide;
import com.tomer.scoundrel.tutorial.TutorialScript;
import com.tomer.scoundrel.screens.GameScreen;
import com.tomer.scoundrel.screens.ModeSelectScreen;
import com.tomer.scoundrel.screens.MusicDeck;
import com.tomer.scoundrel.screens.PixelScreen;
import com.tomer.scoundrel.screens.RecordsScreen;
import com.tomer.scoundrel.screens.SoundBank;
import com.tomer.scoundrel.screens.SpriteLab;
import com.tomer.scoundrel.screens.Sprites;
import com.tomer.scoundrel.screens.Theme;
import com.tomer.scoundrel.screens.TitleScreen;
import com.tomer.scoundrel.screens.TrophiesScreen;

import java.nio.file.Path;

/**
 * {@link com.badlogic.gdx.ApplicationListener} shared by all platforms, and
 * the app's navigator: screens ask it to switch, it owns the shared Theme,
 * RunLog and AchievementStore and disposes whichever screen is being left.
 *
 * <p>It also owns what must outlive a screen change: the sprites, the sound
 * bank, the music (which crossfades where the picture cuts), the player's
 * volume, and the keys that work everywhere — F11 or Alt+Enter for fullscreen,
 * M to mute, F9 for the sprite lab.
 *
 * @author Tomer Ben Ari
 * @version 2.2.0
 * @see com.badlogic.gdx.Game
 * @see com.badlogic.gdx.Screen
 */
public class ScoundrelGame extends Game {

    private static final int WINDOWED_WIDTH = 1280;
    private static final int WINDOWED_HEIGHT = 720;

    private Theme theme;
    private Sprites sprites;
    private SoundBank sounds;
    /** Which music plays and how loud: pure, and here so it outlives the screens. */
    private final MusicDirector music = new MusicDirector();
    private MusicDeck musicDeck;
    /** The player's volume: the title's plates and M change it, and it is saved as it changes. */
    private AudioControls audio;
    private RunLog runLog;
    private AchievementStore achievements;
    private TutorialFlag tutorialFlag;
    // The launcher starts the game borderless-fullscreen, so this starts true.
    // The two have to agree: if they disagree the first F11 goes the wrong way
    // and appears to do nothing.
    private boolean fullscreen = true;

    /** Created by the launcher. Nothing is loaded until {@link #create()}, when GL exists. */
    public ScoundrelGame() {
    }

    /**
     * Loads the shared theme, sprites and sounds, opens the stores under
     * {@code ~/.scoundrel/}, applies the saved volume and shows the title — which
     * offers the tutorial if it has never been seen.
     */
    @Override
    public void create() {
        theme = new Theme();
        sprites = new Sprites();
        sounds = new SoundBank();
        musicDeck = new MusicDeck(sounds, music);
        Path home = Path.of(System.getProperty("user.home"), ".scoundrel");
        runLog = new RunLog(home.resolve("runs.log"));
        achievements = new AchievementStore(home.resolve("achievements.log"));
        tutorialFlag = new TutorialFlag(home.resolve("tutorial.seen"));
        // A setting, not progress: the full reset leaves it alone.
        audio = new AudioControls(new AudioSettingsStore(home.resolve("audio.settings")),
                e -> Gdx.app.error("audio", "could not read or save the audio settings", e));
        applyVolume();
        // First ever launch offers the tutorial; afterward it lives under "How to play".
        switchTo(new TitleScreen(this, theme, sprites, runLog, !tutorialFlag.isSeen()));
    }

    /**
     * One frame: the global keys first, then the current screen, then the music,
     * which follows whatever the frame asked of it.
     */
    @Override
    public void render() {
        // F11 or Alt+Enter toggles between borderless-fullscreen and windowed. Polled
        // here rather than in a screen so it works on every screen without each one
        // having to route it; the resize is handled by each screen's viewport.
        boolean altEnter = Gdx.input.isKeyJustPressed(Input.Keys.ENTER)
                && (Gdx.input.isKeyPressed(Input.Keys.ALT_LEFT)
                    || Gdx.input.isKeyPressed(Input.Keys.ALT_RIGHT));
        if (Gdx.input.isKeyJustPressed(Input.Keys.F11) || altEnter) {
            toggleFullscreen();
        }
        // F9 opens the developer sprite inspector. Polled here for the same
        // reason as F11, and guarded so it can't stack on top of itself.
        if (Gdx.input.isKeyJustPressed(Input.Keys.F9) && !(getScreen() instanceof SpriteLab)) {
            switchTo(new SpriteLab(this, theme, sprites));
        }
        // M mutes everything, and brings it back, from any screen — polled here
        // like F11 so no screen has to route it.
        if (Gdx.input.isKeyJustPressed(Input.Keys.M)) {
            toggleMute();
        }
        super.render(); // draws the current screen

        // The music, after the screen: whatever the frame asked of the director (a
        // death, a win, a new run) is carried out in the same frame. Read off the
        // screen now showing, which the frame may just have switched to.
        Screen screen = getScreen();
        boolean boardIdle = !(screen instanceof GameScreen run) || run.boardIdle();
        float torchLight = screen instanceof PixelScreen pixel ? pixel.torchLight()
                : screen instanceof SpriteLab lab ? lab.torchLight() : 1f;
        musicDeck.update(Gdx.graphics.getDeltaTime(), boardIdle, torchLight);
    }

    /**
     * The window was minimised (or is closing). Nothing is heard until it comes
     * back, but nothing stops: the audio keeps time with the picture, which LibGDX
     * keeps rendering. Holding it instead put a death cue minutes after the death
     * it belonged to.
     */
    @Override
    public void pause() {
        super.pause();
        audio.windowMinimised(true);
        applyVolume();
        musicDeck.windowMinimised(true);
    }

    /** The window is back: the audio is heard again at the player's levels. */
    @Override
    public void resume() {
        super.resume();
        audio.windowMinimised(false);
        applyVolume();
        musicDeck.windowMinimised(false);
    }

    private void toggleFullscreen() {
        if (fullscreen) {
            Gdx.graphics.setUndecorated(false);
            Gdx.graphics.setWindowedMode(WINDOWED_WIDTH, WINDOWED_HEIGHT);
        } else {
            Graphics.DisplayMode desktop = Gdx.graphics.getDisplayMode();
            Gdx.graphics.setUndecorated(true);
            Gdx.graphics.setWindowedMode(desktop.width, desktop.height);
        }
        fullscreen = !fullscreen;
    }

    /**
     * The player's volume as it stands, for the title's plates to show.
     *
     * @return the current levels and mute
     */
    public AudioSettings audioSettings() {
        return audio.settings();
    }

    /** The title's MUSIC plate: up a step, round to off. */
    public void cycleMusic() {
        audio.cycleMusic();
        applyVolume();
    }

    /**
     * The title's SOUND plate: up a step, round to off — and a click at the new
     * level, which is how the player hears what they chose. At off it is silent.
     */
    public void cycleSound() {
        audio.cycleSound();
        applyVolume();
        sounds.play(sounds.choice().click());
    }

    /** M: silence everything or bring it back. A run says which in its feed. */
    private void toggleMute() {
        AudioSettings now = audio.toggleMute();
        applyVolume();
        if (getScreen() instanceof GameScreen run) {
            run.announceMute(now.muted());
        }
    }

    /** The gains as they should sound now: the levels, or silence while minimised or muted. */
    private void applyVolume() {
        sounds.setGain(audio.soundGain());
        musicDeck.setGains(audio.musicGain(), audio.soundGain());
    }

    /**
     * The sound effects, shared by every screen like the theme and the sprites.
     *
     * @return the one sound bank, owned and disposed here
     */
    public SoundBank sounds() {
        return sounds;
    }

    /**
     * The music's director, for the moments only a screen sees: a death, a win,
     * trophies, a new run started in place. Which track plays is decided here, on
     * every screen switch.
     *
     * @return the one director, which outlives every screen
     */
    public MusicDirector music() {
        return music;
    }

    /** Back to the title screen, without the first-launch tutorial prompt. */
    public void showTitle() {
        switchTo(new TitleScreen(this, theme, sprites, runLog));
    }

    /** Records that the first-run tutorial prompt has been answered (played or skipped). */
    public void markTutorialSeen() {
        tutorialFlag.markSeen();
    }

    /** The mode picker — where a run is chosen before it begins. */
    public void showModeSelect() {
        switchTo(new ModeSelectScreen(this, theme));
    }

    /**
     * Starts a new run, freshly shuffled, and switches to the run music.
     *
     * @param mode the difficulty chosen on the mode picker; recorded with the run
     */
    public void showGame(GameMode mode) {
        switchTo(new GameScreen(this, theme, sprites, runLog, achievements, mode));
    }

    /**
     * The guided tutorial — a scripted Standard game with narration, recorded
     * nowhere. Entering it marks the tutorial seen, so it is only auto-offered
     * once even if the player leaves partway.
     */
    public void showTutorial() {
        tutorialFlag.markSeen();
        switchTo(new GameScreen(this, theme, sprites, GameModes.STANDARD,
                new TutorialGuide(TutorialScript.steps())));
    }

    /** The ledger: the best runs across every mode, the lifetime figures, and the progress reset. */
    public void showRecords() {
        switchTo(new RecordsScreen(this, theme, runLog, achievements));
    }

    /** The trophies screen: every achievement, earned or not. */
    public void showTrophies() {
        switchTo(new TrophiesScreen(this, theme, achievements));
    }

    /**
     * Wipes all recorded runs, earned achievements, and the tutorial-seen marker
     * (so a reset makes the player new again). Every file is moved aside to a
     * recoverable {@code .bak} backup rather than deleted. Guarded in the UI
     * behind a confirmation; callers own that safety step. The wipe itself is the
     * pure {@link Progress#eraseAll} so it can be tested headlessly.
     */
    public void eraseAllProgress() {
        Progress.eraseAll(runLog, achievements, tutorialFlag);
    }

    /**
     * setScreen only hides the previous screen; it must also be disposed. And the
     * music follows: a run plays the run track, anything else (the lab included) the
     * menu track — which carries on, without restarting, from one menu to the next.
     */
    private void switchTo(Screen next) {
        Screen previous = getScreen();
        setScreen(next);
        if (previous != null) {
            previous.dispose();
        }
        if (next instanceof GameScreen) {
            music.enterRun();
        } else {
            music.enterMenus();
        }
    }

    /** The app is closing: disposes the last screen and every shared resource. */
    @Override
    public void dispose() {
        super.dispose(); // hides the current screen
        if (getScreen() != null) {
            getScreen().dispose();
        }
        sprites.dispose();
        theme.dispose();
        musicDeck.dispose();
        sounds.dispose();
    }
}
