package dev.meowpow.boxbot.render.effect;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

/**
 * A flat color wash, drawn across the entire screen.
 */
@HotPath
public final class ScreenTint implements ScreenEffect {

    private final Color color = new Color(Color.BLACK);

    /**
     * Sets this tint's color, alpha included.
     *
     * @param color the new tint color
     */
    public void setColor(Color color) {
        this.color.set(color);
    }

    /**
     * Sets this tint's opacity, leaving its color untouched.
     *
     * @param alpha the new opacity, in [0, 1]
     */
    public void setAlpha(float alpha) {
        color.a = alpha;
    }

    @Override
    public boolean isActive() {
        return color.a > 0f;
    }

    @Override
    public void render(ShapeRenderer renderer, float screenWidth, float screenHeight) {
        renderer.setColor(color);
        renderer.rect(0f, 0f, screenWidth, screenHeight);
    }
}
