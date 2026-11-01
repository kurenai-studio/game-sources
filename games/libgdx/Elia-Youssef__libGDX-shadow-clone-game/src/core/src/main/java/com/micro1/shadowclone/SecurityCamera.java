package com.micro1.shadowclone;

import com.badlogic.gdx.math.MathUtils;

/**
 * A ceiling-mounted security camera with a sweeping detection cone (Security Facility, item 6). It
 * reacts to clones (item 7) and can be bypassed by them (item 8): while a clone stands inside the
 * cone the camera locks onto it and is "distracted", so the player can slip past. If the camera sees
 * the player while not distracted, it raises an alert (the current recording fails and a DETECTED
 * banner flashes) rather than killing, which keeps the level fair.
 */
public final class SecurityCamera {

    public final float mountX, mountY;
    public final float baseAngle;    // degrees, direction the cone points
    public final float sweepHalf;    // degrees of sweep to each side
    public final float halfAngle;    // cone half-width
    public final float range;
    public final float period;       // seconds per full sweep

    public String controlId;         // a clone holding this switch disables the camera (bypass)
    private float time;
    public float angle;              // current cone direction (degrees)
    public boolean distracted;       // a clone is in the cone this step
    public boolean disabled;         // controlId switch held: camera is offline
    public boolean alerted;          // saw the player this step (and was not distracted/disabled)

    public SecurityCamera(float mountX, float mountY, float baseAngle, float sweepHalf,
                          float halfAngle, float range, float period) {
        this.mountX = mountX;
        this.mountY = mountY;
        this.baseAngle = baseAngle;
        this.sweepHalf = sweepHalf;
        this.halfAngle = halfAngle;
        this.range = range;
        this.period = period;
        this.angle = baseAngle;
    }

    public void advance(float dt) {
        time += dt;
        angle = baseAngle + sweepHalf * MathUtils.sinDeg(360f * (time / period));
    }

    public boolean sees(float px, float py) {
        float dx = px - mountX;
        float dy = py - mountY;
        float dist = (float) Math.sqrt(dx * dx + dy * dy);
        if (dist > range || dist < 1f) return false;
        float toPoint = MathUtils.atan2(dy, dx) * MathUtils.radiansToDegrees;
        float diff = Math.abs(deltaDeg(toPoint, angle));
        return diff <= halfAngle;
    }

    private static float deltaDeg(float a, float b) {
        float d = (a - b + 540f) % 360f - 180f;
        return d;
    }

    public void reset() {
        time = 0f;
        angle = baseAngle;
        distracted = false;
        disabled = false;
        alerted = false;
    }
}
