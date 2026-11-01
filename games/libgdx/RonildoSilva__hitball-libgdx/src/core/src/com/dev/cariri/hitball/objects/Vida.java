package com.dev.cariri.hitball.objects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.dev.cariri.hitball.Globals;

/**
 * Created by Ronildo on 27/02/2018.
 */

public class Vida {

    private float x, y = 0;

    private float scaleX, scaleY;
    private Color color;
    private Rectangle rectangle;
    private Texture texture;

    public Vida() {
        texture = Globals.LIFE_TEXTURE;

        scaleX = 1f;
        scaleY = 1f;

        color = new Color(1f, 0f, 1f, 0f);

        rectangle = new Rectangle(x, y, Globals.HEART_SIZE, Globals.HEART_SIZE);
    }

    public void setXY(float x, float y){
        this.x = x;
        this.y = y;
    }

    public void draw(SpriteBatch spriteBatch) {
        spriteBatch.draw(texture,
                x, y,
                rectangle.width,
                rectangle.height,
                rectangle.width,
                rectangle.height,
                scaleX, scaleY,
                0,
                (int)rectangle.x, (int)rectangle.y,
                (int)rectangle.width, (int)rectangle.height,
                false, false);
    }
}
