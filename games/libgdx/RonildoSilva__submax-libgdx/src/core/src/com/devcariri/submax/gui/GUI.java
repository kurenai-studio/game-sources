package com.devcariri.submax.gui;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.devcariri.submax.Assets;
import com.devcariri.submax.InputHandler;

/**
 * Created by RoNigga on 31/01/2017.
 */

public abstract class GUI {

    protected Rectangle rectangle;
    protected Object returnValue;
    public boolean canBeRemoved = false;
    public boolean isPressed = false;

    public GUI(){
        this.rectangle = new Rectangle(0,0,0,0);
    }

    public abstract void update(InputHandler input);
    public abstract void render(SpriteBatch batch);
    public abstract boolean isComplete();
    public Object getValue() { return returnValue; }

    public static void drawOutlineRect(SpriteBatch b, Rectangle r, Color outer, Color inner) {
        drawRect(b, r, outer);
        if(inner == Color.CLEAR) return;
        drawRect(b, new Rectangle(r.x + 2, r.y + 2, r.width - 4, r.height - 4), inner);
    }
    public static void drawGUIRect(SpriteBatch b, Rectangle r) {
        drawRect(b, new Rectangle(r.x - 6, r.y - 6, r.width + 12, r.height + 12), Color.BLACK);
        drawRect(b, new Rectangle(r.x - 4, r.y - 4, r.width + 8, r.height + 8), Color.WHITE);
        drawRect(b, new Rectangle(r.x - 2, r.y - 2, r.width + 4, r.height + 4), Color.BLACK);
        drawRect(b, r, Color.WHITE);
    }

    public static void drawButton(SpriteBatch batch, BitmapFont f, Rectangle r, String text)
    {
        Assets.drawCenteredString(batch, f, text,
                new Vector2(r.x + r.width*0.5f, r.y+r.height*0.5f),
                0.55f, false);
    }

    public static void drawRect(SpriteBatch batch, Rectangle r, Color c) {
        Color pc = batch.getColor();
        batch.setColor(c);
        batch.draw(Assets.BACKGROUND, r.x, r.y,
                r.width, r.height);
        batch.setColor(pc);
    }

    public static void drawPoint(SpriteBatch batch, Vector2 pnt, Color c) {
        Color bc = batch.getColor();
        batch.setColor(c);
        batch.draw(Assets.BACKGROUND,
                pnt.x-1, pnt.y-1,
                2, 2);
        batch.setColor(bc);
    }
}
