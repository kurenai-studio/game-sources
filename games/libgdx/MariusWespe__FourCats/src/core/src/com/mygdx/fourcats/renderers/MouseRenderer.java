package com.mygdx.fourcats.renderers;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.mygdx.fourcats.managers.Spatial2DData;

import java.util.ArrayList;

public class MouseRenderer
{
    private final int MOUSESIZE = 35;
    Texture MouseTexture;

    SpriteBatch spriteBatch;

    private int sourceSizeX;

    private int sourceSizeY;

    public MouseRenderer(SpriteBatch batch)
    {
        spriteBatch = batch;
    }

    public void loadTextures()
    {
        MouseTexture = new Texture(Gdx.files.internal("Mouse.PNG"));
        sourceSizeX = MouseTexture.getWidth();
        sourceSizeY = MouseTexture.getHeight();
    }
    public void drawMice(Spatial2DData data, ArrayList<Boolean> isLeftFacing)
    {
        for (int index = 0; index < data.size(); index++)
        {
            if (isLeftFacing.get(index))
            {
                drawOriginal(data.getXByIndex(index),
                        data.getYByIndex(index),
                        MOUSESIZE);
            }
            else
            {
                drawMirroredByXAxis(data.getXByIndex(index),
                        data.getYByIndex(index),
                        MOUSESIZE);
            }
        }
    }

    private void drawOriginal(int posX, int posY, int size)
    {
        spriteBatch.draw(MouseTexture, posX, posY, size, size, 0, 0, sourceSizeX, sourceSizeY, false, false);
    }

    private void drawMirroredByXAxis(int posX, int posY, int size)
    {
        spriteBatch.draw(MouseTexture, posX, posY, size, size, 0, 0, sourceSizeX, sourceSizeY, true, false);
    }
}
