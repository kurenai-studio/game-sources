package com.micro1.projectileaiming;

/**
 * A stationary circular target. Once {@link #hit} it stays on screen but is visibly marked
 * and no longer counts as active (skipped by collision and preview termination).
 */
public class Target {

    public final float x;
    public final float y;
    public final float radius;
    public boolean hit;

    public Target(float x, float y, float radius) {
        this.x = x;
        this.y = y;
        this.radius = radius;
    }
}
