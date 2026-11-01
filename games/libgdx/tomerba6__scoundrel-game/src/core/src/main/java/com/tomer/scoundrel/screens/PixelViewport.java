package com.tomer.scoundrel.screens;

import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * A {@code FitViewport} that only ever scales by a clean factor, so the pixel
 * art lands on whole screen pixels at any window size.
 *
 * <p>{@code FitViewport} scales by whatever fraction fills the window, which at
 * 1600×900 is ×1.25 — putting a 64px sprite drawn at ×2 onto 160 screen pixels,
 * or 2.5 screen pixels per source pixel. Some source pixels then get two screen
 * pixels and their neighbours three, and the art crawls as it moves. This
 * snaps the scale down instead (see {@link PixelScale}) and letterboxes the
 * remainder.
 *
 * <p>All the arithmetic lives in {@code PixelScale} so it can be unit tested;
 * this class only turns the result into screen bounds.
 */
final class PixelViewport extends Viewport {

    /**
     * A viewport onto a fixed design space, with its own orthographic camera.
     *
     * @param worldWidth  the design width, 1280 on every screen
     * @param worldHeight the design height, 720 on every screen
     */
    PixelViewport(float worldWidth, float worldHeight) {
        setWorldSize(worldWidth, worldHeight);
        setCamera(new OrthographicCamera());
    }

    @Override
    public void update(int screenWidth, int screenHeight, boolean centerCamera) {
        float scale = PixelScale.forScreen(screenWidth, screenHeight, getWorldWidth(), getWorldHeight());
        int viewWidth = MathUtils.round(getWorldWidth() * scale);
        int viewHeight = MathUtils.round(getWorldHeight() * scale);
        // Centre the bars, and keep the offsets whole so the whole image sits on
        // the pixel grid rather than straddling it by a half.
        setScreenBounds((screenWidth - viewWidth) / 2, (screenHeight - viewHeight) / 2,
                viewWidth, viewHeight);
        apply(centerCamera);
    }
}
