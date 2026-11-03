package io.github.darellanodev.monkeybananarun;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;

public class Banana {
    private final Sprite sprite;
    private final Rectangle bounds;

    public Banana(Texture texture, float x, float y) {
        sprite = new Sprite(texture);
        sprite.setSize(1f, 1f);
        sprite.setPosition(x, y);
        bounds = new Rectangle();
        updateBounds();
    }

    private void updateBounds() {
        bounds.set(sprite.getX(), sprite.getY(), sprite.getWidth(), sprite.getHeight());
    }

    public void draw(SpriteBatch batch) {
        sprite.draw(batch);
    }

    public Rectangle getBounds() {
        return bounds;
    }
}
