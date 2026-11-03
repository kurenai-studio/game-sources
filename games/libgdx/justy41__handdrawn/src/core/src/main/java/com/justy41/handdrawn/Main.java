package com.justy41.handdrawn;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.utils.ScreenUtils;
import com.justy41.handdrawn.core.SceneManager;
import com.justy41.handdrawn.scenes.StartScene;

/** {@link com.badlogic.gdx.ApplicationListener} implementation shared by all platforms. */
public class Main extends ApplicationAdapter {
    private SpriteBatch batch;

    SceneManager sceneManager;
    StartScene startScene;

    @Override
    public void create() {
        batch = new SpriteBatch();

        sceneManager = new SceneManager();
        startScene = new StartScene();

        sceneManager.addScene(startScene);
        sceneManager.getCurrentScene().start(batch);
    }

    @Override
    public void render() {
        // UPDATE
        sceneManager.getCurrentScene().update(Gdx.graphics.getDeltaTime());

        // RENDER
        ScreenUtils.clear(0.21f, 0.15f, 0.2f, 1f);
        sceneManager.getCurrentScene().render(batch);

        sceneManager.loopEnd();
    }

    @Override
    public void dispose() {
        batch.dispose();
    }
}
