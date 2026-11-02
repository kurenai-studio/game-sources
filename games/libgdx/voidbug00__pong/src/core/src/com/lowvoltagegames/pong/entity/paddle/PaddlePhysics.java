package com.lowvoltagegames.pong.entity.paddle;

import com.lowvoltagegames.pong.GameScreen;
import com.lowvoltagegames.pong.entity.GameObject;
import com.lowvoltagegames.pong.entity.PhysicsComponent;

/**
 * Physical behaviour of a paddle object
 */
public class PaddlePhysics implements PhysicsComponent {
    /**
     * Move the paddle each tick
     * @param obj GameObject to be updated.
     * @param screen Current screen
     * @param delta Time since last update in millis
     */
    @Override
    public void update(GameObject obj, GameScreen screen, float delta) {
        obj.y += obj.velocity * delta;

        if (obj.y + obj.height > screen.height) {
            obj.y = screen.height - obj.height;
        } else if (obj.y < 0) {
            obj.y = 0;
        }

        screen.resolveCollisions(obj);
    }

    /**
     * Handle collision with another object. Nothing is done.
     * @param obj GameObject handling collision
     * @param collisionObj GameObject that has been collided with
     */
    @Override
    public void collision(GameObject obj, GameObject collisionObj) {

    }
}
