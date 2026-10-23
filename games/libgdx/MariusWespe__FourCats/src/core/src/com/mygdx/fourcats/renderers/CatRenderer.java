package com.mygdx.fourcats.renderers;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.mygdx.fourcats.CatName;

public class CatRenderer
{
    private Texture CatTexture;

    private int sourceSizeX;

    private int sourceSizeY;
    private final SpriteBatch spriteBatch;

    public CatRenderer(SpriteBatch batch, CatName name)
    {
        spriteBatch = batch;
        loadTextures(name);
    }

    public void loadTextures(CatName name)
    {
        switch (name)
        {
            case MERLIN:
                CatTexture = new Texture(Gdx.files.internal("Merlin.PNG"));
                break;
            case ARCHIE:
                CatTexture = new Texture(Gdx.files.internal("Archie.PNG"));
                break;
            case CICCIO:
                CatTexture = new Texture(Gdx.files.internal("Ciccio.PNG"));
                break;
            case LENNY:
                CatTexture = new Texture(Gdx.files.internal("LENNY.PNG"));
                break;
        }

        sourceSizeX = CatTexture.getWidth();
        sourceSizeY = CatTexture.getHeight();
    }

    public void renderCat(int posX,  int posY,  int size, boolean isLeftFacing)
    {
        if (isLeftFacing)
        {
            drawOriginal(posX, posY, size);
        }
        else
        {
            drawMirroredByXAxis(posX, posY, size);
        }
    }

    private void drawOriginal(int posX, int posY, int size)
    {
        spriteBatch.draw(CatTexture, posX, posY, size, size, 0, 0, sourceSizeX, sourceSizeY, false, false);
    }

    private void drawMirroredByXAxis(int posX, int posY, int size)
    {
        spriteBatch.draw(CatTexture, posX, posY, size, size, 0, 0, sourceSizeX, sourceSizeY, true, false);
    }
}
