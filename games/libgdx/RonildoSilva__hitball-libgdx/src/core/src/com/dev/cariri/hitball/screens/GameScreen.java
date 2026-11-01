package com.dev.cariri.hitball.screens;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;

/**
 * Created by Ronildo on 27/02/2018.
 */

public abstract class GameScreen {

    /** Classe Screen **/
    //protected GUI currentGUI;

    protected boolean isComplete = false;
    public boolean requiresInput = false;

    public abstract void init();
    public abstract void update(boolean topMost);
    public abstract void render(SpriteBatch spriteBatch);
    //public abstract void update(InputHandler input, boolean topMost);
    //public abstract void render(SpriteBatch b, InputHandler input);
    public abstract void transitionIn();
    public abstract void transitionOut();
    public abstract void dispose();

    //public boolean hasGUI() { return currentGUI != null; }
    //public void setGUI(GUI g) { currentGUI = g; }

    public boolean isComplete() { return isComplete; }

    public int State;

    public static final int MENU_SCREEN = 0;
    public static final int GAME_SCREEN = 1;
}
