package com.github.sharkBoids.shark;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;
import com.github.sharkBoids.fish.Fish;

public class Shark {
    Texture texture;
    public Vector2 position;
    public Vector2 velocity;
    Vector2 acceleration;
    float maxSpeed = 150f;
    float maxForce = 50f;

    // Boids parameters.
    float neighborDist = 100f;
    float desiredSeparation = 40f;
    // Adjusted weights:
    float separationWeight = 3.0f;   // Increase repulsion so sharks spread into more groups.
    float alignmentWeight = 1.0f;
    float cohesionWeight = 0.5f;     // Lower cohesion so they don't clump together too tightly.
    float pursuitWeight = 2.0f;      // New weight to drive sharks towards the fish.

    public Shark(Texture texture, Vector2 position) {
        this.texture = texture;
        this.position = position;
        // Start with a random velocity.
        this.velocity = new Vector2((float)Math.random() * 2 - 1, (float)Math.random() * 2 - 1).nor().scl(maxSpeed);
        this.acceleration = new Vector2();
    }

    public void update(Array<Shark> sharks, Fish fish, float delta) {
        // Apply boids behaviors.
        Vector2 sep = separate(sharks);
        Vector2 ali = align(sharks);
        Vector2 coh = cohesion(sharks);
        Vector2 pursuit = pursue(fish);  // New pursuit force toward the fish.

        // Scale forces by their weights.
        sep.scl(separationWeight);
        ali.scl(alignmentWeight);
        coh.scl(cohesionWeight);
        pursuit.scl(pursuitWeight);

        // Sum all forces.
        acceleration.add(sep);
        acceleration.add(ali);
        acceleration.add(coh);
        acceleration.add(pursuit);

        // Update velocity and limit it.
        velocity.add(acceleration.cpy().scl(delta));
        if (velocity.len() > maxSpeed) {
            velocity.nor().scl(maxSpeed);
        }
        position.add(velocity.cpy().scl(delta));

        // Reset acceleration.
        acceleration.set(0, 0);

        // Wrap around the screen edges.
        if (position.x < 0) position.x = Gdx.graphics.getWidth();
        if (position.x > Gdx.graphics.getWidth()) position.x = 0;
        if (position.y < 0) position.y = Gdx.graphics.getHeight();
        if (position.y > Gdx.graphics.getHeight()) position.y = 0;
    }

    // Separation: steer to avoid crowding neighbors.
    private Vector2 separate(Array<Shark> sharks) {
        Vector2 steer = new Vector2();
        int count = 0;
        for (Shark other : sharks) {
            if (other == this) continue;
            float d = position.dst(other.position);
            if (d > 0 && d < desiredSeparation) {
                Vector2 diff = new Vector2(position).sub(other.position);
                diff.nor();
                diff.scl(1f / d);  // Weight by distance (explicit float division).
                steer.add(diff);
                count++;
            }
        }
        if (count > 0) {
            steer.scl(1.1f / count);
        }
        if (steer.len() > 0) {
            // Steering = desired velocity minus current velocity.
            steer.nor().scl(maxSpeed);
            steer.sub(velocity);
            if (steer.len() > maxForce) {
                steer.nor().scl(maxForce);
            }
        }
        return steer;
    }

    // Alignment: steer towards the average heading of local neighbors.
    private Vector2 align(Array<Shark> sharks) {
        Vector2 sum = new Vector2();
        int count = 0;
        for (Shark other : sharks) {
            if (other == this) continue;
            float d = position.dst(other.position);
            if (d > 0 && d < neighborDist) {
                sum.add(other.velocity);
                count++;
            }
        }
        if (count > 0) {
            sum.scl(1.0f / count);
            sum.nor().scl(maxSpeed);
            Vector2 steer = new Vector2(sum).sub(velocity);
            if (steer.len() > maxForce) {
                steer.nor().scl(maxForce);
            }
            return steer;
        }
        return new Vector2(0, 0);
    }

    // Cohesion: steer to move toward the average position of local neighbors.
    private Vector2 cohesion(Array<Shark> sharks) {
        Vector2 sum = new Vector2();
        int count = 0;
        for (Shark other : sharks) {
            if (other == this) continue;
            float d = position.dst(other.position);
            if (d > 0 && d < neighborDist) {
                sum.add(other.position);
                count++;
            }
        }
        if (count > 0) {
            sum.scl(1.0f / count);
            return seek(sum);
        }
        return new Vector2(0, 0);
    }

    // New method: Pursue the fish by seeking its position.
    private Vector2 pursue(Fish fish) {
        return seek(fish.position);
    }

    // A helper function that calculates a steering vector towards a target.
    private Vector2 seek(Vector2 target) {
        Vector2 desired = new Vector2(target).sub(position);
        desired.nor().scl(maxSpeed);
        Vector2 steer = new Vector2(desired).sub(velocity);
        if (steer.len() > maxForce) {
            steer.nor().scl(maxForce);
        }
        return steer;
    }

    public void render(SpriteBatch batch) {
        // Optionally rotate the shark texture based on its velocity direction.
        float angle = velocity.angleDeg();
        batch.draw(texture, position.x, position.y,
            texture.getWidth() / 2, texture.getHeight() / 2,
            texture.getWidth(), texture.getHeight(),
            1, 1, angle, 0, 0,
            texture.getWidth(), texture.getHeight(), false, false);
    }
}
