package net.zachwalker.eggsort.entities;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;

import net.zachwalker.eggsort.util.Assets;
import net.zachwalker.eggsort.util.Constants;
import net.zachwalker.eggsort.util.DrawingHelpers;
import net.zachwalker.eggsort.util.Enums;

public class Bucket {

    private Vector2 position;
    private int caughtEggs;
    private int caughtEggsGoal;
    private Enums.EggType eggType;
    private int numEggsToShow;
    private int bucketsFilled;
    private int bucketsToFill;

    public Bucket(Vector2 position, Enums.EggType eggType) {
        this.position = new Vector2(position);
        this.eggType = eggType;
    }

    public void render(SpriteBatch batch) {
        //note that the order in which these sprites are drawn is important (z-index)
        switch(eggType) {
            case WHITE:
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.bucketLeft.get(numEggsToShow), position);
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.bucketsToFill.get(bucketsToFill), Constants.BUCKETS_FILLED_LEFT_POSITION);
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.bucketsFilled.get(bucketsFilled), Constants.BUCKETS_FILLED_LEFT_POSITION);
                break;
            case BROWN:
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.bucketMiddle.get(numEggsToShow), position);
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.bucketsToFill.get(bucketsToFill), Constants.BUCKETS_FILLED_MIDDLE_POSITION);
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.bucketsFilled.get(bucketsFilled), Constants.BUCKETS_FILLED_MIDDLE_POSITION);
                break;
            case CHICK:
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.bucketRight.get(numEggsToShow), position);
                //same sprite as for Left/White and Middle/Brown but rotated 90deg
                DrawingHelpers.drawSpriteRotated(batch, Assets.singleton.images.bucketsToFill.get(bucketsToFill), Constants.BUCKETS_FILLED_RIGHT_POSITION);
                DrawingHelpers.drawSpriteRotated(batch, Assets.singleton.images.bucketsFilled.get(bucketsFilled), Constants.BUCKETS_FILLED_RIGHT_POSITION);
                break;
        }
    }

    /** Increments this bucket's eggs caught counter. */
    public void caughtEgg() {
        if (caughtEggs >= caughtEggsGoal - 1) {
            caughtEggs = caughtEggsGoal;
            updateTextures();
            Assets.singleton.sounds.playSound(Assets.singleton.sounds.full);
        } else {
            caughtEggs += 1;
            updateTextures();
        }
    }

    /** Decrements this bucket's eggs caught. Returns true if it's empty (game over). */
    public boolean missedBall() {
        if (caughtEggs == 0) {
            updateTextures();
            return true;
        } else {
            caughtEggs -= 1;
            updateTextures();
            return false;
        }
    }

    public boolean isFull() {
        return (caughtEggs >= caughtEggsGoal);
    }

    public void reset(int startingEggs, int caughtEggsGoal) {
        caughtEggs = startingEggs;
        this.caughtEggsGoal = caughtEggsGoal;
        updateTextures();
    }

    private void updateTextures() {
        if (caughtEggs == 0) {
            numEggsToShow = 0;
            bucketsFilled = 0;
        } else if (caughtEggs % 12 == 0) {
            numEggsToShow = 12;
            bucketsFilled = MathUtils.floor(((float) caughtEggs - 1) / 12.0f);
        } else {
            numEggsToShow = caughtEggs % 12;
            bucketsFilled = MathUtils.floor(((float) caughtEggs) / 12.0f);
        }
        bucketsToFill = MathUtils.floor((float) caughtEggsGoal / 12.0f) - 1;
    }
}
