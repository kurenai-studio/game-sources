package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.render.BoundedViewport;

import com.badlogic.gdx.graphics.Camera;

/**
 * A viewport for HUD content, mapped 1:1 to screen pixels.
 */
public final class HudViewport extends BoundedViewport {

    /**
     * Creates a HUD viewport for the given camera.
     *
     * @param camera the camera this viewport controls
     */
    public HudViewport(Camera camera) {
        super(0f, 0f, camera);
    }

    /**
     * Stretches this viewport to fill the given screen size exactly.
     *
     * @param screenWidth the screen's width in pixels
     * @param screenHeight the screen's height in pixels
     * @param centerCamera whether to center the camera within the viewport
     */
    @Override
    public void update(int screenWidth, int screenHeight, boolean centerCamera) {
        setWorldSize(screenWidth, screenHeight);
        setScreenBounds(0, 0, screenWidth, screenHeight);
        apply(centerCamera);
    }
}
