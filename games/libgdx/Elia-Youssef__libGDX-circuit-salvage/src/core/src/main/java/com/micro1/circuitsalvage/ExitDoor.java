package com.micro1.circuitsalvage;

import com.badlogic.gdx.math.Rectangle;

/** The exit at tile (7,7): locked until all batteries are collected, then open. */
public final class ExitDoor {

    public static final float SIZE = 38f;

    private final float centerX;
    private final float centerY;
    private final Rectangle bounds;
    private boolean locked;

    public ExitDoor(float centerX, float centerY) {
        this.centerX = centerX;
        this.centerY = centerY;
        this.bounds = new Rectangle(centerX - SIZE / 2f, centerY - SIZE / 2f, SIZE, SIZE);
        this.locked = true;
    }

    public float getCenterX() {
        return centerX;
    }

    public float getCenterY() {
        return centerY;
    }

    public Rectangle getBounds() {
        return bounds;
    }

    public boolean isLocked() {
        return locked;
    }

    public void setLocked(boolean locked) {
        this.locked = locked;
    }

    public void reset() {
        locked = true;
    }

    public boolean overlaps(Rectangle playerBounds) {
        return bounds.overlaps(playerBounds);
    }
}
