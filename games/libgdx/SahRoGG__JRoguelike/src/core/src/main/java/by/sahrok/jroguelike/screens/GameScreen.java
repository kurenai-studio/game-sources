package by.sahrok.jroguelike.screens;

import by.sahrok.jroguelike.GdxGame;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.utils.ScreenUtils;

public class GameScreen extends ScreenAdapter {

    private final GdxGame game = GdxGame.getInstance();

    private final Stage gameStage;
    private final Stage uiStage;

    public GameScreen() {
        gameStage = new Stage(game.gameViewport);
        uiStage = new Stage();
    }

    @Override
    public void render(float delta) {
        game.gameViewport.apply();
        ScreenUtils.clear(0.1f, 0.1f, 0.1f, 1f);

        gameStage.act(delta);
        gameStage.draw();

        uiStage.act(delta);
        uiStage.draw();
    }

    @Override
    public void resize(int width, int height) {
        game.gameViewport.update(width, height, true);
    }

    @Override
    public void dispose() {
        gameStage.dispose();
        uiStage.dispose();
    }
}
