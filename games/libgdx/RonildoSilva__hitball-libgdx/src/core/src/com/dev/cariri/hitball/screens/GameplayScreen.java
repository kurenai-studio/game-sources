package com.dev.cariri.hitball.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Matrix4;
import com.dev.cariri.hitball.Globals;
import com.dev.cariri.hitball.objects.Quadro;
import com.dev.cariri.hitball.objects.Vida;
import com.dev.cariri.hitball.objects.VidasFactory;
import com.dev.cariri.hitball.utils.Timer;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.Random;

import static com.badlogic.gdx.Gdx.input;

/**
 * Created by Ronildo on 27/02/2018.
 */

public class GameplayScreen extends GameScreen {

    private float tempoDeJogo;
    private boolean gameOver;
    private Timer endTimer;

    private Quadro quadro;
    private VidasFactory vidasFactory;
    private ArrayList<Vida> vidas;

    BitmapFont font;

    Texture textSquare;

    int cont = 0;

    public GameplayScreen() {
        vidasFactory =  new VidasFactory();
        vidas = vidasFactory.createVidas();

        quadro = new Quadro();
        quadro.setXY(150, 150);

        textSquare = Globals.SQUARE_RELEASE;

        endTimer = new Timer(3.5f);
        gameOver = false;

        font = new BitmapFont(); //or use alex answer to use custom font
        //font.getData().setScale(3,3);
    }

    @Override
    public void init() {
        tempoDeJogo = 60f;
    }

    @Override
    public void update(boolean topMost) {
        if(!gameOver) {
            /** Ai o Jogo acaba ne fedapota?**/
            tempoDeJogo -= Timer.DeltaTime;

            if(tempoDeJogo <= 0) {
                tempoDeJogo = 0;
                endTimer.start();
                gameOver = true;
            }
        }
    }

    @Override
    public void render(SpriteBatch spriteBatch) {
        //spriteBatch.setProjectionMatrix(new Matrix4().setToOrtho2D(0, 0, Globals.VIRTUAL_W, Globals.VIRTUAL_H));

        spriteBatch.begin();
            quadro.draw(spriteBatch);

            for (Vida vida: vidas) {
                vida.draw(spriteBatch);
            }

            font.draw(spriteBatch, "Acertos: "+String.valueOf(cont)+" \n"+timeFormat(tempoDeJogo-=(Gdx.graphics.getDeltaTime())),
                    10,
                    Globals.VIRTUAL_W);

            if(Gdx.input.isButtonPressed(Input.Buttons.LEFT)){
                System.out.println("("+Gdx.input.getX()+","+Gdx.input.getY()+")");
                if(quadro.contains(Gdx.input.getX(),Globals.VIRTUAL_H - Gdx.input.getY())){
                    System.out.println("ok");

                    cont++;

                    Random rn = new Random();
                    int x = rn.nextInt(Globals.VIRTUAL_W - Globals.TILE_SIZE) + 1;
                    int y = rn.nextInt(Globals.VIRTUAL_H - Globals.TILE_SIZE) + 1;

                    quadro.setXY(
                        x,y
                    );
                }
            }

        spriteBatch.end();

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

    private String timeFormat(float tempo){
        return String.format("%02d:%02d", ((Math.round(tempo)) % 3600) / 60, (Math.round(tempo))%60);
    }
}
