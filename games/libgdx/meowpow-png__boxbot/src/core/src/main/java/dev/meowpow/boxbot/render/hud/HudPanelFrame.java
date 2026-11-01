package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

import java.util.Objects;

/**
 * A HUD panel's background and border.
 */
@HotPath
public final class HudPanelFrame {

    private final Color fillColor;
    private final Color borderColor;
    private final float borderThickness;
    private final HudDivider divider;

    /**
     * Creates a panel with the given fill and border colors.
     *
     * @param fillColor the panel's background fill color
     * @param borderColor the panel's border color
     * @param borderThickness the panel's border thickness, in world units
     * @param dividerThickness the panel's divider thickness, in world units
     * @param scale the integer pixel scale to draw the divider's inset at
     *
     * @throws NullPointerException if {@code fillColor} or {@code borderColor} is null
     * @throws IllegalArgumentException if {@code borderThickness} is not positive
     */
    public HudPanelFrame(
            Color fillColor,
            Color borderColor,
            float borderThickness,
            float dividerThickness,
            int scale
    ) {
        Objects.requireNonNull(fillColor, "fillColor must not be null");
        Objects.requireNonNull(borderColor, "borderColor must not be null");

        this.fillColor = fillColor;
        this.borderColor = borderColor;
        if (borderThickness <= 0f) {
            var message = "borderThickness must be positive: " + borderThickness;
            throw new IllegalArgumentException(message);
        }
        this.borderThickness = borderThickness;
        this.divider = new HudDivider(borderColor, dividerThickness, scale);
    }

    /**
     * Draws the panel's background and border at the
     * given position, filling the given width and height.
     *
     * @param renderer the shape renderer to draw into
     * @param x the panel's left edge, in world units
     * @param y the panel's bottom edge, in world units
     * @param width the panel's width, in world units
     * @param height the panel's height, in world units
     */
    public void render(ShapeRenderer renderer, float x, float y, float width, float height) {
        renderer.setColor(fillColor);
        renderer.rect(x, y, width, height);
        renderer.setColor(borderColor);
        drawBorder(renderer, x, y, width, height);
    }

    /**
     * Draws the panel's background and border at the given position.
     *
     * @param renderer the shape renderer to draw into
     * @param x the panel's left edge, in world units
     * @param y the panel's bottom edge, in world units
     * @param width the panel's width, in world units
     * @param height the panel's height, in world units
     * @param dividerFromTop the divider's distance below the top edge, in world units
     */
    public void render(
            ShapeRenderer renderer,
            float x,
            float y,
            float width,
            float height,
            float dividerFromTop
    ) {
        render(renderer, x, y, width, height);
        divider.render(renderer, x, y, width, height, dividerFromTop);
    }

    private void drawBorder(ShapeRenderer renderer, float x, float y, float width, float height) {
        renderer.rect(x, y + height - borderThickness, width, borderThickness);
        renderer.rect(x, y, width, borderThickness);
        renderer.rect(x, y, borderThickness, height);
        renderer.rect(
                x + width - borderThickness,
                y,
                borderThickness,
                height
        );
    }
}
