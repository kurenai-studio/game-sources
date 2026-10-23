package com.jgarivera.blitzbit.screens;

import com.badlogic.gdx.Game;
import com.jgarivera.blitzbit.files.AssetManager;

public class MainMenuScreen extends AbstractScreen {
    private final AssetManager assetManager;

    public MainMenuScreen(Game game) {
        super(game);
        assetManager = new AssetManager();
        assetManager.load();
    }

    @Override
    public void render(float delta) {
        if (assetManager.update()) {
            game.setScreen(new PlayScreen(game, assetManager));
        }
    }

    @Override
    public void dispose() {
        assetManager.dispose();
    }
}
