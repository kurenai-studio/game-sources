package com.dev.cariri.hitball.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

import java.util.ArrayList;

/**
 * Created by Ronildo on 27/02/2018.
 */

public class GameScreenManager {
    private ArrayList<GameScreen> listaScreens;
    private SpriteBatch mBatch;

    public GameScreenManager()
    {
        mBatch = new SpriteBatch();
        listaScreens = new ArrayList<GameScreen>();
    }

    public GameScreen getScreen(int index) { return listaScreens.get(index); }

    public void addScreen(GameScreen screen) {
        screen.init();
        listaScreens.add(screen);
    }

    public void dispose() {
        for(int i = 0; i < listaScreens.size(); i++) {
            listaScreens.get(i).dispose();
        }
        listaScreens.clear();
        mBatch.dispose();
    }

    public void update()
    {
        // update top most
        for(int i = listaScreens.size()-1; i >= 0; --i) {
            GameScreen curScreen = listaScreens.get(i);
            curScreen.dispose();
        }
    }

    public void render()
    {
        for (GameScreen gameScreen:listaScreens) {
            gameScreen.render(mBatch);
        }
    }
}
