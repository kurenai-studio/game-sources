package com.devcariri.submax.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.devcariri.submax.InputHandler;
import com.devcariri.submax.STATES;

import java.util.ArrayList;

/**
 * Created by RoNigga on 31/01/2017.
 */

public class ScreenManager {

    private ArrayList<Screen> listaScreens;
    private InputHandler mInputHandler;
    private SpriteBatch mBatch;

    public ScreenManager()
    {
        mInputHandler = new InputHandler();
        Gdx.input.setInputProcessor(mInputHandler);
        mBatch = new SpriteBatch();
        listaScreens = new ArrayList<Screen>();
    }

    public Screen getScreen(int index) { return listaScreens.get(index); }

    public void addScreen(Screen screen) {
        screen.init();
        listaScreens.add(screen);
        System.out.println("add "+screen.getClass().getName());
    }

    public void removeScreen(int index) {
        listaScreens.get(index).State = STATES.SCREEN_TRANS_OUT;
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
        mInputHandler.process();
        // update top most
        for(int i = listaScreens.size()-1; i >= 0; --i) {
            Screen curScreen = listaScreens.get(i);
            if(curScreen.State == STATES.SCREEN_TRANS_OUT) {
                curScreen.transitionOut();
                if(curScreen.isComplete()) {
                    curScreen.dispose();
                    listaScreens.remove(curScreen);
                    //i++;
                }
            } else if(curScreen.State == STATES.SCREEN_TRANS_IN) {
                curScreen.transitionIn();

            } else {
                curScreen.update(mInputHandler, i == listaScreens.size()-1);
            }

        }
    }

    public void render()
    {
        for(int i = 0; i < listaScreens.size(); i++) {
            listaScreens.get(i).render(mBatch, mInputHandler);
        }
    }
}