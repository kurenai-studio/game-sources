package by.sahrok.jroguelike.screens;

import by.sahrok.jroguelike.GdxGame;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ClickListener;

public class MainMenuScreen extends ScreenAdapter {

    private final GdxGame game = GdxGame.getInstance();

    private final Stage stage;
    private final Skin skin;

    public MainMenuScreen() {
        stage = new Stage();
        skin = game.assetManager.get("ui/uiskin.json", Skin.class);

        Gdx.input.setInputProcessor(stage);
    }

    @Override
    public void show() {
        Table table = new Table();
        table.setBounds(
            0, 0,
            600,
            400
        );

        TextButton startGameButton = new TextButton("Start game", skin);
        startGameButton.addListener(new ClickListener() {
            @Override
            public boolean touchDown(InputEvent event, float x, float y, int pointer, int button) {
                game.changeScreen(Screen.GAME);
                return true;
            }
        });
        TextButton exitGameButton = new TextButton("Exit the game", skin);
        exitGameButton.addListener(new ClickListener() {
            @Override
            public boolean touchDown(InputEvent event, float x, float y, int pointer, int button) {
                Gdx.app.exit();
                return true;
            }
        });

        Label titleLabel = new Label("JRoguelike", skin);

        table.add(titleLabel).colspan(2).row();
        table.add(startGameButton).pad(5f);
        table.add(exitGameButton).colspan(2);

        stage.addActor(table);
    }

    @Override
    public void render(float delta) {
        stage.act(delta);
        stage.draw();
    }

    @Override
    public void resize(int width, int height) {
        stage.getViewport().update(width, height, true);
    }

    @Override
    public void dispose() {
        stage.dispose();
        skin.dispose();
    }
}
