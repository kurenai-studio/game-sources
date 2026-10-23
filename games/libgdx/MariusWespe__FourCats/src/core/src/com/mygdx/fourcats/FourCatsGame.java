package com.mygdx.fourcats;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

public class FourCatsGame extends Game {

    public BitmapFont bigfont, regularfont, smallfont;

    public SpriteBatch batch;

    public ShapeRenderer shape;

    @Override
    public void create()
    {
        Gdx.gl.glClearColor(0,0,0,1);
        bigfont = new BitmapFont();
        bigfont.getData().setScale(2);
        regularfont = new BitmapFont();
        smallfont = new BitmapFont();
        smallfont.getData().setScale(0.5f);
        batch = new SpriteBatch();
        shape = new ShapeRenderer();
        this.setScreen(new MenuScreen(this));
    }

    public void render()
    {
        super.render();
    }
    @Override
    public void dispose()
    {
        batch.dispose();
        bigfont.dispose();
    }
}
