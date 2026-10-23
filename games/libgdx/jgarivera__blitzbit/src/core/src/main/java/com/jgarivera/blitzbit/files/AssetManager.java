package com.jgarivera.blitzbit.files;


import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;

public class AssetManager extends com.badlogic.gdx.assets.AssetManager {

    public void load() {
        loadTextures();
    }

    private void loadTextures() {
        load("pack.atlas", TextureAtlas.class);
        load("player.png", Texture.class);
        load("minion.png", Texture.class);
        load("flag.png", Texture.class);
    }
}
