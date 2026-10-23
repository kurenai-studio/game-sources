package by.sahrok.jroguelike.screens;

import by.sahrok.jroguelike.GdxGame;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;

public class LoadingScreen extends ScreenAdapter {

    private final GdxGame game = GdxGame.getInstance();

    public LoadingScreen() {
        game.assetManager.load("ui/uiskin.json", Skin.class);
    }

    @Override
    public void render(float delta) {
        if(game.assetManager.update()) {
            game.changeScreen(Screen.MAIN_MENU);
        }
    }
}
