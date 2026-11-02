package com.ychstudio.gamesys;

import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.assets.loaders.resolvers.InternalFileHandleResolver;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.TmxMapLoader;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Disposable;

public class GameManager implements Disposable {

    public static final GameManager instance = new GameManager();

    public static final short NOTHING_BIT   = 0;
    public static final short WALL_BIT      = 1 << 0;
    public static final short PLAYER_BIT    = 1 << 1;
    public static final short ANIMAL_BIT    = 1 << 2;
    public static final short NPC_BIT       = 1 << 3;
    public static final short NPC_ITEM_BIT  = 1 << 4;

    public static final float PPM = 32f;
    public static AssetManager assetManager;

    public static Vector2 playerSpawnPos = new Vector2();
    public static Vector2 playerCurrentPos = new Vector2();

    // the area bound that player and NPC can move
    public static Rectangle moveBound = new Rectangle();

    private GameManager() {
        assetManager = new AssetManager();

        assetManager.setLoader(TiledMap.class, new TmxMapLoader(new InternalFileHandleResolver()));
        assetManager.load("maps/map1.tmx", TiledMap.class);

        assetManager.load("img/actors.pack", TextureAtlas.class);
        assetManager.finishLoading();
    }

    @Override
    public void dispose() {
        assetManager.dispose();
    }

}
