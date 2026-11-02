package com.lowvoltagegames.pong.entity.ball;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.lowvoltagegames.pong.GameScreen;
import com.lowvoltagegames.pong.entity.GameObject;
import com.lowvoltagegames.pong.entity.PhysicsComponent;

/**
 * Physical behaviour of a ball object
 */
public class BallPhysics implements PhysicsComponent {
    private final float MIN_ANGLE = (float) (4 * Math.PI / 6);
    private final float MAX_ANGLE = (float) (8 * Math.PI / 6);

    private float angle;

    private Vector2 vel;
    private Vector2 dis;

    public BallPhysics() {
        vel = new Vector2();
        dis = new Vector2();

        this.angle = MathUtils.random(MIN_ANGLE, MAX_ANGLE);

        vel.x = MathUtils.cos(angle) * MathUtils.randomSign();
        vel.y = MathUtils.sin(angle);
    }

    /**
     * Move ball each tick
     * @param obj GameObject to be updated.
     * @param screen Current screen
     * @param delta Time since last update in millis
     */
    @Override
    public void update(GameObject obj, GameScreen screen, float delta) {
        dis.setZero().add(vel).scl(obj.velocity * delta);
        obj.x += dis.x;
        obj.y += dis.y;

        if (obj.y + obj.height >= screen.height) {
            obj.y = screen.height - obj.height;
            vel.y *= -1;
        } else if (obj.y <= 0) {
            obj.y = 0;
            vel.y *= -1;
        }

        if (obj.x + obj.width > screen.width) {
            screen.goalScoredRight(obj);
        } else if (obj.x < 0) {
            screen.goalScoredLeft(obj);
        }

        screen.resolveCollisions(obj);
    }

    /**
     * Handle collision with another object, if the object is a paddle the ball will bounce.
     * @param obj GameObject handling collision
     * @param collisionObj GameObject that has been collided with
     */
    @Override
    public void collision(GameObject obj, GameObject collisionObj) {
        //System.out.println("Collision with:  " + collisionObj.getClass());
        float deltaY = (obj.y + obj.height / 2) - (collisionObj.y + collisionObj.height / 2);
        deltaY = deltaY / collisionObj.height + 0.5f; //normalise delta between 0 and 1
        angle = MAX_ANGLE - deltaY * (MAX_ANGLE - MIN_ANGLE);

        vel.x = MathUtils.cos(angle) * (vel.x / Math.abs(vel.x));
        vel.y = MathUtils.sin(angle);

        obj.velocity = 700;
    }
}
