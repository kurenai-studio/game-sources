package com.micro1.shadowclone;

/** The live, keyboard-controlled body. Advanced by {@link Physics#step} with live input. */
public final class Player extends Body {

    public Player(float x, float y) {
        super(x, y, Theme.PLAYER_W, Theme.PLAYER_H);
    }

    public void resetTo(float x, float y) {
        this.x = x;
        this.y = y;
        this.vx = 0f;
        this.vy = 0f;
        this.onGround = false;
        this.ridingPlatform = null;
        this.facing = 1;
    }
}
