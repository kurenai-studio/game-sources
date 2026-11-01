package com.micro1.leap;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

/**
 * Root game. Owns the shared SpriteBatch, ShapeRenderer and default BitmapFont
 * (created once, disposed once) and starts on the title screen. The screens
 * borrow these shared resources rather than allocating their own.
 */
public class LeapGame extends Game {

    public SpriteBatch batch;
    public ShapeRenderer shapes;
    public BitmapFont font;

    @Override
    public void create() {
        batch = new SpriteBatch();
        shapes = new ShapeRenderer();
        font = new BitmapFont();                 // LibGDX built-in font, no font file shipped
        font.setUseIntegerPositions(false);      // smooth positioning when scaled
        setScreen(new TitleScreen(this));
    }

    @Override
    public void dispose() {
        if (getScreen() != null) {
            getScreen().dispose();
        }
        batch.dispose();
        shapes.dispose();
        font.dispose();
    }
}
