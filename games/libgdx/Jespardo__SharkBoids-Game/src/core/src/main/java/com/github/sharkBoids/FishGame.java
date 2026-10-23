package com.github.sharkBoids;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;
import com.github.sharkBoids.fish.Fish;
import com.github.sharkBoids.shark.Shark;

public class FishGame extends ApplicationAdapter {
    SpriteBatch batch;
    Texture fishTexture;
    Texture sharkTexture;
    Fish fish;
    Array<Shark> sharks;

    BitmapFont font;
    float timeSurvived = 0f;
    // Spawn 2 sharks every 10 seconds.
    float nextSpawnTime = 10f;

    boolean gameOver = false;

    @Override
    public void create () {
        Gdx.gl.glClearColor(0.3f, 0.4f, 0.7f, 1f);
        batch = new SpriteBatch();
        font = new BitmapFont(); // Default font.

        // Replace these with your own texture file paths.
        fishTexture = new Texture(Gdx.files.internal("fish.png"));
        sharkTexture = new Texture(Gdx.files.internal("shark_flipped.png"));

        // Spawn the fish on the left side (e.g., 50 pixels from the left) and vertically centered.
        fish = new Fish(fishTexture, new Vector2(50, Gdx.graphics.getHeight() / 2));
        sharks = new Array<Shark>();
        // Initially spawn 4 sharks on the right side.
        for (int i = 0; i < 4; i++) {
            float sharkX = (float)(Math.random() * (Gdx.graphics.getWidth() * 0.2)) + (Gdx.graphics.getWidth() * 0.8f);
            float sharkY = (float)Math.random() * Gdx.graphics.getHeight();
            sharks.add(new Shark(sharkTexture, new Vector2(sharkX, sharkY)));
        }
    }

    @Override
    public void render () {
        float delta = Gdx.graphics.getDeltaTime();
        Gdx.gl.glClearColor(0.3f, 0.4f, 0.8f, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        if (!gameOver) {
            // Update timer.
            timeSurvived += delta;

            // Update the fish.
            fish.update(delta);

            // Update sharks and check for collisions.
            for (int i = 0; i < sharks.size; i++) {
                Shark shark = sharks.get(i);
                shark.update(sharks, fish, delta);
                if (checkCollision(shark, fish)) {
                    gameOver = true;
                    System.out.println("Game Over! The fish was eaten!");
                }
            }

            // Every 10 seconds, spawn 2 additional sharks.
            if (timeSurvived >= nextSpawnTime) {
                int sharksToAdd = 2;
                for (int i = 0; i < sharksToAdd; i++) {
                    float sharkX = (float)(Math.random() * (Gdx.graphics.getWidth() * 0.2)) + (Gdx.graphics.getWidth() * 0.8f);
                    float sharkY = (float)Math.random() * Gdx.graphics.getHeight();
                    sharks.add(new Shark(sharkTexture, new Vector2(sharkX, sharkY)));
                }
                nextSpawnTime += 10f;
            }
        }

        // Render all objects and UI.
        batch.begin();
        fish.render(batch);
        for (int i = 0; i < sharks.size; i++) {
            Shark shark = sharks.get(i);
            shark.render(batch);
        }
        // Draw the survival timer in the top left corner.
        font.draw(batch, "Time: " + String.format("%.1f", timeSurvived), 10, Gdx.graphics.getHeight() - 10);
        // Optionally, display the number of sharks.
        font.draw(batch, "Sharks: " + sharks.size, 10, Gdx.graphics.getHeight() - 30);
        batch.end();
    }

    @Override
    public void dispose () {
        batch.dispose();
        fishTexture.dispose();
        sharkTexture.dispose();
        font.dispose();
    }

    // Collision detection: check if the fish collides with the front of a shark.
    public boolean checkCollision(Shark shark, Fish fish) {
        float collisionDistance = 30f; // Adjust this threshold as needed.
        Vector2 toFish = new Vector2(fish.position).sub(shark.position);
        if (toFish.len() < collisionDistance) {
            // Determine if the fish is in front of the shark.
            Vector2 sharkDir = new Vector2(shark.velocity).nor();
            if (toFish.dot(sharkDir) > 0) {  // dot product > 0 indicates "in front"
                return true;
            }
        }
        return false;
    }
}
