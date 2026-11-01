package dev.meowpow.boxbot;

import dev.meowpow.boxbot.config.ConfigLoader;
import dev.meowpow.boxbot.engine.Simulation;
import dev.meowpow.boxbot.engine.robot.RobotControllerFactory;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.input.*;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.LogTag;
import dev.meowpow.boxbot.render.SimulationRenderers;
import dev.meowpow.boxbot.render.assets.AssetLoader;
import dev.meowpow.boxbot.render.hud.HudPanels;
import dev.meowpow.boxbot.render.menu.GameOverController;
import dev.meowpow.boxbot.render.menu.PauseMenuController;
import dev.meowpow.boxbot.render.menu.PauseMenuLabel;
import dev.meowpow.boxbot.render.screen.ScreenLayout;
import dev.meowpow.boxbot.render.screen.ScreenPreset;
import dev.meowpow.boxbot.render.screen.ScreenPresets;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.GL20;

import java.util.function.Consumer;

@HotPath
public final class SimulationScreen extends ScreenAdapter {

    private static final float SCROLL_STEP_BASE = 10f;
    private static final PauseMenuLabel[] PAUSE_MENU_ITEMS = PauseMenuLabel.values();

    private final AssetLoader assetLoader;
    private final GameActionDispatcher actionDispatcher;
    private final WorldClickDispatcher clickDispatcher;
    private final WorldHoverDispatcher hoverDispatcher;
    private final RobotControllerFactory controllerFactory;

    private final boolean devMode;
    private final boolean playerInputEnabled;
    private final boolean restartOnFailure;

    private final PauseMenuController pauseMenuController;
    private final GameOverController gameOverController;

    private final Consumer<GameAction> actionListener = this::onAction;
    private final Consumer<WorldClick> clickListener = this::onWorldClick;
    private final Consumer<WorldHover> hoverListener = this::onHover;

    private final ScreenPreset largeScreenPreset;
    private final SimulationClock clock;

    private ConfigLoader configLoader;
    private ScreenLayout screenLayout;

    private SimulationRenderers renderers;
    private Simulation simulation;

    private boolean runEnded;

    /**
     * Creates the screen that runs the game simulation.
     *
     * @param assetLoader the app-owned rendering assets
     * @param actionDispatcher the dispatcher to listen to for player-triggered actions
     * @param clickDispatcher the dispatcher to listen to for player clicks in the world
     * @param hoverDispatcher the dispatcher to listen to for pointer movement in the world
     * @param controllerFactory creates a controller for each newly built simulation
     * @param devMode whether development-only actions are enabled
     * @param playerInputEnabled whether the screen accepts player actions and clicks
     * @param restartOnFailure whether a failed run automatically starts again
     * @param returnToMainMenu discards this run and returns to the main menu
     * @param largeScreenPreset the large windowed preset the screen layout recognizes
     * @param clock the simulation clock
     */
    public SimulationScreen(
            AssetLoader assetLoader,
            GameActionDispatcher actionDispatcher,
            WorldClickDispatcher clickDispatcher,
            WorldHoverDispatcher hoverDispatcher,
            RobotControllerFactory controllerFactory,
            boolean devMode,
            boolean playerInputEnabled,
            boolean restartOnFailure,
            Runnable returnToMainMenu,
            ScreenPreset largeScreenPreset,
            SimulationClock clock
    ) {
        this.assetLoader = assetLoader;
        this.actionDispatcher = actionDispatcher;
        this.clickDispatcher = clickDispatcher;
        this.hoverDispatcher = hoverDispatcher;
        this.controllerFactory = controllerFactory;
        this.devMode = devMode;
        this.playerInputEnabled = playerInputEnabled;
        this.restartOnFailure = restartOnFailure;
        this.pauseMenuController = new PauseMenuController(returnToMainMenu);
        this.gameOverController = new GameOverController(this::buildSimulation, returnToMainMenu);
        this.largeScreenPreset = largeScreenPreset;
        this.clock = clock;
    }

    @Override
    public void show() {
        configLoader = new ConfigLoader();
        pauseMenuController.close();
        gameOverController.close();

        buildSimulation();

        if (playerInputEnabled) {
            screenLayout = new ScreenLayout(largeScreenPreset);
        }
        else {
            var smallPreset = ScreenPresets.computeCentered(
                    ScreenPresets.SMALL.width(),
                    ScreenPresets.SMALL.height()
            );
            var largePreset = ScreenPresets.computeCentered(
                    largeScreenPreset.width(),
                    largeScreenPreset.height()
            );
            screenLayout = new ScreenLayout(smallPreset, largePreset);
        }
        rebuildRenderers();

        if (playerInputEnabled) {
            registerPlayerInput();
        }
    }

    /**
     * Handles a raw player click, in screen coordinates.
     *
     * @param click the click that occurred
     */
    private void onWorldClick(WorldClick click) {
        if (gameOverController.isOpen()) {
            var gameOverMenu = renderers.gameOver();
            if (gameOverMenu != null) {
                gameOverController.handleClick(click, gameOverMenu);
            }
            return;
        }
        if (pauseMenuController.isOpen()) {
            var pauseMenu = renderers.pauseMenu();
            if (pauseMenu != null) {
                pauseMenuController.handleClick(click, pauseMenu);
            }
            return;
        }
        var hud = renderers.hud();
        if (hud != null && hud.isMouseOverDepartIcon(click.screenX(), click.screenY())) {
            simulation.truck().forceDepart(simulation.world());
            return;
        }
        var controller = simulation.selectionController();
        if (controller == null) {
            return;
        }
        var worldPoint = renderers.world().unproject(
                click.screenX(),
                click.screenY()
        );
        controller.onClick(simulation.world(), simulation.tileSize(), worldPoint);
        GameLog.debugf(LogTag.INPUT,
                "Selection changed (primary=%s secondary=%s)",
                controller.primary(),
                controller.secondary()
        );
    }

    private void onHover(WorldHover hover) {
        if (gameOverController.isOpen()) {
            var gameOverMenu = renderers.gameOver();
            if (gameOverMenu != null) {
                gameOverController.handleHover(hover, gameOverMenu);
            }
            return;
        }
        if (!pauseMenuController.isOpen()) {
            return;
        }
        var pauseMenu = renderers.pauseMenu();
        if (pauseMenu != null) {
            pauseMenuController.handleHover(hover, pauseMenu);
        }
    }

    private void scrollOrdersIfHovered(float delta) {
        var hud = renderers.hud();
        if (hud == null) {
            return;
        }
        int screenX = Gdx.input.getX();
        int screenY = Gdx.input.getY();

        if (hud.isMouseOverPanel(HudPanels.ORDERS_PANEL, screenX, screenY)) {
            hud.scrollOrders(delta);
        }
    }

    private void onAction(GameAction action) {
        if (gameOverController.isOpen()) {
            var gameOverMenu = renderers.gameOver();
            if (gameOverMenu != null) {
                gameOverController.handleAction(action, gameOverMenu);
            }
            return;
        }
        if (action == GameAction.MENU_BACK) {
            var pauseMenuRenderer = renderers.pauseMenu();
            if (pauseMenuRenderer != null) {
                pauseMenuController.toggle(pauseMenuRenderer);
            }
            return;
        }
        if (pauseMenuController.isOpen()) {
            var pauseMenu = renderers.pauseMenu();
            if (pauseMenu != null) {
                pauseMenuController.handleAction(action, pauseMenu);
            }
            return;
        }
        switch (action) {
            case RELOAD_RESOURCES -> {
                if (devMode) {
                    reloadResources();
                }
            }
            case RELOAD_LEVEL -> {
                if (devMode) {
                    reloadLevel();
                }
            }
            case SCROLL_PANEL_UP -> scrollOrdersIfHovered(-scrollStep());
            case SCROLL_PANEL_DOWN -> scrollOrdersIfHovered(scrollStep());
            default -> {}
        }
    }

    private float scrollStep() {
        return SCROLL_STEP_BASE * screenLayout.scale();
    }

    private void buildSimulation() {
        var config = configLoader.config();
        simulation = SimulationFactory.build(
                config,
                assetLoader.map(),
                controllerFactory,
                playerInputEnabled,
                clock
        );
        runEnded = false;

        GameLog.infof(LogTag.WORLD, "World built (seed=%d)", config.seed());
    }

    private void registerPlayerInput() {
        actionDispatcher.addListener(actionListener);
        clickDispatcher.addListener(clickListener);
        hoverDispatcher.addListener(hoverListener);
    }

    private void reloadResources() {
        try {
            assetLoader.reload();
            configLoader.reload();
            rebuildRenderers();
            GameLog.info(LogTag.ASSETS, "Resources reloaded");
        }
        catch (RuntimeException e) {
            var message = "Failed to reload resources, keeping previous state";
            GameLog.error(LogTag.ASSETS, message, e);
        }
    }

    private void reloadLevel() {
        try {
            buildSimulation();
        }
        catch (RuntimeException e) {
            var message = "Failed to reload level, keeping previous state";
            GameLog.error(LogTag.WORLD, message);
        }
    }

    private void rebuildRenderers() {
        disposeRenderers();
        renderers = new SimulationRenderers(
                assetLoader,
                configLoader.config(),
                screenLayout,
                simulation.failureLimit(),
                PAUSE_MENU_ITEMS,
                playerInputEnabled
        );
    }

    private void disposeRenderers() {
        if (renderers != null) {
            renderers.dispose();
        }
    }

    @Override
    public void resize(int width, int height) {
        int previousScale = screenLayout.scale();
        screenLayout.update(width, height);

        if (screenLayout.scale() != previousScale) {
            rebuildRenderers();
        }
        else {
            renderers.resize(screenLayout, width, height);
        }
        GameLog.debugf(
                LogTag.RENDER,
                "Resized window (size=%dx%d shell=%s warehouse=%s hud=%s)",
                width,
                height,
                screenLayout.shell(),
                screenLayout.warehouse(),
                screenLayout.hud()
        );
    }

    @Override
    public void render(float delta) {
        Gdx.gl.glClearColor(0f, 0f, 0f, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        if (!runEnded && simulation.hasFailed()) {
            var world = simulation.world();
            GameLog.infof(
                    LogTag.WORLD,
                    "Run failed: %d packages failed. Final score: %d",
                    world.shipmentFailures(),
                    world.score()
            );
            if (restartOnFailure) {
                buildSimulation();
            }
            else {
                runEnded = true;
                openGameOver(world.score());
            }
        }
        if (!runEnded && !pauseMenuController.isOpen()) {
            simulation.step(delta);
        }
        if (!pauseMenuController.isOpen() && !gameOverController.isOpen()) {
            simulation.updateSelection();
        }
        renderers.render(
                simulation.world(),
                simulation.movementAlpha(),
                delta,
                simulation.tileSize(),
                simulation.selectionController(),
                simulation.hudState(),
                pauseMenuController.isOpen(),
                pauseMenuController.selectedLabel(),
                gameOverController.isOpen(),
                gameOverController.selectedLabel()
        );
    }

    private void openGameOver(int score) {
        var gameOverMenu = renderers.gameOver();
        if (gameOverMenu == null) {
            return;
        }
        renderers.setGameOverScore(score);
        gameOverController.open(gameOverMenu);
    }

    @Override
    public void dispose() {
        actionDispatcher.removeListener(actionListener);
        clickDispatcher.removeListener(clickListener);
        hoverDispatcher.removeListener(hoverListener);

        disposeRenderers();

        GameLog.info(LogTag.SYSTEM, "Simulation screen disposed");
    }
}
