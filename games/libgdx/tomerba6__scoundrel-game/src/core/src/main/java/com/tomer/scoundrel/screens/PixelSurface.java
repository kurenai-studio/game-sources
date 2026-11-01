package com.tomer.scoundrel.screens;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.glutils.FrameBuffer;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.utils.Disposable;
import com.badlogic.gdx.utils.ScreenUtils;

/**
 * An offscreen surface exactly the size of the design resolution. The board is
 * drawn onto it at 1:1 and the finished image is then scaled to the window in a
 * single step.
 *
 * <p>Without it every draw call is scaled independently, and at a scale that is
 * not a whole number they do not agree. At 1920×1080 the viewport fits at ×1.5,
 * and the five identical 2px stems of the word AVOID come out 3, 2, 2, 3 and 2
 * screen pixels wide — each quad rounded on its own, so identical strokes
 * disagree by half their width. Drawing them onto one integer grid first makes
 * every 2px feature exactly 3 screen pixels, because the whole image is
 * resampled once with one phase instead of a few hundred times with many.
 *
 * <p>It cannot make ×1.5 pixel-perfect — nothing can, since a single design
 * pixel has no whole number of screen pixels to occupy. Features one pixel
 * across still land on one screen pixel or two depending where they fall. What
 * changes is that the choice is made consistently across the whole frame
 * rather than per draw call, which is the difference between a coarse image and
 * a scruffy one.
 */
final class PixelSurface implements Disposable {

    private final FrameBuffer buffer;
    private final TextureRegion region;
    private final OrthographicCamera camera = new OrthographicCamera();

    /**
     * Allocates the frame buffer, {@code Nearest}-filtered.
     *
     * @param width  the surface's width in pixels: the design width, 1280
     * @param height the surface's height in pixels: the design height, 720
     * @see FrameBuffer
     */
    PixelSurface(int width, int height) {
        buffer = new FrameBuffer(Pixmap.Format.RGBA8888, width, height, false);
        // Nearest, obviously: this texture is the pixel art, and the one scale
        // it will ever undergo is the one that happens when it is drawn.
        buffer.getColorBufferTexture().setFilter(
                Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        region = new TextureRegion(buffer.getColorBufferTexture());
        // A frame buffer's texture comes out bottom-up; SpriteBatch expects the
        // other way round, so the region is flipped once here rather than the
        // image being upside down everywhere.
        region.flip(false, true);
        camera.setToOrtho(false, width, height);
        camera.update();
    }

    /**
     * Everything drawn until {@link #end} lands on the surface's own grid.
     *
     * @param clearTo the colour the surface starts the frame as; must be opaque, as
     *                {@link #draw} copies rather than blends
     */
    void begin(Color clearTo) {
        buffer.begin();
        ScreenUtils.clear(clearTo);
    }

    /** Unbinds the surface; drawing goes to the window again. */
    void end() {
        buffer.end();
    }

    /**
     * The projection to draw with while the surface is bound: 1:1, y-up.
     *
     * @return the surface camera's combined matrix
     */
    com.badlogic.gdx.math.Matrix4 projection() {
        return camera.combined;
    }

    /**
     * Draws the finished surface to the window, at world size, exactly once.
     *
     * <p><b>With blending off</b>, and that is not an optimisation. Ordinary
     * blending applies to the alpha channel as well as to colour, so every
     * translucent draw <em>into</em> the surface erodes the alpha it lands on:
     * something drawn at 72% leaves the destination at 0.72² + 0.28 = 0.798
     * rather than the 1 it started at. Blending the surface out again then
     * multiplies its colour by that eroded alpha, and every translucent element
     * in the frame comes out darker than it was drawn — measured at 0.55 for a
     * 0.72 fill, over a black clear.
     *
     * <p>The surface is the whole frame and opaque by construction: it is
     * cleared to an opaque colour and covers the viewport. There is nothing
     * behind it to blend with, so it is copied rather than composited.
     *
     * @param batch  a batch on the viewport's projection, already begun; blending is
     *               switched back on afterwards
     * @param width  the width to draw at, in world units: the design width
     * @param height the height to draw at, in world units: the design height
     */
    void draw(Batch batch, float width, float height) {
        batch.disableBlending();
        batch.draw(region, 0, 0, width, height);
        batch.enableBlending();
    }

    @Override
    public void dispose() {
        buffer.dispose();
    }
}
