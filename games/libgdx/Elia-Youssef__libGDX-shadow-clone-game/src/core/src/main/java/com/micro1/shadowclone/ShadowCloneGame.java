package com.micro1.shadowclone;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * The libGDX {@link Game}: owns the shared SpriteBatch, ShapeRenderer, font and camera/viewport that
 * every screen draws with, plus the run-wide {@link GameStats}. Starts on the Main Menu and hosts
 * the Menu -> Play (12 levels) -> Victory flow. Asset-free: text uses the built-in BitmapFont scaled
 * per call, everything else is ShapeRenderer primitives.
 */
public final class ShadowCloneGame extends Game {

    public SpriteBatch batch;
    public ShapeRenderer shapes;
    public BitmapFont font;
    public GlyphLayout layout;
    public OrthographicCamera camera;
    public Viewport viewport;
    public final GameStats stats = new GameStats();

    @Override
    public void create() {
        batch = new SpriteBatch();
        shapes = new ShapeRenderer();
        font = new BitmapFont();
        font.setUseIntegerPositions(false);
        layout = new GlyphLayout();
        camera = new OrthographicCamera();
        viewport = new FitViewport(Theme.WORLD_W, Theme.WORLD_H, camera);
        centerCamera();
        setScreen(new MenuScreen(this));
    }

    private void centerCamera() {
        camera.position.set(Theme.WORLD_W * 0.5f, Theme.WORLD_H * 0.5f, 0f);
        camera.update();
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, false);
        centerCamera();
        super.resize(width, height);
    }

    /** Point both renderers at the world camera; call at the top of each screen's render. */
    public void useWorldCamera() {
        camera.update();
        batch.setProjectionMatrix(camera.combined);
        shapes.setProjectionMatrix(camera.combined);
    }

    /**
     * Draw one string with the shared font at a relative scale (1.0 = the built-in ~15px font).
     * Must be called inside {@code batch.begin()/end()}. align: -1 left, 0 centre, 1 right of x.
     */
    public void text(String s, float x, float y, float scale, Color color, int align) {
        font.getData().setScale(scale);
        font.setColor(color);
        layout.setText(font, s);
        float dx = x;
        if (align == 0) dx = x - layout.width * 0.5f;
        else if (align == 1) dx = x - layout.width;
        font.draw(batch, layout, dx, y);
    }


    // --- Flow. -------------------------------------------------------------------------------
    public void startRun() {
        stats.reset();
        setScreen(new PlayScreen(this, 0));
    }

    public void toMenu() {
        setScreen(new MenuScreen(this));
    }

    public void toVictory() {
        setScreen(new VictoryScreen(this));
    }

    @Override
    public void dispose() {
        if (getScreen() != null) getScreen().dispose();
        batch.dispose();
        shapes.dispose();
        font.dispose();
    }
}
