package com.micro1.immortalcombat;

import com.badlogic.gdx.Game;

/** Owns the desktop demo's screen lifecycle. */
public class ImmortalCombatGame extends Game {

    @Override
    public void create() {
        setScreen(new GameScreen());
    }

    @Override
    public void dispose() {
        if (getScreen() != null) {
            getScreen().dispose();
        }
        super.dispose();
    }
}
