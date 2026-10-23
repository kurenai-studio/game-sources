package com.mygdx.fourcats.renderers;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.mygdx.fourcats.managers.Spatial2DData;

public class CorpseRenderer
{
    Texture CorpseTexture;
    Texture BonesTexture;
    int CORPSESIZE = 35;

    private final SpriteBatch spriteBatch;

    public CorpseRenderer(SpriteBatch batch)
    {
        spriteBatch = batch;
    }

    public void loadTextures()
    {
        CorpseTexture = new Texture(Gdx.files.internal("DeadMouse.PNG"));
        BonesTexture = new Texture(Gdx.files.internal("MouseBones.PNG"));
    }

    public void drawCorpses(Spatial2DData data, int firstUndecayedIndex)
    {
        for (int index = 0; index < Math.min(data.size(), firstUndecayedIndex); index++)
        {
            spriteBatch.draw(BonesTexture, data.getXByIndex(index), data.getYByIndex(index), CORPSESIZE, CORPSESIZE);
        }

        if (firstUndecayedIndex < data.size())
        {
            for (int index = firstUndecayedIndex; index < data.size(); index++)
            {
                spriteBatch.draw(CorpseTexture, data.getXByIndex(index), data.getYByIndex(index), CORPSESIZE, CORPSESIZE);
            }
        }

    }
}
