package com.github.sharkBoids.fish;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.Vector2;

public class Fish {
    public Texture texture;
    public Animation<TextureRegion> animation;
    public float stateTime = 0f;
    public Vector2 position;
    public Vector2 velocity;

    // Energy and speed parameters.
    public float energy = 0f;             // Current energy.
    public float maxEnergy = 100f;          // Maximum energy.
    public float energyGainRate = 50f;      // Energy gained per second while moving.
    public float energyDecayRate = 30f;     // Energy lost per second when not moving.
    public float baseSpeed = 100f;          // Base speed when energy is zero.
    public float energySpeedFactor = 1.0f;  // Additional speed factor when energy is full.

    // Rotation for the fish. The fish texture is drawn pointing left by default.
    // rotation = 0 means the fish faces left.
    public float rotation = 0f;

    public TextureRegion currentFrame;

    public Fish(Texture texture, Vector2 position) {
        this.texture = texture;
        this.position = position;
        this.velocity = new Vector2();

        // Split the texture into 9 frames. Assumes 1 row.
        TextureRegion[][] tmp = TextureRegion.split(texture, texture.getWidth() / 9, texture.getHeight());
        TextureRegion[] fishFrames = new TextureRegion[9];
        for (int i = 0; i < 9; i++) {
            fishFrames[i] = tmp[0][i];
        }
        // Create the animation with a frame duration of 0.1 seconds.
        animation = new Animation<TextureRegion>(0.1f, fishFrames);
        animation.setPlayMode(Animation.PlayMode.LOOP);
    }

    public void update(float delta) {
        stateTime += delta;

        // Determine input direction.
        float inputX = 0;
        float inputY = 0;
        boolean moving = false;

        if (Gdx.input.isKeyPressed(Input.Keys.LEFT) || Gdx.input.isKeyPressed(Input.Keys.A)) {
            inputX = -1;
            moving = true;
        }
        if (Gdx.input.isKeyPressed(Input.Keys.RIGHT) || Gdx.input.isKeyPressed(Input.Keys.D)) {
            inputX = 1;
            moving = true;
        }
        if (Gdx.input.isKeyPressed(Input.Keys.UP) || Gdx.input.isKeyPressed(Input.Keys.W)) {
            inputY = 1;
            moving = true;
        }
        if (Gdx.input.isKeyPressed(Input.Keys.DOWN) || Gdx.input.isKeyPressed(Input.Keys.S)) {
            inputY = -1;
            moving = true;
        }

        Vector2 inputDir = new Vector2(inputX, inputY);
        if (inputDir.len() > 0) {
            inputDir.nor();
        }

        // Adjust energy: gain energy when moving, decay when not.
        if (moving) {
            energy = Math.min(maxEnergy, energy + energyGainRate * delta);
        } else {
            energy = Math.max(0, energy - energyDecayRate * delta);
        }

        // Determine the current speed based on energy.
        float currentSpeed = baseSpeed + (energy / maxEnergy) * baseSpeed * energySpeedFactor;

        // Compute the desired velocity.
        Vector2 desiredVelocity = new Vector2();
        if (inputDir.len() > 0) {
            desiredVelocity.set(inputDir).scl(currentSpeed);
        } else {
            desiredVelocity.set(0, 0);
        }

        // Smoothly interpolate current velocity toward the desired velocity.
        float lerpFactor = 0.1f;  // Adjust for responsiveness.
        velocity.lerp(desiredVelocity, lerpFactor);

        // Update position.
        position.add(velocity.cpy().scl(delta));

        // Smoothly update rotation based on velocity.
        // Only update if there is a significant movement.
        if (velocity.len() > 0.1f) {
            // Compute desired rotation:
            // The texture is drawn facing left (0° rotation). We want to rotate
            // the fish so that it points in the direction of movement.
            // LibGDX's angleDeg() returns the angle in degrees with 0° pointing right.
            // So, desiredRotation = velocity.angleDeg() - 180 will yield:
            //   - 0° (when velocity points left),
            //   - -90° when moving upward,
            //   - 90° when moving downward,
            //   - 180° (or -180°) when moving right.
            float desiredRotation = velocity.angleDeg() - 180;
            // Compute the shortest angle difference, handling wrap-around.
            float angleDiff = desiredRotation - rotation;
            if (angleDiff > 180) angleDiff -= 360;
            if (angleDiff < -180) angleDiff += 360;
            // Smoothly adjust rotation.
            float rotationLerpFactor = 0.1f; // Adjust smoothing factor as needed.
            rotation += angleDiff * rotationLerpFactor;
        }

        // Keep the fish within the screen bounds.
        float fishWidth = texture.getWidth() / 9;  // If using a sprite sheet.
        float fishHeight = texture.getHeight();
        if (position.x < 0) position.x = 0;
        if (position.x > Gdx.graphics.getWidth() - fishWidth)
            position.x = Gdx.graphics.getWidth() - fishWidth;
        if (position.y < 0) position.y = 0;
        if (position.y > Gdx.graphics.getHeight() - fishHeight)
            position.y = Gdx.graphics.getHeight() - fishHeight;
    }

    public void render(SpriteBatch batch) {
        // Get the current frame from the animation.
        currentFrame = animation.getKeyFrame(stateTime, true);

        // Determine fish dimensions.
        float fishWidth = texture.getWidth() / 9;
        float fishHeight = texture.getHeight();

        // Draw the fish with rotation.
        // The origin is set to the center of the fish.
        batch.draw(currentFrame,
            position.x, position.y,
            fishWidth / 2, fishHeight / 2,
            fishWidth, fishHeight,
            1, 1,
            rotation);
    }
}
