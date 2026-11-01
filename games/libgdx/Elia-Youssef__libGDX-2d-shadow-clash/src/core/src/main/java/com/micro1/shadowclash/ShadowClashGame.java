package com.micro1.shadowclash;

import com.badlogic.gdx.Game;

/** Application entry: loads assets once and hands off to the single match screen. */
public final class ShadowClashGame extends Game {

    private Assets assets;

    @Override
    public void create() {
        assets = new Assets();
        setScreen(new MatchScreen(assets));
    }

    @Override
    public void dispose() {
        if (getScreen() != null) getScreen().dispose();
        if (assets != null) assets.dispose();
    }
}
