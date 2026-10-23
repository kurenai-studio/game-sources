package com.jgarivera.blitzbit.screens;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.ScreenAdapter;

public abstract class AbstractScreen extends ScreenAdapter {
    protected final Game game;

    public AbstractScreen(Game game) {
        this.game = game;
    }
}
