package ru.samsung.gamestudio.characters;

import static ru.samsung.gamestudio.MyGdxGame.SCR_HEIGHT;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;

public class Bird {

    int x;
    float y;
    int width, height;

    float velocity;
    final float gravity = 0.7f;
    final float jumpVelocity = 13f;

    int frameCounter;
    TextureRegion[] framesArray;

    boolean isDead;
    float deathRotation;

    public Bird(int x, int y, int speed, int width, int height) {
        this.x = x;
        this.y = y;
        this.velocity = 0;
        this.width = width;
        this.height = height;
        frameCounter = 0;
        isDead = false;
        deathRotation = 0;

        framesArray = new TextureRegion[]{
                new TextureRegion(new Texture("birdTiles/bird0.png")),
                new TextureRegion(new Texture("birdTiles/bird1.png")),
                new TextureRegion(new Texture("birdTiles/bird2.png")),
                new TextureRegion(new Texture("birdTiles/bird1.png")),
        };
    }

    public void reset(int startY) {
        this.y = startY;
        this.velocity = 0;
        this.frameCounter = 0;
        this.isDead = false;
        this.deathRotation = 0;
    }

    public void setDead(boolean dead) {
        this.isDead = dead;
    }

    public void onClick() {
        velocity = jumpVelocity;
    }

    public void fly() {
        velocity -= gravity;
        y += velocity;
    }

    public boolean isInField() {
        if (y + height < 0) return false;
        if (y > SCR_HEIGHT) return false;
        return true;
    }

    public void draw(Batch batch) {
        int frameMultiplier = 10;
        if (isDead) {
            if (deathRotation > -90f) deathRotation -= 4f;
            batch.draw(framesArray[0], x, y, width / 2f, height / 2f, width, height, 1f, 1f, deathRotation);
        } else {
            batch.draw(framesArray[frameCounter / frameMultiplier], x, y, width / 2f, height / 2f, width, height, 1f, 1f, 0f);
            if (frameCounter++ == framesArray.length * frameMultiplier - 1) frameCounter = 0;
        }
    }

    public void dispose() {
        for (TextureRegion region : framesArray) {
            region.getTexture().dispose();
        }
    }

}
