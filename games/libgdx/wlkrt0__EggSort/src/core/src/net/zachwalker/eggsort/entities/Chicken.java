package net.zachwalker.eggsort.entities;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.TimeUtils;
import net.zachwalker.eggsort.util.Assets;
import net.zachwalker.eggsort.util.DrawingHelpers;
import net.zachwalker.eggsort.util.Enums;

public class Chicken {

    private Vector2 position;
    private long createdTime;
    private Enums.ChickenColor chickenColor;

    public Chicken(Vector2 position, Enums.ChickenColor chickenColor) {
        this.position = new Vector2(position);
        this.chickenColor = chickenColor;
        createdTime = TimeUtils.nanoTime();
    }

    public void render(SpriteBatch batch) {
        float elapsedTime = DrawingHelpers.secondsSince(createdTime);
        switch (chickenColor) {
            case WHITE:
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.chickenWhite.getKeyFrame(elapsedTime, true), position);
                break;
            case BROWN:
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.chickenBrown.getKeyFrame(elapsedTime, true), position);
                break;
        }
    }

}
