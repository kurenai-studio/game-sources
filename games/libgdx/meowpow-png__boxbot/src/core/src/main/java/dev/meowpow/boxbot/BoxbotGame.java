package dev.meowpow.boxbot;

import dev.meowpow.boxbot.engine.robot.PlayerRobotController;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.input.GameActionDispatcher;
import dev.meowpow.boxbot.input.WorldClickDispatcher;
import dev.meowpow.boxbot.input.WorldHoverDispatcher;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.LogTag;
import dev.meowpow.boxbot.render.assets.AssetLoader;
import dev.meowpow.boxbot.render.effect.ScreenFade;
import dev.meowpow.boxbot.render.effect.ScreenFxController;
import dev.meowpow.boxbot.render.screen.ScreenPreset;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.InputProcessor;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;

public final class BoxbotGame extends Game {

    private static final float TRANSITION_FADE_DURATION = 0.3f;
    private static final Color TRANSITION_FADE_COLOR = Color.BLACK;

    private final InputProcessor inputProcessor;
    private final ScreenPreset largeScreenPreset;

    private final GameActionDispatcher actionDispatcher;
    private final WorldClickDispatcher clickDispatcher;
    private final WorldHoverDispatcher hoverDispatcher;

    private final SimulationClock clock;
    private final boolean devMode;

    private AssetLoader assetLoader;
    private ScreenFxController screenEffects;

    private ScreenFade transitionFade;
    private Screen pendingScreen;

    /**
     * Creates the game.
     *
     * @param inputProcessor the platform's input processor
     * @param largeScreenPreset the large windowed preset the screen layout recognizes
     * @param actionDispatcher the dispatcher game screens can listen to for player-triggered actions
     * @param clickDispatcher the dispatcher game screens can listen to for player clicks in the world
     * @param hoverDispatcher the dispatcher game screens can listen to for pointer movement in the world
     * @param clock the simulation clock
     * @param devMode whether development-only actions are enabled
     */
    public BoxbotGame(
            InputProcessor inputProcessor,
            ScreenPreset largeScreenPreset,
            GameActionDispatcher actionDispatcher,
            WorldClickDispatcher clickDispatcher,
            WorldHoverDispatcher hoverDispatcher,
            SimulationClock clock,
            boolean devMode
    ) {
        this.inputProcessor = inputProcessor;
        this.largeScreenPreset = largeScreenPreset;
        this.actionDispatcher = actionDispatcher;
        this.clickDispatcher = clickDispatcher;
        this.hoverDispatcher = hoverDispatcher;
        this.clock = clock;
        this.devMode = devMode;
    }

    @Override
    public void create() {
        GameLog.infof(LogTag.SYSTEM, "Boxbot starting (devMode=%s)", devMode);

        assetLoader = new AssetLoader();
        screenEffects = new ScreenFxController();

        screenEffects.resize(Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
        Gdx.input.setInputProcessor(inputProcessor);

        showMainMenu();
    }

    private void showMainMenu() {
        var menuScreen = new MainMenuScreen(
                largeScreenPreset,
                assetLoader,
                actionDispatcher,
                clickDispatcher,
                hoverDispatcher,
                clock,
                this::startNewGame
        );
        transitionTo(menuScreen);
    }

    private void startNewGame() {
        var simulationScreen = new SimulationScreen(
                assetLoader,
                actionDispatcher,
                clickDispatcher,
                hoverDispatcher,
                ignored -> new PlayerRobotController(),
                devMode,
                true,
                false,
                this::showMainMenu,
                largeScreenPreset,
                clock
        );
        transitionTo(simulationScreen);
    }

    /**
     * Fades to the given screen,
     * replacing the current screen once hidden.
     * <p>
     * <strong>API Note:</strong>
     * Ignored while a transition is already in progress.
     *
     * @param nextScreen the screen to switch to
     */
    private void transitionTo(Screen nextScreen) {
        if (transitionFade != null) {
            return;
        }
        transitionFade = new ScreenFade(TRANSITION_FADE_DURATION);
        screenEffects.addEffect(transitionFade);
        transitionFade.fadeOut(TRANSITION_FADE_COLOR);
        pendingScreen = nextScreen;
    }

    private void switchScreen(Screen nextScreen) {
        var previousScreen = getScreen();
        setScreen(nextScreen);
        if (previousScreen != null) {
            previousScreen.dispose();
        }
    }

    @Override
    public void render() {
        float delta = Gdx.graphics.getDeltaTime();
        screenEffects.update(delta);

        if (transitionFade != null && !transitionFade.isFading()) {
            if (pendingScreen != null) {
                switchScreen(pendingScreen);
                pendingScreen = null;
                transitionFade.fadeIn();
            }
            else {
                screenEffects.removeEffect(transitionFade);
                transitionFade = null;
            }
        }
        super.render();
        screenEffects.render();
    }

    @Override
    public void resize(int width, int height) {
        super.resize(width, height);
        screenEffects.resize(width, height);
    }

    @Override
    public void dispose() {
        super.dispose();
        screenEffects.dispose();
        assetLoader.dispose();
    }
}
