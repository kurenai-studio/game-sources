package com.devcariri.submax;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.Vector2;

/**
 * Created by RoNigga on 31/01/2017.
 */

public class Globals {

    /** Configuracoes de resolucao do aparelho **/
    public static final int VIRTUAL_W = Gdx.graphics.getWidth();
    public static final int VIRTUAL_H = Gdx.graphics.getHeight();

    public static final int MENU_BUTTON_H = 60;

    /** Quantidade de Quadros por linha e coluna **/
    public static int QUD_TILE_H = 5;
    public static int QUD_TILE_W = 5;

    public static int TILE_SIZE = VIRTUAL_W/(QUD_TILE_W+1);

    public static int OFFSET_TILE = TILE_SIZE/(QUD_TILE_W+1);

    //Maximo de altura que todos os quadros pode tomar
    public static float LIM_H = (QUD_TILE_H*OFFSET_TILE) + (QUD_TILE_H * TILE_SIZE);
    //Maximo de largura que todos os quadros pode tomar
    public static float LIM_W = QUD_TILE_W * (OFFSET_TILE + TILE_SIZE);

    //Alinhar Eixo Y
    public static float ALIGN_Y = ((Gdx.graphics.getHeight() - Globals.LIM_H)/2); //854 - 115

    //public static float ALIGN_Y = ((Gdx.graphics.getHeight() - Globals.LIM_H)/2); //854 - 115

    public static float FPS = 1.0f / 60.0f;
    public static float GameTime = 0;

    public static Color BACKGROUND_COLOR = new Color(1f, 1f, 1f, 1);
    public static Color blue = new Color(0.086f, 0.34f, 0.8f,1);
    public static Color red = new Color(0.8f, 0.22f, 0.086f,1);
    public static Color green = new Color(0.086f, 0.8f, 0.245f, 1);


    /** Strings **/
    public static final String ESTA_PRONTO = "PRONTO ?";
    public static final String GAME_OVER = "GAME OVER !";
    public static final String TEMPO = "Tempo ";
    public static final String SCORE = "Pontos ";
    public static final CharSequence ERROU = "Errou !";

    /// INUTIL
    public static Vector2 AngleToVector(float angle) {
        return new Vector2((float)Math.sin(angle), -(float)Math.cos(angle));
    }
    public static float VectorToAngle(Vector2 vector) {
        return (float)Math.atan2((double)vector.x, (double)vector.y);
    }
    public static Vector2 sub(Vector2 a, Vector2 b) {
        return new Vector2( a.x - b.x, a.y - b.y );
    }
    public static Vector2 add(Vector2 a, Vector2 b) {
        return new Vector2( a.x + b.x, a.y + b.y );
    }

    // LERP = Linear Interpolation
    public static float lerp(float v0, float v1, float t) {
        return v0+(v1-v0)*t;
    }
    public static Vector2 lerp(Vector2 v0, Vector2 v1, float t) {
        return new Vector2(v0.x+(v1.x-v0.x)*t, v0.y+(v1.y-v0.y)*t);
    }
}
