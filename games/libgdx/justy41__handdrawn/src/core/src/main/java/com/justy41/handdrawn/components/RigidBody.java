package com.justy41.handdrawn.components;

import com.badlogic.gdx.math.Vector2;

/**
 * Component that holds data for simple physics interactions.
 * IMPORTANT: when on ground (collider.touching.get("down")) its good practice to set the gravity to 1
 * and NOT 0, as 0 makes the ground check jumble up.
 */
public class RigidBody extends Component {
    public Vector2 velocity;
    public float gravity;

    public RigidBody() {
        velocity = new Vector2(0, 0);
        gravity = 0;
    }

    public RigidBody(float velX, float velY, float gravity) {
        velocity = new Vector2(velX, velY);
        this.gravity = gravity;
    }
}
