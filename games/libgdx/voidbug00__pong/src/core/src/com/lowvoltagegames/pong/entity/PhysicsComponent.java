package com.lowvoltagegames.pong.entity;

import com.lowvoltagegames.pong.GameScreen;

/**
 * Component to represent physical behaviour of an object
 */
public interface PhysicsComponent {
    /**
     * Update the object each tick
     * @param obj GameObject to be updated.
     * @param screen Current screen
     * @param delta Time since last update in millis
     */
    void update(GameObject obj, GameScreen screen, float delta);

    /**
     * Resolve collision between objects
     * @param obj GameObject handling collision
     * @param collisionObj GameObject that has been collided with
     */
    void collision(GameObject obj, GameObject collisionObj);
}
