package com.micro1.shadowclone;

import com.badlogic.gdx.math.Rectangle;

/**
 * A rectangular kinematic body: position (bottom-left), size, velocity, and ground state. Both the
 * {@link Player} and every {@link Clone} are Bodies, and both are advanced by the same
 * {@link Physics#step} routine, which is what guarantees a clone reproduces the player's motion
 * exactly under the same environment.
 */
public class Body {

    public float x, y;
    public float w, h;
    public float vx, vy;
    public boolean onGround;
    public int facing = 1;          // -1 left, +1 right
    public Platform ridingPlatform; // the solid currently carrying this body (may be null)
    public boolean interactedThisStep; // the input frame applied this step pressed interact

    private final Rectangle rect = new Rectangle();

    public Body(float x, float y, float w, float h) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
    }

    /** Live AABB in world space. Reused instance - copy if it must outlive the call. */
    public Rectangle bounds() {
        rect.set(x, y, w, h);
        return rect;
    }

    public float centerX() {
        return x + w * 0.5f;
    }

    public float centerY() {
        return y + h * 0.5f;
    }

    public boolean overlaps(Rectangle r) {
        return x < r.x + r.width && x + w > r.x && y < r.y + r.height && y + h > r.y;
    }
}
