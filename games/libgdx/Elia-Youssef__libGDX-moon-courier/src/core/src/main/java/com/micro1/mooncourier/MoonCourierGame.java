package com.micro1.mooncourier;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * The application root. Extends libGDX {@code Game} to host exactly four player-facing screens - Main
 * Menu, Gameplay, Victory, Game Over - and owns the shared render resources ({@link SpriteBatch},
 * {@link ShapeRenderer}, a 1280x720 {@link FitViewport}, and the {@link Assets} fonts) so the screens
 * hold no GL state of their own. The world is fixed at 1280x720 virtual units and letterboxed to any
 * window size by the FitViewport, which keeps the HUD legible at the default size and beyond.
 */
public final class MoonCourierGame extends Game {

    private final CaptureConfig capture;

    private SpriteBatch batch;
    private ShapeRenderer shape;
    private OrthographicCamera camera;
    private Viewport viewport;
    private Assets assets;

    private int captureFrameCount;

    public MoonCourierGame(CaptureConfig capture) {
        this.capture = capture != null ? capture : new CaptureConfig();
    }

    @Override
    public void create() {
        camera = new OrthographicCamera();
        viewport = new FitViewport(MissionWorld.WORLD_WIDTH, MissionWorld.WORLD_HEIGHT, camera);
        viewport.apply(true);
        batch = new SpriteBatch();
        shape = new ShapeRenderer();
        assets = new Assets();

        if (capture.enabled) {
            setScreen(buildCaptureScreen(capture.scenario));
        } else {
            setScreen(new MainMenuScreen(this));
        }
    }

    private Screen buildCaptureScreen(String scenario) {
        String sc = scenario == null ? "menu" : scenario;
        switch (sc) {
            case "play":
                return new GameplayScreen(this);
            case "playCargo": {
                GameplayScreen gs = new GameplayScreen(this);
                gs.getWorld().forceCollectCargo();
                gs.getWorld().setShipPosition(720f, 360f);
                gs.getWorld().setFuel(72f);
                return gs;
            }
            case "victory":
                return new VictoryScreen(this, new MissionResult(true, 42, 12500, 168f));
            case "gameover":
                return new GameOverScreen(this, new MissionResult(false, 0, 4800, 135f));
            case "autowin": {
                // Seed a gameplay world one step from delivery, to prove the live Gameplay -> Victory
                // transition actually fires in the real GL app (not just in the headless test).
                GameplayScreen gs = new GameplayScreen(this);
                gs.getWorld().forceCollectCargo();
                gs.getWorld().setShipPosition(MissionWorld.PAD_X, MissionWorld.PAD_Y);
                return gs;
            }
            case "autolose": {
                // Seed a gameplay world already out of fuel, to prove the live Gameplay -> Game Over
                // transition fires in the real GL app. Fuel is set to exactly 0 (not a small positive
                // value) so the first update deterministically crosses the depletion check regardless of
                // the capture frame delta - with vsync off, frames elapse in near-zero wall-clock time,
                // so a positive seed could take many frames to drain and make the capture non-reproducible.
                GameplayScreen gs = new GameplayScreen(this);
                gs.getWorld().setFuel(0f);
                return gs;
            }
            case "menu":
            default:
                return new MainMenuScreen(this);
        }
    }

    @Override
    public void render() {
        viewport.apply();
        batch.setProjectionMatrix(camera.combined);
        shape.setProjectionMatrix(camera.combined);
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);

        super.render(); // delegates to the active screen

        if (capture.enabled && capture.file != null) {
            captureFrameCount++;
            if (captureFrameCount >= capture.frame) {
                ScreenshotUtil.saveFrame(capture.file);
                Gdx.app.exit();
            }
        }
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true);
    }

    /** Switches to {@code next}, disposing the screen being left (they hold no shared resources). */
    private void switchTo(Screen next) {
        Screen old = getScreen();
        setScreen(next);
        if (old != null) {
            old.dispose();
        }
    }

    public void showMainMenu() {
        switchTo(new MainMenuScreen(this));
    }

    public void showGameplay() {
        switchTo(new GameplayScreen(this));
    }

    public void showVictory(MissionResult result) {
        switchTo(new VictoryScreen(this, result));
    }

    public void showGameOver(MissionResult result) {
        switchTo(new GameOverScreen(this, result));
    }

    public SpriteBatch getBatch() {
        return batch;
    }

    public ShapeRenderer getShape() {
        return shape;
    }

    public Viewport getViewport() {
        return viewport;
    }

    public Assets getAssets() {
        return assets;
    }

    @Override
    public void dispose() {
        if (getScreen() != null) {
            getScreen().dispose();
        }
        if (batch != null) batch.dispose();
        if (shape != null) shape.dispose();
        if (assets != null) assets.dispose();
    }
}
