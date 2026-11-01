package dev.meowpow.boxbot.render;

import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * A {@link Viewport} that can be positioned from a screen {@link Rectangle}.
 */
public abstract class BoundedViewport extends Viewport {

    /**
     * Creates a viewport of the given world size and camera.
     *
     * @param worldWidth the world's width, in world units
     * @param worldHeight the world's height, in world units
     * @param camera the camera this viewport controls
     */
    protected BoundedViewport(float worldWidth, float worldHeight, Camera camera) {
        setWorldSize(worldWidth, worldHeight);
        setCamera(camera);
    }

    /**
     * Sets this viewport's screen bounds to the given rectangle, rounded.
     *
     * @param bounds the screen rectangle, in pixels
     */
    public void setScreenBounds(Rectangle bounds) {
        setScreenBounds(
                Math.round(bounds.x),
                Math.round(bounds.y),
                Math.round(bounds.width),
                Math.round(bounds.height)
        );
    }
}
