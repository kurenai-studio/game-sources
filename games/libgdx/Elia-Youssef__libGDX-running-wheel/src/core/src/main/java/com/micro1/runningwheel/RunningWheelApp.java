package com.micro1.runningwheel;

import java.util.List;
import java.util.Locale;
import java.util.Random;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.TimeUtils;

/**
 * The render + input layer. Polls the arrow keys and Escape, advances {@link GameWorld}, scrolls
 * a camera that follows the wheel (clamped to the world edges), and draws the terrain, wheel, and
 * finish flag in world space plus the fixed top-panel HUD (elapsed time, speed, and the win/lose
 * message) in screen space.
 */
public class RunningWheelApp extends ApplicationAdapter {

    private static final Color BACKGROUND = Color.WHITE;
    private static final Color TERRAIN = Color.valueOf("B5824F");
    private static final Color PLATFORM = Color.valueOf("A9763F");
    private static final Color WHEEL = Color.BLACK;
    private static final Color POLE = Color.valueOf("444444");
    private static final Color FLAG = Color.valueOf("D64545");
    private static final Color HUD_PANEL = Color.valueOf("D9D9D9");

    private static final float CAM_Y_OFFSET_PX = 120f;
    private static final float MIN_CAM_Y_PX = 300f;
    private static final float MAX_CAM_Y_PX = 460f;

    private static final float[] OUTLINE_OFFSETS = {
        -1.5f, 0f, 1.5f, 0f, 0f, -1.5f, 0f, 1.5f,
        -1.5f, -1.5f, 1.5f, -1.5f, -1.5f, 1.5f, 1.5f, 1.5f
    };

    private GameWorld world;
    private ShapeRenderer shapes;
    private SpriteBatch batch;
    private BitmapFont font;
    private GlyphLayout layout;
    private OrthographicCamera worldCam;
    private OrthographicCamera hudCam;

    @Override
    public void create() {
        world = new GameWorld(new Random(TimeUtils.nanoTime()));
        shapes = new ShapeRenderer();
        batch = new SpriteBatch();
        font = new BitmapFont();
        font.getData().setScale(1.2f);
        layout = new GlyphLayout();

        worldCam = new OrthographicCamera();
        worldCam.setToOrtho(false, WorldConstants.WINDOW_WIDTH_PX, WorldConstants.WINDOW_HEIGHT_PX);
        hudCam = new OrthographicCamera();
        hudCam.setToOrtho(false, WorldConstants.WINDOW_WIDTH_PX, WorldConstants.WINDOW_HEIGHT_PX);
        hudCam.update();
    }

    @Override
    public void render() {
        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            Gdx.app.exit();
            return;
        }

        boolean leftHeld = Gdx.input.isKeyPressed(Input.Keys.LEFT);
        boolean rightHeld = Gdx.input.isKeyPressed(Input.Keys.RIGHT);
        world.update(Gdx.graphics.getDeltaTime(), leftHeld, rightHeld);

        updateCamera();

        Gdx.gl.glClearColor(BACKGROUND.r, BACKGROUND.g, BACKGROUND.b, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        drawWorld();
        drawWheel();
        drawHud();
    }

    private void updateCamera() {
        float halfW = WorldConstants.WINDOW_WIDTH_PX / 2f;
        float camX = clamp(world.getWheelXPx(), halfW, WorldConstants.WORLD_WIDTH_PX - halfW);
        float camY = clamp(world.getWheelYPx() + CAM_Y_OFFSET_PX, MIN_CAM_Y_PX, MAX_CAM_Y_PX);
        worldCam.position.set(camX, camY, 0f);
        worldCam.update();
    }

    private void drawWorld() {
        TerrainData terrain = world.getTerrain();
        float camLeft = worldCam.position.x - WorldConstants.WINDOW_WIDTH_PX / 2f;
        float camRight = worldCam.position.x + WorldConstants.WINDOW_WIDTH_PX / 2f;

        shapes.setProjectionMatrix(worldCam.combined);
        shapes.begin(ShapeRenderer.ShapeType.Filled);

        // Ground surface: fill each column from the surface curve down past the view bottom.
        shapes.setColor(TERRAIN);
        for (float[] seg : terrain.groundSegments) {
            for (int i = 0; i + 3 < seg.length; i += 2) {
                float x0 = seg[i];
                float x1 = seg[i + 2];
                if (x1 < camLeft || x0 > camRight) {
                    continue;
                }
                float y0 = seg[i + 1];
                float y1 = seg[i + 3];
                float bottom = WorldConstants.FILL_BOTTOM_Y_PX;
                shapes.triangle(x0, bottom, x0, y0, x1, y1);
                shapes.triangle(x0, bottom, x1, y1, x1, bottom);
            }
        }

        // Rectangular platforms.
        shapes.setColor(PLATFORM);
        List<float[]> platforms = terrain.platforms;
        for (int i = 0; i < platforms.size(); i++) {
            float[] p = platforms.get(i);
            shapes.rect(p[0] - p[2], p[1] - p[3], p[2] * 2f, p[3] * 2f);
        }

        // Triangular ramp wedge.
        if (terrain.rampWedge != null) {
            float[] r = terrain.rampWedge;
            shapes.setColor(TERRAIN);
            shapes.triangle(r[0], r[1], r[2], r[3], r[4], r[5]);
        }

        // Finish: a pole with a red pennant at the right end of the course.
        float top = terrain.finishGroundYPx + WorldConstants.FINISH_POLE_HEIGHT_PX;
        shapes.setColor(POLE);
        shapes.rect(terrain.finishXPx - 2f, terrain.finishGroundYPx, 4f, WorldConstants.FINISH_POLE_HEIGHT_PX);
        shapes.setColor(FLAG);
        shapes.triangle(terrain.finishXPx + 2f, top, terrain.finishXPx + 2f, top - 40f,
                terrain.finishXPx + 60f, top - 20f);

        shapes.end();
    }

    private void drawWheel() {
        float cx = world.getWheelXPx();
        float cy = world.getWheelYPx();
        float r = WorldConstants.WHEEL_RADIUS_PX;
        float a = world.getWheelAngleRad();

        shapes.setProjectionMatrix(worldCam.combined);
        shapes.begin(ShapeRenderer.ShapeType.Line);
        shapes.setColor(WHEEL);
        shapes.circle(cx, cy, r, 28);
        shapes.line(cx, cy, cx + r * MathUtils.cos(a), cy + r * MathUtils.sin(a));
        shapes.line(cx, cy, cx + r * MathUtils.cos(a + MathUtils.HALF_PI),
                cy + r * MathUtils.sin(a + MathUtils.HALF_PI));
        shapes.end();
    }

    private void drawHud() {
        shapes.setProjectionMatrix(hudCam.combined);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(HUD_PANEL);
        shapes.rect(0f, WorldConstants.WINDOW_HEIGHT_PX - WorldConstants.HUD_PANEL_HEIGHT_PX,
                WorldConstants.WINDOW_WIDTH_PX, WorldConstants.HUD_PANEL_HEIGHT_PX);
        shapes.end();

        float ty = WorldConstants.WINDOW_HEIGHT_PX - 8f;
        batch.setProjectionMatrix(hudCam.combined);
        batch.begin();

        String time = "Time: " + formatTime(world.getElapsedSeconds());
        drawOutlined(time, 12f, ty);

        String speed = String.format(Locale.US, "Speed: %.1f m/s", world.getSpeedMps());
        layout.setText(font, speed);
        drawOutlined(speed, WorldConstants.WINDOW_WIDTH_PX - 12f - layout.width, ty);

        String message = endMessage();
        if (message != null) {
            layout.setText(font, message);
            drawOutlined(message, (WorldConstants.WINDOW_WIDTH_PX - layout.width) / 2f, ty);
        }

        batch.end();
    }

    private String endMessage() {
        if (world.getState() == GameWorld.State.WON) {
            return "You Win";
        }
        if (world.getState() == GameWorld.State.LOST) {
            return "You Lose";
        }
        return null;
    }

    /** Draws white text with a black outline (the sample HUD style) by offsetting the black pass. */
    private void drawOutlined(String text, float x, float y) {
        font.setColor(Color.BLACK);
        for (int i = 0; i + 1 < OUTLINE_OFFSETS.length; i += 2) {
            font.draw(batch, text, x + OUTLINE_OFFSETS[i], y + OUTLINE_OFFSETS[i + 1]);
        }
        font.setColor(Color.WHITE);
        font.draw(batch, text, x, y);
    }

    private static String formatTime(float seconds) {
        int total = (int) seconds;
        return String.format(Locale.US, "%02d:%02d", total / 60, total % 60);
    }

    private static float clamp(float v, float lo, float hi) {
        if (v < lo) {
            return lo;
        }
        if (v > hi) {
            return hi;
        }
        return v;
    }

    @Override
    public void dispose() {
        if (shapes != null) {
            shapes.dispose();
        }
        if (batch != null) {
            batch.dispose();
        }
        if (font != null) {
            font.dispose();
        }
        if (world != null) {
            world.dispose();
        }
    }
}
