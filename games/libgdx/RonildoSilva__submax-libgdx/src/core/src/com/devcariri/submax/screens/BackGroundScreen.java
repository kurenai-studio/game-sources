package com.devcariri.submax.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Matrix4;
import com.badlogic.gdx.math.Rectangle;
import com.devcariri.submax.Assets;
import com.devcariri.submax.Globals;
import com.devcariri.submax.InputHandler;
import com.devcariri.submax.gui.GUI;

/**
 * Created by RoNigga on 31/01/2017.
 */

public class BackGroundScreen extends Screen {

    public static Color corBackGround = Color.YELLOW;


    @Override
    public void init() {

    }

    @Override
    public void update(InputHandler input, boolean topMost) {
        // TODO Auto-generated method stub

    }

    @Override
    public void render(SpriteBatch b, InputHandler input) {
        /** Configura Tela **/
        b.setProjectionMatrix(new Matrix4().setToOrtho2D(0, 0, Globals.VIRTUAL_W, Globals.VIRTUAL_H));
        Gdx.gl.glClearColor(1f, 1f, 1f, 1f);
        b.begin();
        {
            // clear color (cobre o background com a cor)
//				GUI.drawRect(b, new Rectangle(0, 0, Globals.VIRTUAL_W, Globals.VIRTUAL_H),Globals.BACKGROUND_COLOR);

            //Mistura a cor da textura do Background com a cor
            //GUI.drawRect(b, new Rectangle(0, 0, Globals.VIRTUAL_W, Globals.VIRTUAL_H),corBackGround);

            b.draw(Assets.BACKGROUND,0, 0, Globals.VIRTUAL_W, Globals.VIRTUAL_H);
        }
        b.end();
    }

    @Override
    public void transitionIn() {

    }

    @Override
    public void transitionOut() {

    }

    @Override
    public void dispose() {

    }

}
