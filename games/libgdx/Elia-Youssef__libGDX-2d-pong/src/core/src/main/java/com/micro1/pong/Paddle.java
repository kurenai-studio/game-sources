package com.micro1.pong;

/**
 * A paddle as pure state (no libGDX / GL dependency) so the mechanics stay headless-testable.
 * Positions are bottom-left, in the 800x600 field. Size is {@link PongWorld#PADDLE_W} x
 * {@link PongWorld#PADDLE_H}.
 */
public class Paddle {
    public float x;
    public float y;

    public Paddle(float x, float y) {
        this.x = x;
        this.y = y;
    }

    /** Vertical center of the paddle, used by the bounce-angle formula. */
    public float centerY() {
        return y + PongWorld.PADDLE_H / 2f;
    }
}
