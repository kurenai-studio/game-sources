package com.dev.cariri.hitball.objects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.dev.cariri.hitball.Globals;

/**
 * Created by Ronildo on 27/02/2018.
 */

public class Quadro {

    private float x, y = 0;

    private float scaleX, scaleY;
    private Color color;
    private Rectangle srcRect;

    private Texture textSquare;

    int valor;

    public Quadro() {
        textSquare = Globals.SQUARE_RELEASE;

        scaleX = 1f;
        scaleY = 1f;

        color = new Color(1f, 0f, 1f, 0f);

        srcRect = new Rectangle(x, y, Globals.TILE_SIZE, Globals.TILE_SIZE);
    }


    public Color getColor() { return color; }
    public Vector2 getPosition() { return new Vector2(x, y); }
    public int getValor() {return valor; }


    public void setXY(float x, float y){
        this.x = x;
        this.y = y;
    }

    public void setScale(float x, float y){
        scaleX = x;
        scaleY = y;
    }


    public void setColor(Color c) {
        color = c;
    }

    public Rectangle getBounds() {

        return new Rectangle(x, y, srcRect.width, srcRect.height);
    }

    public boolean contains(float cx, float cy) {
        //Pulo do gato no touch
        if(new Vector2(x, y).add(srcRect.width/2,srcRect.height/2).sub(cx, cy).len() < srcRect.width)
            return true;
        return false;
    }


    public void draw(SpriteBatch spriteBatch) {
        Color batchColor = spriteBatch.getColor();

        spriteBatch.setColor(batchColor);
        spriteBatch.draw(textSquare,
                x, y,
                srcRect.width,
                srcRect.height,
                srcRect.width,
                srcRect.height,
                scaleX, scaleY,
                0,
                (int)srcRect.x, (int)srcRect.y,
                (int)srcRect.width, (int)srcRect.height,
                false, false);

        spriteBatch.setColor(batchColor);
    }
}
