package net.zachwalker.ballsort.entities;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import net.zachwalker.ballsort.util.Constants;

public class Bucket {

    private float positionX;
    private int caughtBalls;
    private int caughtBallsGoal;
    private Color color;

    public Bucket(float x, Color color, int caughtBallsGoal) {
        positionX = x;
        this.color = color;
        this.caughtBallsGoal = caughtBallsGoal;
    }

    //no update method on the Rectangle, since it isn't going anywhere

    public void render(ShapeRenderer renderer) {
        renderer.begin(ShapeRenderer.ShapeType.Filled);
        renderer.setColor(color);
        float heightPercent = (float) caughtBalls / caughtBallsGoal;
        renderer.rect(positionX, 0.0f, Constants.BUCKET_WIDTH, heightPercent * Constants.BUCKET_HEIGHT);
        renderer.end();
    }

    /** Increments this bucket's balls caught counter. Returns true if it's now full. */
    public boolean caughtBall() {
        caughtBalls += 1;
        if (caughtBalls == caughtBallsGoal) {
            return true;
        } else if (caughtBalls > caughtBallsGoal) {
            caughtBalls -= 1;
            return false;
        } else {
            return false;
        }
    }

    /** Decrements this bucket's balls caught. Returns true if it's empty (game over). */
    public boolean missedBall() {
        caughtBalls -= 1;
        return (caughtBalls <= 0);
    }

    public boolean isFull() {
        return (caughtBalls >= caughtBallsGoal);
    }

    public void reset(int caughtBallsGoal) {
        caughtBalls = 0;
        this.caughtBallsGoal = caughtBallsGoal;
    }

}
