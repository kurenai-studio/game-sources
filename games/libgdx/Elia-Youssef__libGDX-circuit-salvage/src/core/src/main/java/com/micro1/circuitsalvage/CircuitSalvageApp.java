package com.micro1.circuitsalvage;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

/**
 * The only class touching {@code Gdx.*}. Owns the render resources, polls input each frame,
 * drives {@link CircuitSalvageWorld}, and draws the grid, entities, HUD, and end-state overlay -
 * everything generated at runtime from {@link ShapeRenderer} primitives and the default
 * {@link BitmapFont}. No external art, fonts, or audio are loaded.
 */
public class CircuitSalvageApp extends ApplicationAdapter {

    private static final Color BACKGROUND_COLOR = new Color(0.05f, 0.05f, 0.07f, 1f);
    private static final Color TILE_COLOR = new Color(0.26f, 0.26f, 0.30f, 1f);
    private static final Color TILE_BORDER_COLOR = new Color(0.12f, 0.12f, 0.15f, 1f);
    private static final Color PLAYER_COLOR = new Color(0.20f, 0.80f, 0.95f, 1f);
    private static final Color PLAYER_OUTLINE_COLOR = new Color(0.05f, 0.35f, 0.55f, 1f);
    private static final Color BATTERY_COLOR = new Color(0.95f, 0.85f, 0.15f, 1f);
    private static final Color BATTERY_CAP_COLOR = new Color(0.70f, 0.60f, 0.05f, 1f);
    private static final Color SPARK_COLOR = new Color(1f, 0.55f, 0.10f, 1f);
    private static final Color EXIT_BACKDROP_COLOR = new Color(0.10f, 0.10f, 0.13f, 1f);
    private static final Color EXIT_LOCKED_COLOR = new Color(0.85f, 0.20f, 0.20f, 1f);
    private static final Color EXIT_OPEN_COLOR = new Color(0.20f, 0.85f, 0.35f, 1f);
    private static final Color OVERLAY_FILL_COLOR = new Color(0.03f, 0.03f, 0.05f, 1f);
    private static final Color WIN_TEXT_COLOR = new Color(0.30f, 0.90f, 0.45f, 1f);
    private static final Color LOSS_TEXT_COLOR = new Color(1f, 0.35f, 0.35f, 1f);

    private static final float TILE_INSET = 2f;

    private static final float OVERLAY_WIDTH = 320f;
    private static final float OVERLAY_HEIGHT = 140f;
    private static final float OVERLAY_CENTER_X = MapConstants.WINDOW_WIDTH / 2f;
    private static final float OVERLAY_CENTER_Y = MapConstants.WINDOW_HEIGHT / 2f;

    // QA-only offscreen capture support (set on the instance via Lwjgl3Launcher's --capture /
    // --capture-frame / --scenario arguments, before create() runs). Never touched during normal
    // play: a plain `./gradlew lwjgl3:run` leaves captureEnabled false and these are all no-ops.
    public boolean captureEnabled = false;
    public String captureFile = null;
    public int captureFrame = 2;
    public String scenario = null;
    private int frame = 0;

    private CircuitSalvageWorld world;
    private ShapeRenderer shapeRenderer;
    private SpriteBatch batch;
    private BitmapFont font;
    private OrthographicCamera camera;
    private GlyphLayout glyphLayout;

    @Override
    public void create() {
        world = new CircuitSalvageWorld();
        if (scenario != null) {
            world.forceScenarioForQA(scenario);
        }
        shapeRenderer = new ShapeRenderer();
        batch = new SpriteBatch();
        font = new BitmapFont();
        glyphLayout = new GlyphLayout();

        camera = new OrthographicCamera();
        camera.setToOrtho(false, MapConstants.WINDOW_WIDTH, MapConstants.WINDOW_HEIGHT);
        camera.update();
    }

    @Override
    public void render() {
        if (!captureEnabled) {
            boolean up = Gdx.input.isKeyPressed(Keys.W) || Gdx.input.isKeyPressed(Keys.UP);
            boolean down = Gdx.input.isKeyPressed(Keys.S) || Gdx.input.isKeyPressed(Keys.DOWN);
            boolean left = Gdx.input.isKeyPressed(Keys.A) || Gdx.input.isKeyPressed(Keys.LEFT);
            boolean right = Gdx.input.isKeyPressed(Keys.D) || Gdx.input.isKeyPressed(Keys.RIGHT);

            // R restarts regardless of state (PLAYING/WIN/LOSS), checked independently of world.update().
            if (Gdx.input.isKeyJustPressed(Keys.R)) {
                world.restart();
            }

            // Cap the frame delta so a stall (alt-tab, breakpoint, dropped frame) cannot move the
            // player or a spark far enough in one step to tunnel past a hazard undetected.
            float delta = Math.min(Gdx.graphics.getDeltaTime(), 1f / 30f);
            world.update(delta, up, down, left, right);
        }

        Gdx.gl.glClearColor(BACKGROUND_COLOR.r, BACKGROUND_COLOR.g, BACKGROUND_COLOR.b, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        shapeRenderer.setProjectionMatrix(camera.combined);
        batch.setProjectionMatrix(camera.combined);

        boolean roundOver = world.getState() != GameState.PLAYING;

        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);
        drawGridFilled();
        drawExitBackdrop();
        drawBatteriesFilled();
        drawSparksFilled();
        drawPlayerFilled();
        if (roundOver) {
            drawOverlayFilled();
        }
        shapeRenderer.end();

        shapeRenderer.begin(ShapeRenderer.ShapeType.Line);
        drawGridLines();
        drawExitOutline();
        drawPlayerOutline();
        if (roundOver) {
            drawOverlayOutline();
        }
        shapeRenderer.end();

        batch.begin();
        drawHudText();
        if (roundOver) {
            drawOverlayText();
        }
        batch.end();

        if (captureEnabled && captureFile != null) {
            frame++;
            if (frame >= captureFrame) {
                saveFrame(captureFile);
                Gdx.app.exit();
            }
        }
    }

    /** QA-only: dumps the current backbuffer to a PNG file, then the caller exits the app. */
    private void saveFrame(String path) {
        int w = Gdx.graphics.getBackBufferWidth();
        int h = Gdx.graphics.getBackBufferHeight();
        Pixmap raw = Pixmap.createFromFrameBuffer(0, 0, w, h);
        Pixmap flipped = new Pixmap(w, h, Pixmap.Format.RGBA8888);
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                flipped.drawPixel(x, h - 1 - y, raw.getPixel(x, y));
            }
        }
        PixmapIO.writePNG(Gdx.files.local(path), flipped);
        raw.dispose();
        flipped.dispose();
    }

    private void drawGridFilled() {
        shapeRenderer.setColor(TILE_COLOR);
        for (int col = 0; col < MapConstants.COLS; col++) {
            for (int row = 0; row < MapConstants.ROWS; row++) {
                float x = MapConstants.MAP_LEFT + col * MapConstants.TILE_SIZE;
                float y = MapConstants.MAP_BOTTOM + row * MapConstants.TILE_SIZE;
                shapeRenderer.rect(x + TILE_INSET, y + TILE_INSET,
                    MapConstants.TILE_SIZE - TILE_INSET * 2, MapConstants.TILE_SIZE - TILE_INSET * 2);
            }
        }
    }

    private void drawGridLines() {
        shapeRenderer.setColor(TILE_BORDER_COLOR);
        for (int col = 0; col < MapConstants.COLS; col++) {
            for (int row = 0; row < MapConstants.ROWS; row++) {
                float x = MapConstants.MAP_LEFT + col * MapConstants.TILE_SIZE;
                float y = MapConstants.MAP_BOTTOM + row * MapConstants.TILE_SIZE;
                shapeRenderer.rect(x + TILE_INSET, y + TILE_INSET,
                    MapConstants.TILE_SIZE - TILE_INSET * 2, MapConstants.TILE_SIZE - TILE_INSET * 2);
            }
        }
    }

    private void drawExitBackdrop() {
        ExitDoor exit = world.getExit();
        shapeRenderer.setColor(EXIT_BACKDROP_COLOR);
        shapeRenderer.rect(exit.getCenterX() - ExitDoor.SIZE / 2f, exit.getCenterY() - ExitDoor.SIZE / 2f,
            ExitDoor.SIZE, ExitDoor.SIZE);
    }

    private void drawExitOutline() {
        ExitDoor exit = world.getExit();
        shapeRenderer.setColor(exit.isLocked() ? EXIT_LOCKED_COLOR : EXIT_OPEN_COLOR);
        shapeRenderer.rect(exit.getCenterX() - ExitDoor.SIZE / 2f, exit.getCenterY() - ExitDoor.SIZE / 2f,
            ExitDoor.SIZE, ExitDoor.SIZE);
    }

    private void drawBatteriesFilled() {
        for (Battery battery : world.getBatteries()) {
            if (battery.isCollected()) {
                continue;
            }
            float x = battery.getCenterX();
            float y = battery.getCenterY();

            shapeRenderer.setColor(BATTERY_COLOR);
            shapeRenderer.rect(x - Battery.WIDTH / 2f, y - Battery.HEIGHT / 2f, Battery.WIDTH, Battery.HEIGHT);

            float capWidth = Battery.WIDTH * 0.4f;
            float capHeight = 4f;
            shapeRenderer.setColor(BATTERY_CAP_COLOR);
            shapeRenderer.rect(x - capWidth / 2f, y + Battery.HEIGHT / 2f, capWidth, capHeight);
        }
    }

    private void drawSparksFilled() {
        shapeRenderer.setColor(SPARK_COLOR);
        drawDiamond(world.getSparkA().getCenterX(), world.getSparkA().getCenterY(), Spark.SIZE);
        drawDiamond(world.getSparkB().getCenterX(), world.getSparkB().getCenterY(), Spark.SIZE);
    }

    private void drawDiamond(float centerX, float centerY, float size) {
        float half = size / 2f;
        shapeRenderer.triangle(centerX, centerY + half, centerX + half, centerY, centerX, centerY - half);
        shapeRenderer.triangle(centerX, centerY + half, centerX - half, centerY, centerX, centerY - half);
    }

    private void drawPlayerFilled() {
        float size = CircuitSalvageWorld.PLAYER_SIZE;
        shapeRenderer.setColor(PLAYER_COLOR);
        shapeRenderer.rect(world.getPlayerX() - size / 2f, world.getPlayerY() - size / 2f, size, size);
    }

    private void drawPlayerOutline() {
        float size = CircuitSalvageWorld.PLAYER_SIZE;
        shapeRenderer.setColor(PLAYER_OUTLINE_COLOR);
        shapeRenderer.rect(world.getPlayerX() - size / 2f, world.getPlayerY() - size / 2f, size, size);
    }

    private void drawOverlayFilled() {
        shapeRenderer.setColor(OVERLAY_FILL_COLOR);
        shapeRenderer.rect(OVERLAY_CENTER_X - OVERLAY_WIDTH / 2f, OVERLAY_CENTER_Y - OVERLAY_HEIGHT / 2f,
            OVERLAY_WIDTH, OVERLAY_HEIGHT);
    }

    private void drawOverlayOutline() {
        boolean win = world.getState() == GameState.WIN;
        shapeRenderer.setColor(win ? EXIT_OPEN_COLOR : EXIT_LOCKED_COLOR);
        shapeRenderer.rect(OVERLAY_CENTER_X - OVERLAY_WIDTH / 2f, OVERLAY_CENTER_Y - OVERLAY_HEIGHT / 2f,
            OVERLAY_WIDTH, OVERLAY_HEIGHT);
    }

    private void drawHudText() {
        font.setColor(Color.WHITE);
        font.draw(batch, "Batteries: " + world.getBatteriesCollected() + "/3", 16, 464);
        font.draw(batch, world.getExit().isLocked() ? "Exit: LOCKED" : "Exit: OPEN", 230, 464);
        font.draw(batch, "Move: WASD/Arrows", 16, 28);
        font.draw(batch, "R: Restart", 530, 28);
    }

    private void drawOverlayText() {
        boolean win = world.getState() == GameState.WIN;
        String primary = win ? "YOU WIN" : "SHORT CIRCUIT";
        String secondary = "R: Restart";

        font.setColor(win ? WIN_TEXT_COLOR : LOSS_TEXT_COLOR);
        glyphLayout.setText(font, primary);
        font.draw(batch, primary, OVERLAY_CENTER_X - glyphLayout.width / 2f, OVERLAY_CENTER_Y + 20f);

        font.setColor(Color.WHITE);
        glyphLayout.setText(font, secondary);
        font.draw(batch, secondary, OVERLAY_CENTER_X - glyphLayout.width / 2f, OVERLAY_CENTER_Y - 12f);
    }

    @Override
    public void dispose() {
        shapeRenderer.dispose();
        batch.dispose();
        font.dispose();
    }
}
