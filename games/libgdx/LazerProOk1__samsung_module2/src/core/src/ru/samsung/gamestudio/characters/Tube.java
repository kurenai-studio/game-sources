package ru.samsung.gamestudio.characters;

import static ru.samsung.gamestudio.MyGdxGame.SCR_HEIGHT;
import static ru.samsung.gamestudio.MyGdxGame.SCR_WIDTH;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Batch;

import java.util.Random;

public class Tube {

    Texture textureUpperTube;
    Texture textureDownTube;

    Random random;

    int x, gapY;
    int distanceBetweenTubes;

    boolean isPointReceived;

    int speed = 10;
    final int width = 200;
    final int height = 700;
    int gapHeight = 400;
    int padding = 100;

    final Color tintColor = new Color();

    public Tube(int tubeCount, int tubeIdx) {
        random = new Random();

        gapY = gapHeight / 2 + padding + random.nextInt(SCR_HEIGHT - 2 * (padding + gapHeight / 2));
        distanceBetweenTubes = (SCR_WIDTH + width) / (tubeCount - 1);
        x = distanceBetweenTubes * tubeIdx + SCR_WIDTH;

        textureUpperTube = new Texture("tubes/tube_flipped.png");
        textureDownTube = new Texture("tubes/tube.png");

        isPointReceived = false;
    }

    public void draw(Batch batch) {
        float t = Math.min(1f, (speed - 10f) / 18f);
        tintColor.set(1f, 1f - t * 0.8f, 1f - t * 0.8f, 1f);
        batch.setColor(tintColor);
        batch.draw(textureUpperTube, x, gapY + gapHeight / 2, width, height);
        batch.draw(textureDownTube, x, gapY - gapHeight / 2 - height, width, height);
        batch.setColor(1f, 1f, 1f, 1f);
    }

    public void move() {
        x -= speed;
        if (x < -width) {
            isPointReceived = false;
            x = SCR_WIDTH + distanceBetweenTubes;
            gapY = gapHeight / 2 + padding + random.nextInt(SCR_HEIGHT - 2 * (padding + gapHeight / 2));
        }
    }

    public boolean isHit(Bird bird) {
        if (bird.y <= gapY - gapHeight / 2 && bird.x + bird.width >= x && bird.x <= x + width)
            return true;
        if (bird.y + bird.height >= gapY + gapHeight / 2 && bird.x + bird.width >= x && bird.x <= x + width)
            return true;
        return false;
    }

    public boolean needAddPoint(Bird bird) {
        return !isPointReceived && bird.x > x + width;
    }

    public void setPointReceived() {
        isPointReceived = true;
    }

    public void setSpeed(int speed) {
        this.speed = speed;
    }

    public int getSpeed() {
        return speed;
    }

    public void dispose() {
        textureDownTube.dispose();
        textureUpperTube.dispose();
    }
}
