package dev.meowpow.boxbot.render.effect;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.hud.HudViewport;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Disposable;

/**
 * Controls various screen effects.
 */
@HotPath
public final class ScreenFxController implements Disposable {

    private final OrthographicCamera camera = new OrthographicCamera();
    private final HudViewport viewport = new HudViewport(camera);
    private final ShapeRenderer shapeRenderer = new ShapeRenderer();

    private final Array<ScreenEffect> effects = new Array<>();

    private float screenWidth;
    private float screenHeight;

    /**
     * Registers an effect to be updated and drawn.
     *
     * @param effect the effect to add
     */
    public void addEffect(ScreenEffect effect) {
        effects.add(effect);
    }

    /**
     * Unregisters a previously added effect.
     *
     * @param effect the effect to remove
     */
    public void removeEffect(ScreenEffect effect) {
        effects.removeValue(effect, true);
    }

    /**
     * Updates this controller's viewport for the given screen size.
     *
     * @param width the screen's width, in pixels
     * @param height the screen's height, in pixels
     */
    public void resize(int width, int height) {
        screenWidth = width;
        screenHeight = height;

        viewport.update(width, height, true);
    }

    /**
     * Advances every screen effect by {@code delta}, in seconds.
     *
     * @param delta elapsed time since the last call, in seconds
     */
    public void update(float delta) {
        for (int i = 0; i < effects.size; i++) {
            effects.get(i).update(delta);
        }
    }

    /**
     * Draws every screen effect over the current frame.
     */
    public void render() {
        viewport.apply();

        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);

        shapeRenderer.setProjectionMatrix(camera.combined);
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);
        for (int i = 0; i < effects.size; i++) {
            var effect = effects.get(i);
            if (effect.isActive()) {
                effect.render(shapeRenderer, screenWidth, screenHeight);
            }
        }
        shapeRenderer.end();
    }

    @Override
    public void dispose() {
        shapeRenderer.dispose();
    }
}
