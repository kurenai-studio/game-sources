package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

import java.util.Objects;

/**
 * A small filled box in a package color.
 */
@HotPath
public final class HudPackageColorBox {

    private final Color color;

    /**
     * Creates a box filled with the given color.
     *
     * @param color the box's fill color
     *
     * @throws NullPointerException if {@code color} is null
     */
    HudPackageColorBox(Color color) {
        this.color = Objects.requireNonNull(color, "color must not be null");
    }

    /**
     * Draws this box at the given position.
     *
     * @param renderer the shape renderer to draw into
     * @param x the box's left edge, in world units
     * @param y the box's bottom edge, in world units
     * @param size the box's width and height, in world units
     */
    void render(ShapeRenderer renderer, float x, float y, float size) {
        renderer.setColor(color);
        renderer.rect(x, y, size, size);
    }
}
