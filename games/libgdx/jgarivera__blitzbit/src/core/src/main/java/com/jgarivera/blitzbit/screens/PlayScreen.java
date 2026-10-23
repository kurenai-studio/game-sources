package com.jgarivera.blitzbit.screens;

import com.badlogic.ashley.core.Engine;
import com.badlogic.gdx.Game;
import com.badlogic.gdx.utils.ScreenUtils;
import com.jgarivera.blitzbit.files.AssetManager;
import com.jgarivera.blitzbit.graphics.Camera;
import com.jgarivera.blitzbit.input.ToggleManager;
import com.jgarivera.blitzbit.world.World;
import com.jgarivera.blitzbit.world.physics.Physics;

public class PlayScreen extends AbstractScreen {

    private final World world;

    public PlayScreen(Game game, AssetManager assetManager) {
        super(game);
        world = new World(new Engine(), new Physics(), new Camera(), new ToggleManager(), assetManager);
    }

    @Override
    public void show() {
        world.show();
    }

    @Override
    public void render(float delta) {
        ScreenUtils.clear(0, 0, 0, 1);
        world.render(delta);
        world.update(delta);
        world.renderOverlay(delta);
    }

    @Override
    public void resize(int width, int height) {
        world.resize(width, height);
    }

    @Override
    public void dispose() {
        world.dispose();
    }
}
