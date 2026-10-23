package com.mygdx.fourcats;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.Disposable;

import java.util.ArrayList;

public class CatSelection implements Disposable

{
    private final int spriteSize;
    private final int paddingToLeft;
    private final int distBetweenSelectors;
    private int selectedIndex = 0;
    private final int xOffset, yOffSet;

    private final ShapeRenderer shape;
    private final ArrayList<CatName> names;
    private final ArrayList<Sprite> sprites;

    private final ArrayList<Texture> textures;

    public CatSelection(ShapeRenderer shape, int xWorldSize, int yDistFromCenter) {
        this.shape = shape;
        names = new ArrayList<>();
        sprites = new ArrayList<>();
        textures = new ArrayList<>();

        xOffset = - xWorldSize / 2;
        yOffSet = yDistFromCenter;
        spriteSize = Math.round(xWorldSize * 0.2f);
        paddingToLeft = spriteSize / 8;
        distBetweenSelectors = spriteSize / 4;

    }

    public  CatName getSelectedCat()
    {
        return names.get(selectedIndex);
    }

    public void addCat(CatName name, String path)
    {
        names.add(name);
        Texture newTexture = new Texture(Gdx.files.internal(path));
        textures.add(newTexture);
        Sprite newSprite = new Sprite(newTexture);
        newSprite.setSize(spriteSize, spriteSize);
        sprites.add(newSprite);
    }

    @Override
    public void dispose()
    {
        for (Texture texture : textures) {
            texture.dispose();
        }
    }

    public void setPositions()
    {
        for (int i = 0; i < sprites.size(); i++)
        {
            sprites.get(i).setPosition(xOffset + paddingToLeft + i * (spriteSize + distBetweenSelectors), yOffSet);
        }
    }

    public void increaseSelectedIndex()
    {
        if (selectedIndex < sprites.size() - 1)
        {
            selectedIndex++;
        }
    }

    public void decreaseSelectedIndex()
    {
        if (selectedIndex > 0)
        {
            selectedIndex--;
        }
    }

    public void drawSelectionBox(ShapeRenderer shape)
    {
        for (int i = 0; i < sprites.size(); i++)
        {
            if (i == selectedIndex)
            {
                shape.rect(sprites.get(i).getX(), sprites.get(i).getY(), spriteSize, spriteSize);
            }
        }
    }


    public void draw(SpriteBatch batch)
    {
        for (Sprite sprite : sprites) {
            sprite.draw(batch);
        }
    }
}
