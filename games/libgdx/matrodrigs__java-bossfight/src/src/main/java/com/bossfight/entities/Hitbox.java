package com.bossfight.entities;

import com.badlogic.gdx.math.Rectangle;

public class Hitbox {
    private final Rectangle bounds;

    public Hitbox(float x, float y, float width, float height) {
        bounds = new Rectangle(x, y, width, height);
    }

    public void setPosition(float x, float y) {
        bounds.setPosition(x, y);
    }

    public boolean overlaps(Hitbox other) {
        return bounds.overlaps(other.bounds);
    }

    public Rectangle getBounds() {
        return bounds;
    }
}
