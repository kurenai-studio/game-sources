package com.micro1.circuitsalvage;

import com.badlogic.gdx.math.Rectangle;

/** A collectible battery at a fixed tile center. Collected at most once. */
public final class Battery {

    public static final float WIDTH = 22f;
    public static final float HEIGHT = 28f;

    private final float centerX;
    private final float centerY;
    private final Rectangle bounds;
    private boolean collected;

    public Battery(float centerX, float centerY) {
        this.centerX = centerX;
        this.centerY = centerY;
        this.bounds = new Rectangle(centerX - WIDTH / 2f, centerY - HEIGHT / 2f, WIDTH, HEIGHT);
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

    public boolean isCollected() {
        return collected;
    }

    public void reset() {
        collected = false;
    }

    /** Marks this battery collected if not already collected and the player overlaps it. */
    public boolean tryCollect(Rectangle playerBounds) {
        if (collected) {
            return false;
        }
        if (bounds.overlaps(playerBounds)) {
            collected = true;
            return true;
        }
        return false;
    }
}
