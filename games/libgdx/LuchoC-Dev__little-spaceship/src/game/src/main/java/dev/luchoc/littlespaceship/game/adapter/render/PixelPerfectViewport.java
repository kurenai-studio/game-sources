package dev.luchoc.littlespaceship.game.adapter.render;

import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * A viewport that only ever scales the logical resolution by a whole number.
 *
 * <p>libGDX's stock viewports — {@code FitViewport} included — scale by whatever fractional factor
 * fits the window, which blurs nearest-neighbour pixel art the moment the window size is not an
 * exact multiple of the logical resolution. This one rounds the scale down to the nearest integer
 * and centres the result, leaving the remainder as letterbox bars instead of a soft edge.
 *
 * <p>{@code CLAUDE.md} states this policy as a project invariant; {@code 10-mvp-initial-values.md}
 * proposes the concrete 480x270 this project uses, confirmed by the technical prototype.
 */
public final class PixelPerfectViewport extends Viewport {

    public PixelPerfectViewport(float worldWidth, float worldHeight, Camera camera) {
        setWorldSize(worldWidth, worldHeight);
        setCamera(camera);
    }

    @Override
    public void update(int screenWidth, int screenHeight, boolean centerCamera) {
        int scale = (int) Math.max(1f,
            Math.floor(Math.min(
                screenWidth / getWorldWidth(),
                screenHeight / getWorldHeight())));

        int viewportWidth = Math.round(getWorldWidth() * scale);
        int viewportHeight = Math.round(getWorldHeight() * scale);

        setScreenBounds(
            (screenWidth - viewportWidth) / 2,
            (screenHeight - viewportHeight) / 2,
            viewportWidth,
            viewportHeight);

        apply(centerCamera);
    }
}
