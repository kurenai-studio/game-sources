package com.github.br.libgdx.jam38.game.screens;

import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.github.br.libgdx.jam38.game.Resources;
import com.github.br.libgdx.jam38.structure.screen.loading.AssetsLoader;

public class GraphGameAssetLoader implements AssetsLoader {

    @Override
    public void loadAssets(AssetManager assetManager) {
        assetManager.load(Resources.GRAPH_GAME_ATLAS, TextureAtlas.class);
        assetManager.load(Resources.GraphGame.BACKGROUND, Texture.class);
    }

    @Override
    public void unloadAssets(AssetManager assetManager) {
        assetManager.unload(Resources.GRAPH_GAME_ATLAS);
        assetManager.unload(Resources.GraphGame.BACKGROUND);
    }

}
