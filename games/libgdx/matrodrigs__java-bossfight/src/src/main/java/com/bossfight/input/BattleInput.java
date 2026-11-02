package com.bossfight.input;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.bossfight.entities.PlayerInput;

public final class BattleInput {
    private boolean jumpQueued;
    private boolean dashQueued;
    private boolean specialQueued;
    private boolean moveLeft;
    private boolean moveRight;
    private boolean shootHeld;

    public void poll() {
        jumpQueued |= Gdx.input.isKeyJustPressed(Input.Keys.SPACE);
        dashQueued |= Gdx.input.isKeyJustPressed(Input.Keys.SHIFT_LEFT);
        specialQueued |= Gdx.input.isButtonJustPressed(Input.Buttons.RIGHT);

        moveLeft = Gdx.input.isKeyPressed(Input.Keys.A);
        moveRight = Gdx.input.isKeyPressed(Input.Keys.D);
        shootHeld = Gdx.input.isButtonPressed(Input.Buttons.LEFT);
    }

    public boolean isShootHeld() {
        return shootHeld;
    }

    public PlayerInput consumePlayerInput() {
        PlayerInput input = new PlayerInput(moveLeft, moveRight, jumpQueued, dashQueued);
        jumpQueued = false;
        dashQueued = false;
        return input;
    }

    public boolean consumeSpecial() {
        boolean queued = specialQueued;
        specialQueued = false;
        return queued;
    }
}
