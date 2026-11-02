package com.lowvoltagegames.pong.entity.paddle;

import com.lowvoltagegames.pong.entity.GameObject;
import com.lowvoltagegames.pong.entity.GraphicsComponent;
import com.lowvoltagegames.pong.entity.InputComponent;
import com.lowvoltagegames.pong.entity.PhysicsComponent;

/**
 * GameObject representation of a paddle
 */
public class Paddle extends GameObject {
    private final float WIDTH = 16;
    private final float HEIGHT = 96;

    public Paddle(InputComponent input, PhysicsComponent physics, GraphicsComponent graphics) {
        super(input, physics, graphics);
        this.width = WIDTH;
        this.height = HEIGHT;
    }
}
