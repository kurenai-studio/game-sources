package com.devcariri.submax.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Matrix4;
import com.badlogic.gdx.math.Vector2;
import com.devcariri.submax.Assets;
import com.devcariri.submax.Globals;
import com.devcariri.submax.InputHandler;
import com.devcariri.submax.STATES;
import com.devcariri.submax.SubMaxGame;
import com.devcariri.submax.Timer;

/**
 * Created by RoNigga on 31/01/2017.
 */

public class SplashScreen extends Screen {

    float fontScale = 0.5f;
    String state;
    Color fontColor;

    Vector2 webPosition;

    float timeSplash;

    @Override
    public void init() {
        timeSplash = 3f;

        requiresInput = true;
        fontColor = Color.BLACK.cpy();
        fontColor.a = 0;
        webPosition = new Vector2(-Globals.VIRTUAL_W, 10);
        state = "copyright";
    }

    @Override
    public void update(InputHandler input, boolean topMost) {
        timeSplash -= Timer.DeltaTime;

        if(state.equals("copyright")) {
            fontColor.a = Globals.lerp(fontColor.a, 1f, Timer.DeltaTime*2);
            //if(input.isFirstTouched())
            if(timeSplash <= 200f) //2f
                state = "copyright-out";
        }
        else if(state.equals("copyright-out")) {
            fontColor.a = Globals.lerp(fontColor.a, 0, Timer.DeltaTime*4);
            if(fontColor.a <= 0.05f)
                state = "name";
        }
        else if(state.equals("name")) {
            webPosition.x = Globals.lerp(webPosition.x, Globals.VIRTUAL_W*0.5f, Timer.DeltaTime*4);
            fontColor.a = Globals.lerp(fontColor.a, 1f, Timer.DeltaTime*2);
            //if(input.isFirstTouched())
            if(timeSplash <= 0)
                state = "name-out";
        }
        else if(state.equals("name-out")) {
            webPosition.x = Globals.lerp(webPosition.x, Globals.VIRTUAL_W*2f, Timer.DeltaTime*4);
            fontColor.a = Globals.lerp(fontColor.a, 0, Timer.DeltaTime*4);
            if(fontColor.a <= 0.05f)
                State = STATES.SCREEN_TRANS_OUT;
        }
    }

    @Override
    public void dispose() {

    }

    @Override
    public void render(SpriteBatch b, InputHandler input) {

        //-------------- Set Screen --------------
        b.setProjectionMatrix(new Matrix4().setToOrtho2D(0, 0, Globals.VIRTUAL_W, Globals.VIRTUAL_H));

        b.begin();
        {
            Gdx.gl.glClear( GL20.GL_COLOR_BUFFER_BIT | GL20.GL_DEPTH_BUFFER_BIT );

			/*
			if(state.contains("copyright")) {
				b.draw(Assets.HIVE_LOGO, (Globals.VIRTUAL_W - Assets.HIVE_LOGO.getWidth()) / 2,
						(Globals.VIRTUAL_H - Assets.LIBGDX_LOGO.getHeight()) /2,
						Assets.HIVE_LOGO.getWidth(), Assets.HIVE_LOGO.getHeight());
			}

            if(state.contains("name")) {
                b.draw(Assets.LIBGDX_LOGO, (Globals.VIRTUAL_W - Assets.LIBGDX_LOGO.getWidth()) / 2,
                        (Globals.VIRTUAL_H - Assets.LIBGDX_LOGO.getHeight()) /2,
                        Assets.LIBGDX_LOGO.getWidth(), Assets.LIBGDX_LOGO.getHeight());
            }
            */
        }
        b.end();
    }

    @Override
    public void transitionIn() {
        State = STATES.SCREEN_PLAY;
    }

    @Override
    public void transitionOut() {
        isComplete = true;
        SubMaxGame.screenManager.addScreen(new MainMenuScreen());
    }
}