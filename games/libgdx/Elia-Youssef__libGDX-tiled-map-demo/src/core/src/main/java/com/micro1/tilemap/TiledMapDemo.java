package com.micro1.tilemap;

import com.badlogic.gdx.Game;

/**
 * Root libGDX Game. Hosts a single GameScreen that loads the Tiled map, renders it with a camera
 * that follows the player, and handles WASD movement + tile collision.
 */
public class TiledMapDemo extends Game {

    @Override
    public void create() {
        setScreen(new GameScreen());
    }

    @Override
    public void dispose() {
        // Game.dispose() only calls screen.hide(), so dispose the screen explicitly to release its
        // textures / batch / map / renderer on exit.
        super.dispose();
        if (getScreen() != null) {
            getScreen().dispose();
        }
    }
}
