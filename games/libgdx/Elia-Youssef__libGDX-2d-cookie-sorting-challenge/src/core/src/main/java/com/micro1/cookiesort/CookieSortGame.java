package com.micro1.cookiesort;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Cursor;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.utils.TimeUtils;

import java.util.Date;

/**
 * Render + input layer for Cookie Sorting Challenge. All gameplay rules live in {@link CookieSortWorld};
 * this class draws it with the three supplied textures plus tinted 1x1-pixel rectangles for the timer/
 * overlay boxes, handles mouse drag + hover cursors, and writes the metrics log on a win/loss transition.
 *
 * <p>The public {@code capture*} / {@code scenario} fields are a QA-only path set by the launcher to
 * render a single frame to a PNG (for offscreen visual verification, incl. forcing a win/loss overlay);
 * they do not affect normal play.
 */
public class CookieSortGame extends ApplicationAdapter {

    // QA capture hooks (set by Lwjgl3Launcher from command-line args). Off by default.
    public boolean captureEnabled = false;
    public String captureFile = null;
    public int captureFrame = 2;
    public String scenario = null; // "win" or "lose" to screenshot the game-over overlay

    private static final float CENTER_PLATE_DRAW = 620f;
    private static final float CORNER_PLATE_DRAW = 260f;
    private static final float CENTER_COOKIE_DRAW = 90f;
    private static final float CORNER_COOKIE_DRAW = 70f;
    private static final int DRAG_CURSOR_SIZE = 32; // LWJGL3 requires a power-of-two cursor pixmap size

    private OrthographicCamera camera;
    private SpriteBatch batch;
    private BitmapFont font;
    private GlyphLayout layout;

    private Texture plateTexture;
    private Texture lightTexture;
    private Texture darkTexture;
    private Texture whitePixel;
    private Cursor lightDragCursor;
    private Cursor darkDragCursor;

    private CookieSortWorld world;
    private int frame;

    @Override
    public void create() {
        camera = new OrthographicCamera();
        camera.setToOrtho(false, CookieSortWorld.WINDOW_W, CookieSortWorld.WINDOW_H); // bottom-left origin
        batch = new SpriteBatch();
        font = new BitmapFont(); // built-in Arial-15; no font asset needed
        layout = new GlyphLayout();

        plateTexture = loadTexture("cookie_plate.png");
        lightTexture = loadTexture("l_cookie.png");
        darkTexture = loadTexture("d_cookie.png");
        whitePixel = buildWhitePixel();
        lightDragCursor = buildCursor("l_cookie.png", DRAG_CURSOR_SIZE);
        darkDragCursor = buildCursor("d_cookie.png", DRAG_CURSOR_SIZE);

        world = new CookieSortWorld();
        if ("win".equals(scenario)) world.forceTerminalForQA(true);
        else if ("lose".equals(scenario)) world.forceTerminalForQA(false);

        Gdx.input.setInputProcessor(new DragInputProcessor());
    }

    @Override
    public void render() {
        if (!captureEnabled) {
            world.update(Gdx.graphics.getDeltaTime());
        }
        if (world.consumeLogPending()) {
            writeMetricsLog();
        }

        camera.update();
        Gdx.gl.glClearColor(0.141f, 0.102f, 0.078f, 1f); // #241a14 dark brown
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        batch.setProjectionMatrix(camera.combined);
        batch.begin();

        drawPlate(CookieSortWorld.CENTER_CX, CookieSortWorld.CENTER_CY, CENTER_PLATE_DRAW);
        for (CornerPlate plate : world.corners) {
            drawPlate(plate.cx, plate.cy, CORNER_PLATE_DRAW);
        }

        Cookie dragged = world.draggedCookie();
        for (Cookie cookie : world.cookies) {
            if (cookie == dragged) continue; // drawn last so it stays on top while dragged
            if (cookie.isOnCenterPlate()) {
                drawCookie(cookie, CENTER_COOKIE_DRAW);
            } else {
                drawCookie(cookie, CORNER_COOKIE_DRAW);
            }
        }
        if (dragged != null) {
            drawCookie(dragged, CENTER_COOKIE_DRAW);
        }

        drawTimer();
        if (world.state != CookieSortWorld.State.PLAYING) {
            drawGameOverOverlay();
        }
        batch.end();

        frame++;
        if (captureEnabled && captureFile != null && frame >= captureFrame) {
            saveFrame(captureFile);
            Gdx.app.exit();
        }
    }

    private void drawPlate(float cx, float cy, float size) {
        batch.draw(plateTexture, cx - size / 2f, cy - size / 2f, size, size);
    }

    private void drawCookie(Cookie cookie, float size) {
        Texture texture = (cookie.type == CookieType.LIGHT) ? lightTexture : darkTexture;
        batch.draw(texture, cookie.x - size / 2f, cookie.y - size / 2f, size, size);
    }

    private void drawTimer() {
        int totalSeconds = (int) Math.ceil(world.remainingSeconds);
        int minutes = totalSeconds / 60;
        int seconds = totalSeconds % 60;
        String text = String.format("%02d:%02d", minutes, seconds);
        drawBox(800f, 1140f, 220f, 74f, 0.08f, 0.06f, 0.05f);
        drawCentered(text, 800f, 1128f, 40f, Color.WHITE);
    }

    private void drawGameOverOverlay() {
        drawBox(CookieSortWorld.CENTER_CX, CookieSortWorld.CENTER_CY, 640f, 240f, 0.08f, 0.06f, 0.05f);
        boolean won = world.state == CookieSortWorld.State.WON;
        String headline = won ? "YOU WIN!" : "YOU LOSE!";
        Color color = won ? Color.valueOf("4CD964") : Color.valueOf("FF5B4C");
        String subtext = won ? "All cookies sorted before time ran out."
                              : "Time ran out before sorting all cookies.";
        drawCentered(headline, CookieSortWorld.CENTER_CX, CookieSortWorld.CENTER_CY + 40f, 56f, color);
        drawCentered(subtext, CookieSortWorld.CENTER_CX, CookieSortWorld.CENTER_CY - 30f, 22f, Color.WHITE);
    }

    /** Solid box centered on (cx, cy), size (w, h), tinted (r, g, b) fully opaque. */
    private void drawBox(float cx, float cy, float w, float h, float r, float g, float b) {
        batch.setColor(r, g, b, 1f);
        batch.draw(whitePixel, cx - w / 2f, cy - h / 2f, w, h);
        batch.setColor(Color.WHITE);
    }

    /** Draw {@code text} horizontally centered on {@code cx} with its baseline at {@code baselineY}. */
    private void drawCentered(String text, float cx, float baselineY, float targetPx, Color color) {
        font.getData().setScale(1f);
        float scale = targetPx / font.getCapHeight();
        font.getData().setScale(scale);
        font.setColor(color);
        layout.setText(font, text);
        float x = cx - layout.width / 2f;
        float y = baselineY + font.getCapHeight(); // draw-y is the cap top; baseline sits capHeight below
        font.draw(batch, layout, x, y);
    }

    private void writeMetricsLog() {
        String fileName = MetricsLogWriter.fileName(new Date());
        String body = MetricsLogWriter.body(world.metrics);
        Gdx.files.local(fileName).writeString(body, false);
    }

    private Texture loadTexture(String path) {
        Texture texture = new Texture(Gdx.files.internal(path));
        texture.setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear);
        return texture;
    }

    private Texture buildWhitePixel() {
        Pixmap pixmap = new Pixmap(1, 1, Pixmap.Format.RGBA8888);
        pixmap.setColor(Color.WHITE);
        pixmap.fill();
        Texture texture = new Texture(pixmap);
        pixmap.dispose();
        return texture;
    }

    /** A small (downscaled) cursor built from a supplied cookie texture, for the drag-cursor requirement. */
    private Cursor buildCursor(String assetPath, int size) {
        Pixmap source = new Pixmap(Gdx.files.internal(assetPath));
        Pixmap scaled = new Pixmap(size, size, source.getFormat());
        scaled.setFilter(Pixmap.Filter.BiLinear);
        scaled.drawPixmap(source, 0, 0, source.getWidth(), source.getHeight(), 0, 0, size, size);
        Cursor cursor = Gdx.graphics.newCursor(scaled, size / 2, size / 2);
        source.dispose();
        scaled.dispose();
        return cursor;
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
        if (plateTexture != null) plateTexture.dispose();
        if (lightTexture != null) lightTexture.dispose();
        if (darkTexture != null) darkTexture.dispose();
        if (whitePixel != null) whitePixel.dispose();
        if (lightDragCursor != null) lightDragCursor.dispose();
        if (darkDragCursor != null) darkDragCursor.dispose();
        if (batch != null) batch.dispose();
        if (font != null) font.dispose();
    }

    /** Left-click-only drag lifecycle + hover cursor, translating top-left screen coords to the world's
     * bottom-left-origin coordinates. */
    private class DragInputProcessor extends InputAdapter {
        @Override
        public boolean touchDown(int screenX, int screenY, int pointer, int button) {
            if (button != Input.Buttons.LEFT) return false;
            boolean started = world.beginDrag(screenX, toWorldY(screenY), TimeUtils.millis());
            if (started) {
                Cookie dragged = world.draggedCookie();
                Gdx.graphics.setCursor(dragged.type == CookieType.LIGHT ? lightDragCursor : darkDragCursor);
            }
            return started;
        }

        @Override
        public boolean touchDragged(int screenX, int screenY, int pointer) {
            if (!world.isDragging()) return false;
            world.updateDrag(screenX, toWorldY(screenY));
            return true;
        }

        @Override
        public boolean touchUp(int screenX, int screenY, int pointer, int button) {
            if (button != Input.Buttons.LEFT || !world.isDragging()) return false;
            world.endDrag(screenX, toWorldY(screenY), TimeUtils.millis());
            updateHoverCursor(screenX, screenY);
            return true;
        }

        @Override
        public boolean mouseMoved(int screenX, int screenY) {
            updateHoverCursor(screenX, screenY);
            return false;
        }

        private float toWorldY(int screenY) {
            return CookieSortWorld.WINDOW_H - screenY;
        }

        private void updateHoverCursor(int screenX, int screenY) {
            if (world.isDragging()) return; // the drag cursor already owns the pointer icon
            boolean hovering = world.hitTestCenterCookie(screenX, toWorldY(screenY)) >= 0;
            Gdx.graphics.setSystemCursor(hovering ? Cursor.SystemCursor.Hand : Cursor.SystemCursor.Arrow);
        }
    }
}
