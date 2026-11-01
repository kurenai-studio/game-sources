package dev.meowpow.boxbot.render;

import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.spatial.InterpolatedFacing;
import dev.meowpow.boxbot.engine.spatial.InterpolatedPosition;
import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.engine.time.Alpha;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.assets.LightingOverlays;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.glutils.FrameBuffer;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Disposable;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * Darkens the world outside the robot's headlight beam.
 */
@HotPath
public final class LightingRenderer implements Disposable {

    private static final float DARKNESS_ALPHA = 0.6f;
    private static final float HEADLIGHT_WIDTH = 80f;
    private static final float HEADLIGHT_HEIGHT = 35f;
    private static final float ROBOT_OFFSET = 11.3f;

    private final TileSize tileSize;
    private final LightingOverlays overlays;

    private final TextureRegion maskRegion;

    private final FrameBuffer maskBuffer;
    private final SpriteBatch batch = new SpriteBatch();

    private final InterpolatedPosition robotPosition = new InterpolatedPosition();
    private final InterpolatedFacing robotFacing = new InterpolatedFacing();

    private final int worldWidth;
    private final int worldHeight;

    /**
     * Allocates a mask buffer sized to the given map,
     * drawing lighting with the given overlay textures.
     *
     * @param map the Tiled map whose dimensions size the lighting mask
     * @param tileSize the map's tile size, in pixels
     * @param overlays the overlay textures used to render lighting
     */
    public LightingRenderer(TiledMap map, TileSize tileSize, LightingOverlays overlays) {
        this.tileSize = tileSize;
        this.overlays = overlays;

        int mapWidth = map.getProperties().get("width", Integer.class);
        int mapHeight = map.getProperties().get("height", Integer.class);

        worldWidth = mapWidth * tileSize.pixels();
        worldHeight = mapHeight * tileSize.pixels();

        maskBuffer = new FrameBuffer(Pixmap.Format.RGBA8888, worldWidth, worldHeight, false);
        maskRegion = new TextureRegion(maskBuffer.getColorBufferTexture());
        maskRegion.flip(false, true);
    }

    /**
     * Draws the lighting mask for one frame,
     * following the robot's interpolated position and facing.
     *
     * @param camera the camera whose view the mask is drawn into
     * @param viewport the game's active viewport, restored after mask rendering
     * @param world the simulation state supplying the robot's position and facing
     * @param alpha the interpolation fraction between the previous and current simulation tick
     */
    public void render(Camera camera, Viewport viewport, World world, Alpha alpha) {
        var robot = world.robot();

        robotPosition.set(robot.previousPosition(), robot.position(), alpha);
        robotFacing.set(robot.previousFacing(), robot.facing(), alpha);

        float rotation = robotFacing.degrees();
        float noseX = robotPosition.centerX(tileSize) - MathUtils.sinDeg(rotation) * ROBOT_OFFSET;
        float noseY = robotPosition.centerY(tileSize) + MathUtils.cosDeg(rotation) * ROBOT_OFFSET;

        renderMask(camera, viewport, noseX, noseY, rotation);

        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        batch.draw(maskRegion, 0f, 0f, camera.viewportWidth, camera.viewportHeight);
        batch.end();
    }

    /**
     * Renders the darkness-and-headlight mask
     * into {@link #maskBuffer} for the given
     * light position and rotation.
     * <p>
     * <strong>Implementation Note:</strong>
     * The darkness pass uses separate alpha blend factors because writing
     * into the empty buffer would otherwise square darkness's own alpha
     * ({@code GL_SRC_ALPHA} on an empty destination self-multiplies it).
     * <p>
     * Afterward, {@link FrameBuffer#end()} is called with explicit screen
     * bounds because its no-arg form resets the GL viewport to the full
     * back-buffer, undoing the game's letterboxed, integer-scaled viewport.
     */
    private void renderMask(
            Camera camera,
            Viewport viewport,
            float lightX,
            float lightY,
            float lightRotation
    ) {
        maskBuffer.begin();
        Gdx.gl.glClearColor(0f, 0f, 0f, 0f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        batch.setBlendFunctionSeparate(
                GL20.GL_SRC_ALPHA,
                GL20.GL_ONE_MINUS_SRC_ALPHA,
                GL20.GL_ONE,
                GL20.GL_ONE_MINUS_SRC_ALPHA
        );
        var prevColor = batch.getColor();
        batch.setColor(1f, 1f, 1f, DARKNESS_ALPHA);
        batch.draw(overlays.darkness(), 0f, 0f, worldWidth, worldHeight);

        batch.setBlendFunction(GL20.GL_ZERO, GL20.GL_ONE_MINUS_SRC_ALPHA);
        batch.setColor(prevColor);
        batch.draw(
                overlays.headlight(),
                lightX - HEADLIGHT_WIDTH / 2f, lightY,
                HEADLIGHT_WIDTH / 2f, 0f,
                HEADLIGHT_WIDTH, HEADLIGHT_HEIGHT,
                1f, 1f,
                lightRotation
        );
        batch.setBlendFunction(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);

        batch.end();
        maskBuffer.end(
                viewport.getScreenX(),
                viewport.getScreenY(),
                viewport.getScreenWidth(),
                viewport.getScreenHeight()
        );
    }

    @Override
    public void dispose() {
        batch.dispose();
        maskBuffer.dispose();
    }
}
