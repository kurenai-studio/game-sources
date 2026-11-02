package ru.samsung.gamestudio;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Preferences;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

import ru.samsung.gamestudio.screens.ScreenGame;
import ru.samsung.gamestudio.screens.ScreenMenu;
import ru.samsung.gamestudio.screens.ScreenRestart;

public class MyGdxGame extends Game {

    public SpriteBatch batch;
    public OrthographicCamera camera;

    public static final int SCR_WIDTH = 1280;
    public static final int SCR_HEIGHT = 720;

    public ScreenGame screenGame;
    public ScreenMenu screenMenu;
    public ScreenRestart screenRestart;

    private Preferences prefs;

    @Override
    public void create() {
        batch = new SpriteBatch();
        camera = new OrthographicCamera();
        camera.setToOrtho(false, SCR_WIDTH, SCR_HEIGHT);

        prefs = com.badlogic.gdx.Gdx.app.getPreferences("FlappyBirdPrefs");

        screenGame = new ScreenGame(this);
        screenMenu = new ScreenMenu(this);
        screenRestart = new ScreenRestart(this);

        setScreen(screenMenu);
    }

    public int getBestScore() {
        return prefs.getInteger("best_score", 0);
    }

    public void updateBestScore(int score) {
        if (score > getBestScore()) {
            prefs.putInteger("best_score", score);
            prefs.flush();
        }
    }

    @Override
    public void dispose() {
        batch.dispose();
    }
}
