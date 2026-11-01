package com.dev.cariri.hitball;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;

/**
 * Created by Ronildo on 27/02/2018.
 */

public class Globals {
    /** Configuracoes de resolucao do aparelho **/
    public static final int VIRTUAL_W = Gdx.graphics.getWidth();
    public static final int VIRTUAL_H = Gdx.graphics.getHeight();

    public static int TILE_SIZE = 60;

    public static float FPS = 1.0f / 60.0f;
    public static float GameTime = 0;

    public static Texture SQUARE_RELEASE = new Texture(Gdx.files.internal("objects/sqb.png") );

    public static int HEART_SIZE = 30;
    public static Texture LIFE_TEXTURE = new Texture(Gdx.files.internal("objects/heart-icon.png") );

}
