package com.lowvoltagegames.pong.entity.paddle;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.lowvoltagegames.pong.entity.GameObject;
import com.lowvoltagegames.pong.entity.InputComponent;

public class PaddleInput implements InputComponent {
    private final int PADDLE_SPEED = 500;

    /**
     * Poll keyboard input and update paddle
     * @param obj object to be updated
     */
    public void update(GameObject obj) {
        if (Gdx.input.isKeyPressed(Input.Keys.UP)) {
            obj.velocity = PADDLE_SPEED;
        } else if (Gdx.input.isKeyPressed(Input.Keys.DOWN)) {
            obj.velocity = PADDLE_SPEED * -1;
        } else {
            obj.velocity = 0;
        }
    }
}
