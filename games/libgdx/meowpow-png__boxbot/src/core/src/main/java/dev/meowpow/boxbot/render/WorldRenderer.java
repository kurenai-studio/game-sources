package dev.meowpow.boxbot.render;

import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.renderers.OrthogonalTiledMapRenderer;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Disposable;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * Draws the warehouse's tile map, and owns
 * the camera and viewport used to view it.
 */
@HotPath
public final class WorldRenderer implements Disposable {

    private final OrthographicCamera camera;
    private final WarehouseViewport viewport;
    private final OrthogonalTiledMapRenderer mapRenderer;

    private final Vector2 unprojected = new Vector2();

    /**
     * Creates a camera and viewport sized
     * to the given map, centered on its world bounds.
     *
     * @param map the Tiled map to render and size the camera to
     * @param tileSize the map's tile size, in pixels
     */
    public WorldRenderer(TiledMap map, TileSize tileSize) {
        int mapWidth = map.getProperties().get("width", Integer.class);
        int mapHeight = map.getProperties().get("height", Integer.class);

        float worldWidth = mapWidth * tileSize.pixels();
        float worldHeight = mapHeight * tileSize.pixels();

        camera = new OrthographicCamera();
        camera.position.set(worldWidth / 2f, worldHeight / 2f, 0);
        viewport = new WarehouseViewport(worldWidth, worldHeight, camera);

        mapRenderer = new OrthogonalTiledMapRenderer(map);
    }

    /**
     * Returns the camera used to view the world.
     */
    public Camera camera() {
        return camera;
    }

    /**
     * Returns the viewport used to view the world.
     */
    public Viewport viewport() {
        return viewport;
    }

    /**
     * Converts a screen-space point into world coordinates.
     * <p>
     * <strong>API Note:</strong>
     * The returned vector is reused between calls; copy
     * its values before the next call if they must be kept.
     *
     * @param screenX the point's x coordinate, in screen pixels
     * @param screenY the point's y coordinate, in screen pixels
     */
    public Vector2 unproject(int screenX, int screenY) {
        unprojected.set(screenX, screenY);
        viewport.unproject(unprojected);
        return unprojected;
    }

    /**
     * Updates the viewport for the given screen region.
     *
     * @param warehouseRegion the warehouse's screen region
     */
    public void resize(Rectangle warehouseRegion) {
        viewport.setScreenBounds(warehouseRegion);
        viewport.apply(true);
    }

    /**
     * Draws the tile map using the current camera state.
     */
    public void render() {
        viewport.apply();
        camera.update();
        mapRenderer.setView(camera);
        mapRenderer.render();
    }

    @Override
    public void dispose() {
        mapRenderer.dispose();
    }
}
