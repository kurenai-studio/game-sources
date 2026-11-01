package com.micro1.pong;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.files.FileHandle;
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
 * Render + input layer for Primitive Pong. All gameplay rules live in {@link PongWorld}; this class
 * only reads keys, ticks the world, and draws it with primitives ({@link ShapeRenderer}) and the
 * default {@link BitmapFont}. No external assets are loaded.
 *
 * <p>The public {@code capture*} / {@code scenario} fields are a QA-only path set by the launcher to
 * render a single frame to a PNG (for offscreen visual verification); they do not affect normal play.
 */
public class PongGame extends ApplicationAdapter {

    // QA capture hooks (set by Lwjgl3Launcher from command-line args). Off by default.
    public boolean captureEnabled = false;
    public String captureFile = null;
    public int captureFrame = 2;
    public String scenario = null; // "gameover" to screenshot the overlay

    private OrthographicCamera camera;
    private ShapeRenderer shapes;
    private SpriteBatch batch;
    private BitmapFont font;
    private GlyphLayout layout;
    private PongWorld world;
    private int frame;

    @Override
    public void create() {
        camera = new OrthographicCamera();
        camera.setToOrtho(false, PongWorld.FIELD_W, PongWorld.FIELD_H); // bottom-left origin
        shapes = new ShapeRenderer();
        batch = new SpriteBatch();
        font = new BitmapFont(); // built-in Arial-15; no asset file
        font.setColor(Color.WHITE);
        layout = new GlyphLayout();
        world = new PongWorld();
        world.newMatch();
        if ("gameover".equals(scenario)) {
            world.forceGameOverForQA(1);
        }
    }

    @Override
    public void render() {
        // Clamp the frame delta so a lag spike cannot let the fast ball tunnel through a paddle
        // (max step at 600px/s becomes 20px < the 24px collision window). Normal frames are unaffected.
        float dt = Math.min(Gdx.graphics.getDeltaTime(), 1f / 30f);

        boolean up1 = Gdx.input.isKeyPressed(Input.Keys.W);
        boolean down1 = Gdx.input.isKeyPressed(Input.Keys.S);
        boolean up2 = Gdx.input.isKeyPressed(Input.Keys.UP);
        boolean down2 = Gdx.input.isKeyPressed(Input.Keys.DOWN);
        boolean restart = Gdx.input.isKeyJustPressed(Input.Keys.R);

        if (!captureEnabled) {
            world.update(dt, up1, down1, up2, down2, restart);
        }

        camera.update();
        Gdx.gl.glClearColor(0f, 0f, 0f, 1f); // solid black field
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        shapes.setProjectionMatrix(camera.combined);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(Color.WHITE);
        // Dashed center line at x=398, 4px wide, 20px dashes with 20px gaps, bottom to top.
        for (float y = 0f; y < PongWorld.FIELD_H; y += 40f) {
            shapes.rect(398f, y, 4f, 20f);
        }
        shapes.rect(world.p1.x, world.p1.y, PongWorld.PADDLE_W, PongWorld.PADDLE_H);
        shapes.rect(world.p2.x, world.p2.y, PongWorld.PADDLE_W, PongWorld.PADDLE_H);
        shapes.rect(world.ball.x, world.ball.y, PongWorld.BALL, PongWorld.BALL);
        shapes.end();

        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        // Baseline 552 + 44px caps both sit within the spec tolerances ("near y=560" / "about 48px")
        // and leave a few-pixel margin at the top of the 600px window so the score never touches the edge.
        drawCentered(Integer.toString(world.score1), 200f, 552f, 44f);
        drawCentered(Integer.toString(world.score2), 600f, 552f, 44f);
        if (world.state == PongWorld.State.GAME_OVER) {
            String winText = (world.winner == 1) ? "Player 1 Wins!" : "Player 2 Wins!";
            drawCentered(winText, 400f, 350f, 64f);
            drawCentered("Press R to restart", 400f, 300f, 24f);
        }
        batch.end();

        frame++;
        if (captureEnabled && captureFile != null && frame >= captureFrame) {
            saveFrame(captureFile);
            Gdx.app.exit();
        }
    }

    /** Draw {@code text} horizontally centered on {@code cx} with its baseline at {@code baselineY}. */
    private void drawCentered(String text, float cx, float baselineY, float targetPx) {
        font.getData().setScale(1f);
        float scale = targetPx / font.getCapHeight();
        font.getData().setScale(scale);
        layout.setText(font, text);
        float x = cx - layout.width / 2f;
        float y = baselineY + font.getCapHeight(); // draw-y is the cap top; baseline sits capHeight below
        font.draw(batch, layout, x, y);
    }

    /** QA: read the framebuffer, flip to top-down, and write a PNG. */
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
        PixmapIO.writePNG(new FileHandle(path), flipped);
        raw.dispose();
        flipped.dispose();
    }

    @Override
    public void dispose() {
        if (shapes != null) shapes.dispose();
        if (batch != null) batch.dispose();
        if (font != null) font.dispose();
    }
}
