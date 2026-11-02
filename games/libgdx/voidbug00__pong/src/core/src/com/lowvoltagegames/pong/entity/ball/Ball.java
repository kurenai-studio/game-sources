package com.lowvoltagegames.pong.entity.ball;

import com.lowvoltagegames.pong.entity.GameObject;
import com.lowvoltagegames.pong.entity.GraphicsComponent;
import com.lowvoltagegames.pong.entity.InputComponent;
import com.lowvoltagegames.pong.entity.PhysicsComponent;

/**
 * GameObject representation of a ball
 */
public class Ball extends GameObject {
    private final float WIDTH = 8;
    private final float HEIGHT = 8;
    private final float INITIAL_VELOCITY = 400;

    /**
     * Create a new ball with given components
     * @param input InputComponent to be used for this object
     * @param physics PhysicsComponent to be used for this object
     * @param graphics GraphicsComponent to be used for this object
     */
    public Ball(InputComponent input, PhysicsComponent physics, GraphicsComponent graphics) {
        super(input, physics, graphics);
        this.width = WIDTH;
        this.height = HEIGHT;
        this.velocity = INITIAL_VELOCITY;
    }
}
