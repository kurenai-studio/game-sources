package com.devcariri.submax.objects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFontCache;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Align;
import com.devcariri.submax.Assets;
import com.devcariri.submax.Globals;
import com.devcariri.submax.Timer;

import java.util.Random;

/**
 * Created by RoNigga on 31/01/2017.
 */

public class Quadro {

    public boolean isSelected;
    private float x, y;

    private float scaleX, scaleY;
    private Color color;
    private Rectangle srcRect;

    private Texture textSquare;

    int valor;
    private Random random;


    public Quadro() {

        random = new Random();

        scaleX = 1f;
        scaleY = 1f;

        color = new Color(1f, 1f, 1f, 0f);

        srcRect = new Rectangle(0, 0, Globals.TILE_SIZE, Globals.TILE_SIZE);
        isSelected = false;

        valor = random.nextInt()%100;

        textSquare = Assets.SQUARE_RELEASE;

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

        String zero = "";
        if(Math.abs(this.getValor()) >= 0 &&
                Math.abs(this.getValor()) <= 9)
            zero = "0";

        int multip;

        String signal = "";
        if(this.getValor() < 0){
            new Color();
            Assets.GGFont.setColor(Color.RED.cpy());
            multip = -1;
            //signal = "-";
        }
        else{
            new Color();
            Assets.GGFont.setColor(Color.BLUE.cpy());
            multip = 1;
            //signal = "+";
        }

        //Calcular posicao do texto dentro do quadro
        Assets.GGFont.draw(spriteBatch,
                String.valueOf(signal+zero+this.getValor()*multip),
                this.getPosition().x + 17,
                this.getPosition().y + 38);

    }

    public void changeTexture() {
        textSquare = Assets.SQUARE_PRESSED;
    }

    public void recoverTexture() {
        textSquare = Assets.SQUARE_RELEASE;
    }
}
