package com.github.br.libgdx.jam38.game.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.utils.viewport.Viewport;
import com.github.br.libgdx.jam38.structure.ui.ActorFactory;
import com.github.br.libgdx.jam38.structure.ui.CustomOrthogonalTiledMapRenderer;
import com.github.br.libgdx.jam38.structure.screen.AbstractTiledMapUiScreen;

public class GameScreen extends AbstractTiledMapUiScreen {

    public GameScreen(String tiledMapPath, String pathToSkin, boolean isGlProfileActive) {
        super(tiledMapPath, pathToSkin, isGlProfileActive);
    }

    @Override
    protected void afterShow(
        TiledMap tiledMap,
        CustomOrthogonalTiledMapRenderer renderer,
        Viewport viewport,
        ActorFactory actorFactory
    ) {
        Gdx.input.setInputProcessor(renderer.getInputProcessor());
    }

    @Override
    protected void update(float delta) {

    }

}
