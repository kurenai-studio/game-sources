package com.micro1.territory;

import com.badlogic.gdx.Game;

/**
 * 2D Visual Territory Selection Challenge: a timed visual-estimation game where the player and
 * three CPUs race to pick the largest of four colored territories across four rounds. Hosts the
 * single {@link GameScreen}.
 */
public class TerritoryGame extends Game {

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
