package com.devcariri.submax.screens;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Matrix4;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.devcariri.submax.Assets;
import com.devcariri.submax.Globals;
import com.devcariri.submax.InputHandler;
import com.devcariri.submax.STATES;
import com.devcariri.submax.SubMaxGame;
import com.devcariri.submax.Timer;
import com.devcariri.submax.algorithm.SubConsecMax;
import com.devcariri.submax.objects.Quadro;
import com.devcariri.submax.objects.QuadrosFactory;

import java.util.ArrayList;

/**
 * Created by RoNigga on 31/01/2017.
 */

public class GameplayScreen extends Screen {

    private float tempoDeJogo;
    private Vector2 barOffset;

    private ArrayList<Quadro> colecaoQuadros;
    private ArrayList<Quadro> quadroSelecionados;

    private QuadrosFactory quadrosFactory;

    private boolean gameOver;
    private Timer endTimer;

    SubConsecMax subCM;

    public GameplayScreen() {

        quadrosFactory = new QuadrosFactory();

        barOffset = new Vector2(0,-60);

        colecaoQuadros = new ArrayList<Quadro>();
        quadroSelecionados = new ArrayList<Quadro>();

        colecaoQuadros = QuadrosFactory.createOrb();

        endTimer = new Timer(3.5f);
        gameOver = false;
    }

    @Override
    public void init() {
        tempoDeJogo = 60f;
    }

    @Override
    public void update(InputHandler input, boolean topMost) {

        // Update Score
        SubMaxGame.scoreHandler.update();

        // Player touched the screen
        boolean tocado = input.isTouched();

        if(!gameOver) {
            /** Ai o Jogo acaba ne fedapota?**/
            tempoDeJogo -= Timer.DeltaTime;

            if(tempoDeJogo <= 0) {
                tempoDeJogo = 0;
                endTimer.start();
                gameOver = true;
            }

            for (Quadro quadro : colecaoQuadros) {
                // If orb is touched
                if(tocado && quadro.contains(input.MousePos.x, input.MousePos.y)) {
                    if(!quadro.isSelected) {
                        Quadro gObj;
                        gObj = quadro;
                        gObj.isSelected = true;
                        gObj.changeTexture();
                        quadroSelecionados.add(gObj);
                    }
                }
            }

            // Player leave the screen
            boolean breakChain = false;

            for (Quadro quadro : quadroSelecionados) {

                if(!tocado) {
                    quadro.isSelected = false;
                    breakChain = true;
                }
            }

            // Player removed finger from screen
            if(!tocado || breakChain) {
                if(breakChain) {
                    int soma = 0;

                    for (Quadro quadro : quadroSelecionados) {
                        soma += quadro.getValor();
                    }

                    System.out.println("SOMA:" + soma);

                    if(SubConsecMax.getSubConMax(colecaoQuadros) == soma){
                        System.out.println("BOA!!!");
                        new Color();
                        colecaoQuadros = QuadrosFactory.createOrb();
                        tempoDeJogo += 2;
                        //Pontua de acordo com o tamanho do desafio
                        SubMaxGame.scoreHandler.addScore(colecaoQuadros.size());

                        //BackGroundScreen.corBackGround = Color.WHITE;
                    }
                    else if(SubConsecMax.getSubConMax(colecaoQuadros) != soma){
                        tempoDeJogo -= colecaoQuadros.size();
                        //ARROW

                        //BaseGame.ScoreHandler.addScore(0);


                    }

                    for (Quadro quadro : quadroSelecionados) {
                        quadro.isSelected = false;
                        quadro.recoverTexture(); //duvidoso
                    }
                }
                quadroSelecionados.clear();
            }

        }else if(endTimer.tick()) {
            State = STATES.SCREEN_TRANS_OUT;
        }
    }

    @Override
    public void render(SpriteBatch b, InputHandler input) {

        b.setProjectionMatrix(new Matrix4().setToOrtho2D(0, 0, Globals.VIRTUAL_W, Globals.VIRTUAL_H));
        b.begin();
        {
            /** Desenha os quadros **/
            for (Quadro quadro : colecaoQuadros) {
                quadro.draw(b);

            }

            int i = 0, numObjects = 0;

            // draw objs

            numObjects = quadroSelecionados.size();
            if(numObjects > 0) {
                Quadro current, next;
                for(i = 0; i < numObjects; i++) {
                    current = quadroSelecionados.get(i);
                    Rectangle curbounds = current.getBounds();
                    if(i < numObjects-1) {
                        next = quadroSelecionados.get(i+1);
                        Rectangle nexbounds = next.getBounds();
                        renderLine(b, current.getPosition().add(curbounds.width, curbounds.height),
                                next.getPosition().add(nexbounds.width, nexbounds.height));
                    }
                    else{
                        renderLine(b, current.getPosition().add(curbounds.width, curbounds.height), input.MousePos);
                    }
                }
            }

            /** HUD**/

            //BARRA INFERIOR
            Vector2 v = new Vector2(0, Globals.VIRTUAL_H);

            SubMaxGame.scoreHandler.drawScore(b, v);

            Assets.GGFont.setColor(tempoDeJogo < 10 ? Color.RED : Color.WHITE);

            //Desenha atividades do tempo de jogo
            Assets.drawCenteredString(b, Assets.GGFont,
                    Globals.TEMPO+timeFormat(tempoDeJogo),
                    new Vector2(Globals.VIRTUAL_W/2, Globals.VIRTUAL_H - 10),
                    0.5f, false);


            if(gameOver && endTimer.getTime() < 3f && State != STATES.SCREEN_TRANS_OUT) {
                //Assets.GGFont.setColor(Color.RED.cpy().sub(new Color(0.2f, 0.2f, 0.2f, 0)));
                Assets.GGFont.setColor(Color.RED);
                Assets.drawCenteredString(b, Assets.GGFont,
                        Globals.GAME_OVER,
                        new Vector2(Globals.VIRTUAL_W*0.5f,
                                Globals.VIRTUAL_H*0.5f),
                        1, false);
            }

        }
        b.end();

        b.setProjectionMatrix(new Matrix4().setToOrtho2D(0, 0, Globals.VIRTUAL_W, Globals.VIRTUAL_H));
    }

    private String timeFormat(float tempo){
        return String.format("%02d:%02d", ((Math.round(tempo)) % 3600) / 60, (Math.round(tempo))%60);
    }

    @Override
    public void transitionIn() {
        barOffset.y = Globals.lerp(barOffset.y, 0, Timer.DeltaTime*200);
        if(barOffset.y > -0.2f) {
            State = STATES.SCREEN_PLAY;
            barOffset.y = 0;
            Globals.GameTime = 0;
        }
    }

    @Override
    public void transitionOut() {
        barOffset.y = Globals.lerp(barOffset.y, -70, Timer.DeltaTime*100);
        if(barOffset.y < -58f) {
//			BaseGame.Screens.addScreen(new PostGameScreen());
            isComplete = true;
        }
    }

    @Override
    public void dispose() {

    }

    /** Render Lines**/
    public void renderLine(SpriteBatch b, Vector2 start, Vector2 end) {
        Color bcol = b.getColor();
        Color c = Color.RED.cpy();
        c.a = 0.1f;

        b.setColor(c);
        Vector2 h = end.cpy().sub(start);
        float len = h.len();
        h.nor();
        int thickness = 16;//(int)((quadroSelecionados.size()*0.5f)+1);
        for(int i = 0; i < len; i+=thickness) {
            b.draw(Assets.BLANK, start.x + (i * h.x), start.y + (i * h.y) - thickness/2, thickness, thickness);
        }
        b.setColor(bcol);
    }
}
