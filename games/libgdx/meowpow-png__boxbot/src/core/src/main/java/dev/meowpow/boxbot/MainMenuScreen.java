package dev.meowpow.boxbot;

import dev.meowpow.boxbot.engine.robot.AiRobotController;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.input.*;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.LogTag;
import dev.meowpow.boxbot.render.RenderColors;
import dev.meowpow.boxbot.render.assets.AssetLoader;
import dev.meowpow.boxbot.render.menu.*;
import dev.meowpow.boxbot.render.screen.ScreenLayout;
import dev.meowpow.boxbot.render.screen.ScreenPreset;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.ScreenAdapter;

import java.util.function.Consumer;

/**
 * The game's main-menu screen.
 */
@HotPath
public final class MainMenuScreen extends ScreenAdapter {

    private static final MainMenuLabel[] MENU_ITEMS = MainMenuLabel.values();

    private final ScreenLayout screenLayout;
    private final ScreenPreset largeScreenPreset;

    private final AssetLoader assetLoader;

    private final GameActionDispatcher actionDispatcher;
    private final WorldClickDispatcher clickDispatcher;
    private final WorldHoverDispatcher hoverDispatcher;

    private final SimulationClock clock;
    private final Runnable startNewGame;

    private final Consumer<GameAction> actionListener = this::onAction;
    private final Consumer<WorldClick> clickListener = this::onClick;
    private final Consumer<WorldHover> hoverListener = this::onHover;

    private final MenuSelection selection = new MenuSelection(MENU_ITEMS);

    private SimulationScreen backgroundSimulation;

    private MenuCanvas menuCanvas;
    private MenuRenderer menuRenderer;

    /**
     * Creates the main menu and its background simulation.
     *
     * @param largeScreenPreset the large windowed preset the menu recognizes
     * @param assetLoader the app-owned rendering assets
     * @param actionDispatcher the dispatcher available to the background simulation
     * @param clickDispatcher the dispatcher available to the background simulation
     * @param hoverDispatcher the dispatcher the menu listens to for pointer movement
     * @param clock the background simulation clock
     * @param startNewGame starts a player-controlled simulation
     */
    public MainMenuScreen(
            ScreenPreset largeScreenPreset,
            AssetLoader assetLoader,
            GameActionDispatcher actionDispatcher,
            WorldClickDispatcher clickDispatcher,
            WorldHoverDispatcher hoverDispatcher,
            SimulationClock clock,
            Runnable startNewGame
    ) {
        this.screenLayout = new ScreenLayout(largeScreenPreset);
        this.largeScreenPreset = largeScreenPreset;
        this.assetLoader = assetLoader;
        this.actionDispatcher = actionDispatcher;
        this.clickDispatcher = clickDispatcher;
        this.hoverDispatcher = hoverDispatcher;
        this.clock = clock;
        this.startNewGame = startNewGame;
    }

    @Override
    public void show() {
        backgroundSimulation = new SimulationScreen(
                assetLoader,
                actionDispatcher,
                clickDispatcher,
                hoverDispatcher,
                AiRobotController::new,
                false,
                false,
                true,
                () -> {},
                largeScreenPreset,
                clock
        );
        backgroundSimulation.show();

        menuCanvas = new MenuCanvas();
        menuCanvas.resize(Gdx.graphics.getWidth(), Gdx.graphics.getHeight());

        rebuildMenuRenderer();

        actionDispatcher.addListener(actionListener);
        clickDispatcher.addListener(clickListener);
        hoverDispatcher.addListener(hoverListener);
    }

    @Override
    public void resize(int width, int height) {
        int previousScale = screenLayout.scale();
        screenLayout.update(width, height);
        backgroundSimulation.resize(width, height);
        menuCanvas.resize(width, height);
        if (screenLayout.scale() != previousScale) {
            rebuildMenuRenderer();
        }
    }

    @Override
    public void render(float delta) {
        backgroundSimulation.render(delta);
        menuRenderer.render(selection.selected());
    }

    @Override
    public void hide() {
        actionDispatcher.removeListener(actionListener);
        clickDispatcher.removeListener(clickListener);
        hoverDispatcher.removeListener(hoverListener);
    }

    private void rebuildMenuRenderer() {
        int scale = screenLayout.scale();
        var titleFont = assetLoader.font(MenuFontFactory.titleFontSpec(scale));
        var buttonFont = assetLoader.font(MenuFontFactory.buttonFontSpec(scale));
        var dimOverlay = RenderColors.MAIN_MENU_DIM_OVERLAY;

        var preset = MenuPresets.STANDARD;
        var buttons = new ButtonListComponent(
                MENU_ITEMS,
                buttonFont.font(),
                scale,
                preset.buttonHeight(),
                preset.buttonGap()
        );
        var layout = new MenuLayout.Builder()
                .panelWidth(preset.panelWidth())
                .scale(scale)
                .addComponent(new TextComponent(titleFont.font(), RenderColors.ACCENT, "BOXBOT"))
                .buttons(buttons)
                .build();

        menuRenderer = new MenuRenderer(menuCanvas, layout, scale, dimOverlay);
        menuRenderer.setEnabled(MainMenuLabel.NEW_GAME, true);
        menuRenderer.setEnabled(MainMenuLabel.CONTINUE, false);
        menuRenderer.setEnabled(MainMenuLabel.SETTINGS, false);
        menuRenderer.setEnabled(MainMenuLabel.EXIT, true);
    }

    private void onClick(WorldClick click) {
        var label = menuRenderer.labelAt(click.screenX(), click.screenY());
        if (label == null) {
            return;
        }
        selection.hover(label, menuRenderer);
        if (selection.selected() != null) {
            activateSelected();
        }
    }

    private void onHover(WorldHover hover) {
        var label = menuRenderer.labelAt(hover.screenX(), hover.screenY());
        selection.hover(label, menuRenderer);
    }

    private void onAction(GameAction action) {
        switch (action) {
            case MENU_SELECT_PREVIOUS -> selection.move(-1, menuRenderer);
            case MENU_SELECT_NEXT -> selection.move(1, menuRenderer);
            case MENU_ACTIVATE -> activateSelected();
            case MENU_NEW_GAME -> activate(MainMenuLabel.NEW_GAME);
            case MENU_BACK -> activate(MainMenuLabel.EXIT);
            default -> {}
        }
    }

    private void activateSelected() {
        activate(selection.selected());
    }

    private void activate(@Nullable MenuLabel label) {
        if (label == null || !menuRenderer.isEnabled(label)) {
            return;
        }
        switch ((MainMenuLabel) label) {
            case NEW_GAME -> startNewGame.run();
            case EXIT -> Gdx.app.exit();
            default -> {}
        }
    }

    @Override
    public void dispose() {
        hide();

        menuCanvas.dispose();
        backgroundSimulation.dispose();

        GameLog.infof(LogTag.SYSTEM, "Main menu screen disposed");
    }
}
