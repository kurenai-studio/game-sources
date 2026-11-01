package com.devcariri.submax;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Json;
import com.devcariri.submax.gui.GUI;

/**
 * Created by RoNigga on 31/01/2017.
 */

public class ScoreHandler {
    public int sessionScore = 0;
    private Json json;
    public int scoreToAdd = 0;

    float offset = 0;
    Timer waitTimer, additionTimer;

    public ScoreHandler() {
        json = new Json();
        waitTimer = new Timer(0.2f, true);
        additionTimer = new Timer(0.9f, true);
    }

    public void update() {
        if(scoreToAdd > 0) {
            if(waitTimer.tick()) {
                additionTimer.start();
                waitTimer.stop();
            }
        }
        if(additionTimer.isRunning()) {
            //offset = Globals.lerp(offset, -Assets.GGFont.getBounds("PONTOS ").width-Assets.GGFont.getBounds("+"+scoreToAdd).width, Timer.DeltaTime*5);
            offset = Globals.lerp(offset, -1.0f , Timer.DeltaTime*5);
            if(additionTimer.tick()) {
                additionTimer.stop();
                sessionScore += scoreToAdd;
                scoreToAdd = 0;
            }
        }
    }

    public void drawScore(SpriteBatch b, Vector2 v) {
        //RETANGULO SUPERIOR
        GUI.drawRect(b, new Rectangle(0,
                        v.y - 50,
                        Globals.VIRTUAL_W,
                        50),
                        Color.RED);

        Color batchCol = b.getColor();
        b.setColor(Color.WHITE);

        if(scoreToAdd > 0) {
            Color c = Color.ORANGE.cpy();
            c.a = (1-(additionTimer.getTime()/1));
            //c.a = (1-(additionTimer.getTime()/1));
            Assets.GGFont.setColor(c);

            Assets.GGFont.draw(b,
                    "+"+ scoreToAdd,
                    Globals.VIRTUAL_W/2 - 1.0f,
                    Globals.VIRTUAL_H/2);
        }

        Assets.GGFont.setColor(Color.WHITE);
		/*
    	Assets.GGFont.draw(b, Globals.SCORE + sessionScore,
    			(Globals.VIRTUAL_W - Assets.GFont.getBounds(Globals.SCORE + sessionScore+"").width)/2, 40);
    	*/
        Assets.drawCenteredString(b, Assets.GGFont, Globals.SCORE + sessionScore,
                new Vector2(Globals.VIRTUAL_W/2, 40), 0.7f, false);
        b.setColor(batchCol);
    }

    public void addScore(int v) {
        scoreToAdd += v;
        waitTimer.stop();
        waitTimer.start();
        additionTimer.stop();
        offset = 0;
    }

}
