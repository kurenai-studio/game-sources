package com.micro1.monstercafe;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;

/**
 * A simple rectangular text button used on the Victory / Game Over screens: a colored fill with a dark
 * border (drawn during a {@link ShapeRenderer} pass) plus a caption drawn separately during a SpriteBatch
 * pass. Its rectangle is the click hit-box.
 */
public class MenuButton {
    private static final Color BORDER = new Color(0.12f, 0.06f, 0.16f, 1f);

    public final Rectangle bounds = new Rectangle();
    public final String caption;
    private final Color fill;

    public MenuButton(String caption, Color fill, float cx, float cy, float w, float h) {
        this.caption = caption;
        this.fill = fill;
        bounds.set(cx - w / 2f, cy - h / 2f, w, h);
    }

    public void drawFill(ShapeRenderer shapes) {
        shapes.setColor(BORDER);
        shapes.rect(bounds.x, bounds.y, bounds.width, bounds.height);
        shapes.setColor(fill);
        shapes.rect(bounds.x + 4f, bounds.y + 4f, bounds.width - 8f, bounds.height - 8f);
    }

    public float centerX() {
        return bounds.x + bounds.width / 2f;
    }

    public float centerY() {
        return bounds.y + bounds.height / 2f;
    }

    public boolean contains(float x, float y) {
        return bounds.contains(x, y);
    }
}
