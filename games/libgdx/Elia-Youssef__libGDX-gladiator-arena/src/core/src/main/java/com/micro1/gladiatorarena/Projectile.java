package com.micro1.gladiatorarena;

import com.badlogic.gdx.math.Rectangle;

/**
 * A player projectile: a small white circle at (x, y) moving in a straight line at (vx, vy).
 * Collisions use the AABB bounding box of the circle.
 */
public class Projectile {

    public float x;
    public float y;
    public float vx;
    public float vy;

    private final Rectangle bounds = new Rectangle();

    public Projectile(float x, float y, float vx, float vy) {
        this.x = x;
        this.y = y;
        this.vx = vx;
        this.vy = vy;
    }

    /** AABB bounds (10x10), reused (no per-frame allocation). */
    public Rectangle bounds() {
        float d = ArenaWorld.PROJECTILE_RADIUS * 2f;
        bounds.set(x - ArenaWorld.PROJECTILE_RADIUS, y - ArenaWorld.PROJECTILE_RADIUS, d, d);
        return bounds;
    }
}
