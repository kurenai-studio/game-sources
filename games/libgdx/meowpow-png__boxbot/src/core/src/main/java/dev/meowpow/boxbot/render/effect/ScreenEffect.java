package dev.meowpow.boxbot.render.effect;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

/**
 * A visual effect drawn across the entire screen.
 */
@HotPath
@FunctionalInterface
public interface ScreenEffect {

    /**
     * Returns whether this effect currently needs to be drawn.
     */
    default boolean isActive() {
        return true;
    }

    /**
     * Advances this effect by {@code delta}, in seconds.
     * <p>
     * Effects with no time-based state can leave this a no-op.
     *
     * @param delta elapsed time since the last call, in seconds
     */
    default void update(float delta) {}

    /**
     * Draws this effect across the given screen size.
     *
     * @param renderer the shape renderer to draw into
     * @param screenWidth the screen's width, in pixels
     * @param screenHeight the screen's height, in pixels
     */
    void render(ShapeRenderer renderer, float screenWidth, float screenHeight);
}
