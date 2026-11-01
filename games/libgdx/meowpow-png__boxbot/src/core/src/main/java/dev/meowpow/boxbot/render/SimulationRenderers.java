package dev.meowpow.boxbot.render;

import dev.meowpow.boxbot.config.BoxbotConfig;
import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.engine.time.Alpha;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.input.selection.SelectionController;
import dev.meowpow.boxbot.map.TileSizeParser;
import dev.meowpow.boxbot.render.assets.AssetLoader;
import dev.meowpow.boxbot.render.hud.HudFontFactory;
import dev.meowpow.boxbot.render.hud.HudRenderer;
import dev.meowpow.boxbot.render.hud.HudState;
import dev.meowpow.boxbot.render.menu.*;
import dev.meowpow.boxbot.render.screen.ScreenLayout;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.utils.Disposable;

/**
 * Owns every renderer a running simulation draws with.
 */
@HotPath
public final class SimulationRenderers implements Disposable {

    private final WorldRenderer worldRenderer;
    private final EntityRenderer entityRenderer;
    private final LightingRenderer lightingRenderer;
    private final SelectionRenderer selectionRenderer;

    private final @Nullable HudRenderer hudRenderer;
    private final @Nullable MenuCanvas menuCanvas;
    private final @Nullable MenuRenderer pauseMenuRenderer;
    private final @Nullable MenuRenderer gameOverMenuRenderer;
    private final @Nullable TextComponent gameOverScoreText;

    /**
     * Builds every renderer needed by a simulation.
     *
     * @param assetLoader the app-owned rendering assets
     * @param config the loaded config
     * @param screenLayout the current screen layout
     * @param failureLimit the shipment-failure backlog limit the HUD warns against
     * @param pauseMenuItems the pause menu's items, in display order
     * @param hudVisible whether the HUD and pause menu are shown
     */
    public SimulationRenderers(
            AssetLoader assetLoader,
            BoxbotConfig config,
            ScreenLayout screenLayout,
            int failureLimit,
            PauseMenuLabel[] pauseMenuItems,
            boolean hudVisible
    ) {
        var map = assetLoader.map();
        var tileSize = TileSizeParser.parse(map);
        var timing = config.timing();
        var demand = config.demand();
        var ui = config.ui();
        int scale = screenLayout.scale();

        worldRenderer = new WorldRenderer(map, tileSize);
        worldRenderer.resize(screenLayout.warehouse());
        entityRenderer = new EntityRenderer(
                tileSize,
                assetLoader.entitySprites(),
                assetLoader.font(WorldLabelFontFactory.shelfFontSpec()),
                assetLoader.font(WorldLabelFontFactory.loadingBayFontSpec())
        );
        lightingRenderer = new LightingRenderer(map, tileSize, assetLoader.overlays());
        selectionRenderer = new SelectionRenderer(
                assetLoader.font(WorldLabelFontFactory.queueNumberFontSpec())
        );
        if (hudVisible) {
            hudRenderer = new HudRenderer(
                    assetLoader.font(HudFontFactory.headerFontSpec(scale)),
                    assetLoader.font(HudFontFactory.bodyFontSpec(scale)),
                    scale,
                    failureLimit,
                    timing.simulationTickDuration(),
                    demand.deliveryTimerTicks(),
                    ui.orderWarningThresholdPercent(),
                    ui.orderCriticalThresholdPercent(),
                    assetLoader.hudIcons()
            );
            hudRenderer.resize(screenLayout.hud());

            var titleFont = assetLoader.font(MenuFontFactory.titleFontSpec(scale));
            var buttonFont = assetLoader.font(MenuFontFactory.buttonFontSpec(scale));

            menuCanvas = new MenuCanvas();
            menuCanvas.resize(Gdx.graphics.getWidth(), Gdx.graphics.getHeight());

            var pausePreset = MenuPresets.STANDARD;
            var pauseButtons = new ButtonListComponent(
                    pauseMenuItems,
                    buttonFont.font(),
                    scale,
                    pausePreset.buttonHeight(),
                    pausePreset.buttonGap()
            );
            var pauseLayout = new MenuLayout.Builder()
                    .panelWidth(pausePreset.panelWidth())
                    .scale(scale)
                    .buttons(pauseButtons)
                    .build();

            pauseMenuRenderer = new MenuRenderer(
                    menuCanvas,
                    pauseLayout,
                    scale,
                    RenderColors.PAUSE_MENU_DIM_OVERLAY
            );
            pauseMenuRenderer.setEnabled(PauseMenuLabel.RESUME, true);
            pauseMenuRenderer.setEnabled(PauseMenuLabel.SETTINGS, false);
            pauseMenuRenderer.setEnabled(PauseMenuLabel.MAIN_MENU, true);
            pauseMenuRenderer.setEnabled(PauseMenuLabel.EXIT, true);

            gameOverScoreText = new TextComponent(
                    buttonFont.font(),
                    RenderColors.HUD_PANEL_BODY_FONT,
                    "SCORE: 0"
            );
            var gameOverPreset = MenuPresets.GAME_OVER;
            var gameOverButtons = new ButtonListComponent(
                    GameOverMenuLabel.values(),
                    buttonFont.font(),
                    scale,
                    gameOverPreset.buttonHeight(),
                    gameOverPreset.buttonGap()
            );
            var gameOverTitleText = new TextComponent(
                    titleFont.font(),
                    RenderColors.ACCENT,
                    "GAME OVER"
            );
            var gameOverLayout = new MenuLayout.Builder()
                    .panelWidth(gameOverPreset.panelWidth())
                    .scale(scale)
                    .addComponent(gameOverTitleText)
                    .addComponent(gameOverScoreText)
                    .buttons(gameOverButtons)
                    .build();

            gameOverMenuRenderer = new MenuRenderer(
                    menuCanvas,
                    gameOverLayout,
                    scale,
                    RenderColors.PAUSE_MENU_DIM_OVERLAY
            );
            gameOverMenuRenderer.setEnabled(GameOverMenuLabel.TRY_AGAIN, true);
            gameOverMenuRenderer.setEnabled(GameOverMenuLabel.MAIN_MENU, true);
        }
        else {
            hudRenderer = null;
            menuCanvas = null;
            pauseMenuRenderer = null;
            gameOverMenuRenderer = null;
            gameOverScoreText = null;
        }
    }

    /**
     * Resizes every renderer to the given layout and window size.
     *
     * @param screenLayout the updated screen layout
     * @param windowWidth the window's current width, in pixels
     * @param windowHeight the window's current height, in pixels
     */
    public void resize(ScreenLayout screenLayout, int windowWidth, int windowHeight) {
        worldRenderer.resize(screenLayout.warehouse());
        if (hudRenderer != null) {
            hudRenderer.resize(screenLayout.hud());
        }
        if (menuCanvas != null) {
            menuCanvas.resize(windowWidth, windowHeight);
        }
    }

    /**
     * Returns the warehouse world renderer.
     */
    public WorldRenderer world() {
        return worldRenderer;
    }

    /**
     * Returns the HUD panels renderer,
     * or null if the HUD is hidden.
     */
    public @Nullable HudRenderer hud() {
        return hudRenderer;
    }

    /**
     * Returns the pause menu overlay
     * renderer or null if the HUD is hidden.
     */
    public @Nullable MenuRenderer pauseMenu() {
        return pauseMenuRenderer;
    }

    /**
     * Returns the game-over overlay
     * renderer or null if the HUD is hidden.
     */
    public @Nullable MenuRenderer gameOver() {
        return gameOverMenuRenderer;
    }

    /**
     * Updates the score shown on the game-over screen.
     * No-op if the HUD is hidden.
     *
     * @param score the score to display
     */
    public void setGameOverScore(int score) {
        if (gameOverScoreText != null) {
            gameOverScoreText.setText("SCORE: " + score);
        }
    }

    /**
     * Draws a single frame for a simulation.
     *
     * @param world the simulation's runtime state
     * @param movementAlpha progress into the current movement tick
     * @param delta elapsed time since the last frame, in seconds
     * @param tileSize the map's tile size, in pixels
     * @param selectionController the active selection controller, or null if player input is disabled
     * @param hudState the state HUD panels read from
     * @param pauseMenuOpen whether the pause menu is currently open
     * @param selectedPauseMenuLabel the pause menu's currently selected item, if any
     * @param gameOverOpen whether the game-over menu is currently open
     * @param selectedGameOverLabel the game-over menu's currently selected item, if any
     */
    public void render(
            World world,
            Alpha movementAlpha,
            float delta,
            TileSize tileSize,
            @Nullable SelectionController selectionController,
            HudState hudState,
            boolean pauseMenuOpen,
            @Nullable MenuLabel selectedPauseMenuLabel,
            boolean gameOverOpen,
            @Nullable MenuLabel selectedGameOverLabel
    ) {
        worldRenderer.render();
        entityRenderer.render(worldRenderer.camera(), world, movementAlpha, delta);
        lightingRenderer.render(
                worldRenderer.camera(),
                worldRenderer.viewport(),
                world,
                movementAlpha
        );
        if (selectionController != null) {
            selectionRenderer.render(
                    worldRenderer.camera(),
                    tileSize,
                    selectionController.primary(),
                    selectionController.secondary(),
                    selectionController.stagingPrimary(),
                    selectionController.stagingSecondary(),
                    selectionController.queuedPairs()
            );
        }
        if (hudRenderer != null) {
            hudRenderer.render(hudState);
        }
        if (pauseMenuOpen && pauseMenuRenderer != null) {
            pauseMenuRenderer.render(selectedPauseMenuLabel);
        }
        if (gameOverOpen && gameOverMenuRenderer != null) {
            gameOverMenuRenderer.render(selectedGameOverLabel);
        }
    }

    @Override
    public void dispose() {
        worldRenderer.dispose();
        entityRenderer.dispose();
        lightingRenderer.dispose();
        selectionRenderer.dispose();
        if (hudRenderer != null) {
            hudRenderer.dispose();
        }
        if (menuCanvas != null) {
            menuCanvas.dispose();
        }
    }
}
