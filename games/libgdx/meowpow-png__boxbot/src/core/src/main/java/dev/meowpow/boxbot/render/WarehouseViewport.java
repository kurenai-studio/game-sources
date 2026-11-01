package dev.meowpow.boxbot.render;

import com.badlogic.gdx.graphics.Camera;

/**
 * A viewport for the warehouse world.
 */
public final class WarehouseViewport extends BoundedViewport {

    /**
     * Creates a viewport for the given world size and camera.
     *
     * @param worldWidth the world's width in world units
     * @param worldHeight the world's height in world units
     * @param camera the camera this viewport controls
     */
    public WarehouseViewport(float worldWidth, float worldHeight, Camera camera) {
        super(worldWidth, worldHeight, camera);
    }

    /**
     * Stretches this viewport to fill the given screen size.
     *
     * @param screenWidth the screen's width in pixels
     * @param screenHeight the screen's height in pixels
     * @param centerCamera whether to center the camera within the viewport
     */
    @Override
    public void update(int screenWidth, int screenHeight, boolean centerCamera) {
        setScreenBounds(0, 0, screenWidth, screenHeight);
        apply(centerCamera);
    }
}
