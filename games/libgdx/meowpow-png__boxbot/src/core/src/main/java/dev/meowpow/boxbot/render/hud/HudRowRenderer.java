package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;

/**
 * Draws a single visible row.
 */
@HotPath
@FunctionalInterface
public interface HudRowRenderer {

    /**
     * Draws the row at the given index within its allotted bounds.
     *
     * @param batch the batch to draw into
     * @param index the row's index into the backing data
     * @param x the row's left edge, in world units
     * @param y the row's bottom edge, in world units
     * @param width the row's width, in world units
     * @param height the row's height, in world units
     */
    void renderRow(
            SpriteBatch batch,
            int index,
            float x,
            float y,
            float width,
            float height
    );
}
