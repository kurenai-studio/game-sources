package dev.meowpow.boxbot.render.menu;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

/**
 * Single content element stacked
 * inside a {@link MenuRenderer}'s panel.
 */
@HotPath
public interface MenuComponent {

    /**
     * Returns this component's height.
     */
    float height();

    /**
     * Draws this component's filled shapes, if any.
     *
     * @param shapeRenderer the shape renderer to draw into, already begun
     * @param x the component's left edge
     * @param y the component's bottom edge
     * @param width the width available to center or fill within
     */
    default void renderShapes(ShapeRenderer shapeRenderer, float x, float y, float width) {}

    /**
     * Draws this component's text, if any.
     *
     * @param batch the sprite batch to draw into, already begun
     * @param x the component's left edge
     * @param y the component's bottom edge
     * @param width the width available to center or fill within
     */
    default void renderText(SpriteBatch batch, float x, float y, float width) {}
}
