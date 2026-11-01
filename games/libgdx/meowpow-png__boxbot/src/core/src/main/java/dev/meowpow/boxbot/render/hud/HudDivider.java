package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

import java.util.Objects;

/**
 * A horizontal separator line, inset
 * from both edges of the width it's drawn within.
 */
@HotPath
public final class HudDivider {

    private static final float INSET_BASE = 8f;

    private final Color color;
    private final float thickness;
    private final float inset;

    /**
     * Creates a divider drawn
     * with the given color and thickness.
     *
     * @param color the divider's color
     * @param thickness the divider's thickness, in world units
     * @param scale the integer pixel scale to draw the inset at
     *
     * @throws NullPointerException if {@code color} is null
     * @throws IllegalArgumentException if {@code thickness} is not positive
     */
    HudDivider(Color color, float thickness, int scale) {
        this.color = Objects.requireNonNull(color, "color must not be null");
        if (thickness <= 0f) {
            var message = "thickness must be positive: " + thickness;
            throw new IllegalArgumentException(message);
        }
        this.thickness = thickness;
        this.inset = INSET_BASE * scale;
    }

    /**
     * Draws this divider, inset within the
     * given width, at the given distance below the top edge.
     *
     * @param renderer the shape renderer to draw into
     * @param x the containing area's left edge, in world units
     * @param y the containing area's bottom edge, in world units
     * @param width the containing area's width, in world units
     * @param height the containing area's height, in world units
     * @param fromTop the divider's distance below the top edge, in world units
     */
    void render(
            ShapeRenderer renderer,
            float x,
            float y,
            float width,
            float height,
            float fromTop
    ) {
        renderer.setColor(color);

        float rectX = x + inset;
        float rectY = y + height - fromTop - thickness;
        float rectWidth = width - 2f * inset;

        renderer.rect(rectX, rectY, rectWidth, thickness);
    }
}
