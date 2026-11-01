package dev.meowpow.boxbot.render.menu;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.hud.HudViewport;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.Disposable;

/**
 * A shared screen-space drawing surface for menu overlays.
 * <p>
 * Owns the GL resources a {@link MenuRenderer} draws with,
 * so multiple menus that never render in the same frame can
 * share one camera, viewport, shape renderer, and sprite
 * batch instead of each allocating their own.
 */
@HotPath
public final class MenuCanvas implements Disposable {

    private final OrthographicCamera camera = new OrthographicCamera();
    private final HudViewport viewport = new HudViewport(camera);
    private final ShapeRenderer shapeRenderer = new ShapeRenderer();
    private final SpriteBatch batch = new SpriteBatch();

    private float screenWidth;
    private float screenHeight;

    /**
     * Updates this canvas's viewport for the given screen size.
     *
     * @param width the screen width in pixels
     * @param height the screen height in pixels
     */
    public void resize(int width, int height) {
        screenWidth = width;
        screenHeight = height;
        viewport.update(width, height, true);
    }

    /**
     * Returns the current screen width, in pixels.
     */
    public float screenWidth() {
        return screenWidth;
    }

    /**
     * Returns the current screen height, in pixels.
     */
    public float screenHeight() {
        return screenHeight;
    }

    /**
     * Returns the shape renderer for drawing filled shapes.
     */
    public ShapeRenderer shapeRenderer() {
        return shapeRenderer;
    }

    /**
     * Returns the sprite batch for drawing text.
     */
    public SpriteBatch batch() {
        return batch;
    }

    /**
     * Applies this canvas's viewport and begins
     * filled-shape drawing, with alpha blending enabled.
     */
    public void beginShapes() {
        viewport.apply();

        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);

        shapeRenderer.setProjectionMatrix(camera.combined);
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);
    }

    /**
     * Ends filled-shape drawing started by {@link #beginShapes()}.
     */
    public void endShapes() {
        shapeRenderer.end();
    }

    /**
     * Begins text drawing.
     */
    public void beginBatch() {
        batch.setProjectionMatrix(camera.combined);
        batch.begin();
    }

    /**
     * Ends text drawing started by {@link #beginBatch()}.
     */
    public void endBatch() {
        batch.end();
    }

    @Override
    public void dispose() {
        shapeRenderer.dispose();
        batch.dispose();
    }
}
