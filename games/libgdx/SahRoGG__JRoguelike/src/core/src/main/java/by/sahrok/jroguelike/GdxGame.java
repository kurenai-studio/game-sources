package by.sahrok.jroguelike;

import by.sahrok.jroguelike.screens.*;
import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.utils.viewport.ExtendViewport;
import com.badlogic.gdx.utils.viewport.Viewport;
import com.sun.source.tree.IntersectionTypeTree;

public class GdxGame extends Game {

    public static final float UNIT = 16f;

    private static GdxGame instance;

    private GameScreen gameScreen;
    private SettingsScreen settingsScreen;
    private MainMenuScreen mainMenuScreen;
    private LoadingScreen loadingScreen;

    public OrthographicCamera camera;
    public Viewport gameViewport;
    public AssetManager assetManager;

    private GdxGame() {}

    @Override
    public void create() {
        camera = new OrthographicCamera();
        gameViewport = new ExtendViewport(
            Gdx.graphics.getWidth() / UNIT,
            Gdx.graphics.getHeight() / UNIT,
            camera
        );

        assetManager = new AssetManager();

        changeScreen(Screen.LOADING);
    }

    @Override
    public void dispose() {
        assetManager.dispose();
    }

    public void changeScreen(Screen screen) {
        switch (screen) {
            case GAME:
                if(gameScreen == null) gameScreen = new GameScreen();
                setScreen(gameScreen);
                break;
            case SETTINGS:
                if(settingsScreen == null) settingsScreen = new SettingsScreen();
                setScreen(settingsScreen);
                break;
            case MAIN_MENU:
                if(mainMenuScreen == null) mainMenuScreen = new MainMenuScreen();
                setScreen(mainMenuScreen);
                break;
            case LOADING:
                if(loadingScreen == null) loadingScreen = new LoadingScreen();
                setScreen(loadingScreen);
                break;
        }
    }

    public static GdxGame getInstance() {
        if(instance == null) instance = new GdxGame();
        return instance;
    }
}
