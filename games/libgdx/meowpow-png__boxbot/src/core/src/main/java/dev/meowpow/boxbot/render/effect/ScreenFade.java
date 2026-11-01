package dev.meowpow.boxbot.render.effect;

import dev.meowpow.boxbot.engine.time.AlphaTimer;
import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

/**
 * Fades the screen to and from a solid color, over time.
 */
@HotPath
public final class ScreenFade implements ScreenEffect {

    private final ScreenTint tint = new ScreenTint();
    private final AlphaTimer timer;

    private boolean fading;
    private boolean fadingOut;

    /**
     * Creates a fade that starts fully transparent,
     * taking a given duration in seconds to complete.
     *
     * @param duration the fade's duration, in seconds
     *
     * @throws IllegalArgumentException if {@code duration} is not positive
     */
    public ScreenFade(float duration) {
        timer = new AlphaTimer(duration);
        tint.setAlpha(0f);
    }

    /**
     * Starts fading the screen to {@code color}.
     *
     * @param color the color to fade to
     */
    public void fadeOut(Color color) {
        tint.setColor(color);
        tint.setAlpha(0f);
        timer.reset();
        fadingOut = true;
        fading = true;
    }

    /**
     * Starts fading the screen away from its current color.
     */
    public void fadeIn() {
        timer.reset();
        fadingOut = false;
        fading = true;
    }

    /**
     * Returns whether a fade is currently in progress.
     */
    public boolean isFading() {
        return fading;
    }

    @Override
    public void update(float delta) {
        if (!fading) {
            return;
        }
        timer.update(delta);

        float progress = timer.alpha().value();
        tint.setAlpha(fadingOut ? progress : 1f - progress);
        if (timer.isFinished()) {
            fading = false;
        }
    }

    @Override
    public boolean isActive() {
        return tint.isActive();
    }

    @Override
    public void render(ShapeRenderer renderer, float screenWidth, float screenHeight) {
        tint.render(renderer, screenWidth, screenHeight);
    }
}
