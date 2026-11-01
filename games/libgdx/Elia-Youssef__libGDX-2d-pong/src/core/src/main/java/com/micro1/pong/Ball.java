package com.micro1.pong;

/**
 * The ball as pure state (no libGDX / GL dependency). Position is bottom-left; it is a square of
 * {@link PongWorld#BALL} pixels. {@code speed} is the current total speed magnitude (px/s); the
 * velocity components {@code vx,vy} always satisfy {@code vx*vx + vy*vy == speed*speed}.
 */
public class Ball {
    public float x;
    public float y;
    public float vx;
    public float vy;
    public float speed;

    public float centerX() {
        return x + PongWorld.BALL / 2f;
    }

    public float centerY() {
        return y + PongWorld.BALL / 2f;
    }
}
