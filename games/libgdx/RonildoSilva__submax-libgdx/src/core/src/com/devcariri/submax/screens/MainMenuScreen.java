package com.devcariri.submax.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.ParticleEffect;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Matrix4;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.devcariri.submax.Assets;
import com.devcariri.submax.Globals;
import com.devcariri.submax.InputHandler;
import com.devcariri.submax.STATES;
import com.devcariri.submax.SubMaxGame;
import com.devcariri.submax.Timer;
import com.devcariri.submax.gui.GUI;

/**
 * Created by RoNigga on 31/01/2017.
 */

public class MainMenuScreen extends Screen {

    BitmapFont mFont;
    Color[] bgColors;
    ParticleEffect menuEffect;
    Rectangle playButton, scoreButton, tutorialButton, window;
    Color bgColor;
    Vector2[] linePositions;
    boolean setFirst, wasPressed;

    Timer[] titleTimers;
    float[] titleFloats;
    float[] targetFloats;

    public MainMenuScreen() {
        requiresInput = true;
        mFont = Assets.GGFont;
        bgColor = Color.BLACK;
        window = new Rectangle(0,-Globals.VIRTUAL_H,Globals.VIRTUAL_W,Globals.VIRTUAL_H);

        playButton = new Rectangle(Globals.VIRTUAL_W*0.5f - 100, Globals.VIRTUAL_H/3, 200, Globals.MENU_BUTTON_H);
        scoreButton = new Rectangle(Globals.VIRTUAL_W*0.5f - 100, 100, 200, 60);
        tutorialButton = new Rectangle(Globals.VIRTUAL_W*0.5f - 100, 40, 200, 60);
    }

    @Override
    public void init() {
        titleTimers = new Timer[4];
        titleFloats = new float[4];
        targetFloats = new float[4];
        for(int i = 0; i < 4; i++) {
            titleTimers[i] = new Timer(MathUtils.random(), false);
            titleFloats[i] = 1f;
            targetFloats[i] = 0.8f+MathUtils.random(0.8f);
        }

        wasPressed = false;
        setFirst = true;
        linePositions = new Vector2[2];
        linePositions[0] = new Vector2(50, 0);
        linePositions[1] = new Vector2(100, 100);
    }

    @Override
    public void update(InputHandler input, boolean topMost) {
//		scaleTitle();
        if(State != STATES.SCREEN_TRANS_OUT && topMost) {
            if(playButton.contains(input.MousePos.x, input.MousePos.y))
            {
                SubMaxGame.screenManager.addScreen(new GameplayScreen());
                State = STATES.SCREEN_TRANS_OUT;
            } else if(tutorialButton.contains(input.MousePos.x, input.MousePos.y)) {
//				BaseGame.Screens.addScreen(new HelpScreen());
                State = STATES.SCREEN_TRANS_OUT;
            } else if(scoreButton.contains(input.MousePos.x, input.MousePos.y)) {
//				BaseGame.Screens.addScreen(new ScoreScreen());
                State = STATES.SCREEN_TRANS_OUT;
            }
        }
    }

    @Override
    public void render(SpriteBatch b, InputHandler input) {
        b.setProjectionMatrix(new Matrix4().setToOrtho2D(0, 0, Globals.VIRTUAL_W, Globals.VIRTUAL_H));

        b.begin();
        {
            mFont.setColor(Color.WHITE);
            //NOME JOGO
            Assets.drawCenteredString(b, mFont, String.valueOf(Gdx.graphics.getWidth()+ "\n" +Gdx.graphics.getHeight()),
                    new Vector2(Globals.VIRTUAL_W/2, Globals.VIRTUAL_H - 50), 1.5f, false);

            Rectangle r = new Rectangle(window.x+playButton.x, window.y+playButton.y, playButton.width, playButton.height);

            mFont.setColor(Color.BLACK);
            b.draw(Assets.SQUARE_PRESSED, r.x, r.y, r.getWidth(), r.getHeight());
            GUI.drawButton(b, Assets.GGFont, r, "JOGAR");

            /**
             rectangle = new Rectangle(window.x+scoreButton.x, window.y+scoreButton.y, scoreButton.width, scoreButton.height);
             GUI.drawButton(b, Assets.GGFont, rectangle, "MELHORES");
             rectangle = new Rectangle(window.x+tutorialButton.x, window.y+tutorialButton.y, tutorialButton.width, tutorialButton.height);
             GUI.drawButton(b, Assets.GGFont, rectangle, "CRÉDITOS");
             **/
        }
        b.end();

    }

    public void scaleTitle() {
//		for(int i = 0; i < 4; i++) {
//			if(titleTimers[i].tick()) {
//				targetFloats[i] = 0.6f+MathUtils.random(0.8f);
//				titleTimers[i].setTickRate(MathUtils.random());
//				titleTimers[i].reset();
//			}
//			titleFloats[i] = Globals.lerp(titleFloats[i], targetFloats[i], Timer.DeltaTime);
//		}
    }

    @Override
    public void transitionIn() {
        scaleTitle();
        window.y = Globals.lerp(window.y, 0, Timer.DeltaTime*4);
        if(window.y > -2f) {
            State = STATES.SCREEN_PLAY;
            window.y = 0;
        }
    }

    @Override
    public void transitionOut() {
        // aqçui fica a transicao safada
        window.y = Globals.lerp(window.y, Globals.VIRTUAL_H, Timer.DeltaTime*100);
        if(window.y >= Globals.VIRTUAL_H-20)
            isComplete = true;
    }

    @Override
    public void dispose() {
        // TODO Auto-generated method stub

    }

}