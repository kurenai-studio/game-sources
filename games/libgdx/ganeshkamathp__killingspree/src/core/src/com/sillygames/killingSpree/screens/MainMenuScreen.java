package com.sillygames.killingSpree.screens;

import java.util.ArrayList;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Preferences;
import com.badlogic.gdx.Input.TextInputListener;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.sillygames.killingSpree.KillingSpree;
import com.sillygames.killingSpree.controls.InputController;
import com.sillygames.killingSpree.helpers.MyButton;

public class MainMenuScreen extends AbstractScreen {

    private BitmapFont font;
    private SpriteBatch batch;
    private OrthographicCamera camera;
    private FitViewport viewport;
    private ArrayList<MyButton> buttons;
    private MyButton currentButton;
    private MyButton startGameButton;
    private MyButton joinGameButton;
    private MyButton practiceButton;
    private MyButton optionsButton;
    
    public MainMenuScreen(KillingSpree game) {
        super(game);
        show();
    }

    @Override
    public void render(float delta) {
        renderButtons(delta);
        processInput();
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height);
        camera.update();
    }

    @Override
    public void show() {
        font = game.getFont(170);
        batch = new SpriteBatch();
        camera = new OrthographicCamera();
        viewport = new FitViewport(1280, 720, camera);
        camera.setToOrtho(false, 1280, 720);
        buttons = new ArrayList<MyButton>();
        addAllButtons();
        final Preferences prefs = Gdx.app.getPreferences("profile");
        String name = prefs.getString("name");
        name = name.trim();
        if (name.length() == 0) {
            Gdx.input.getTextInput(new TextInputListener() {
                
                @Override
                public void input(String text) {
                    prefs.putString("name", text);
                    prefs.flush();
                }
                
                @Override
                public void canceled() {
                }
            }, "Enter name", "");
        }
    }

    @Override
    public void hide() {
    }

    @Override
    public void pause() {
    }

    @Override
    public void resume() {
    }

    @Override
    public void dispose() {
        batch.dispose();
        font.dispose();
    }
    
    public void processInput() {
        currentButton = currentButton.process();
        if (InputController.instance.buttonA()){
            processButton();
            return;
        }
        if(Gdx.input.isTouched()) {
            processTouched();
        }
    }
    
    private void processButton() {
        buttons.clear();
        if (currentButton == startGameButton) {
//            LobbyScreen lobbyScreen = new LobbyScreen(game);
//            lobbyScreen.setServer(true);
//            game.setScreen(lobbyScreen);
            startServer(false);
        } else if (currentButton == joinGameButton) {
            ClientDiscoveryScreen clientDiscoveryScreen = 
                    new ClientDiscoveryScreen(game);
            game.setScreen(clientDiscoveryScreen);
        } else if (currentButton == practiceButton) {
            startServer(true);
        } else if (currentButton == optionsButton) {
            game.setScreen(new OptionsScreen(game));
        }
    }

    private void processTouched() {
        Vector2 touchVector = viewport.unproject(new Vector2(Gdx.input.getX(),
                Gdx.input.getY()));
        for (MyButton button: buttons) {
            if(button.isPressed(touchVector, font)) {
                if (currentButton == button) {
                    processButton();
                    return;
                }
                currentButton.setActive(false);
                currentButton = button;
                currentButton.setActive(true);
                renderButtons(0.01f);
                return;
            }
        }
    }
    
    public MyButton addButton(String text, float x, float y) {
        MyButton button = new MyButton(text, x, y);
        buttons.add(button);
        return button;
    }
    
    private void renderButtons(float delta) {
        Gdx.gl.glClearColor(0, 0, 0, 0);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        for (MyButton button: buttons) {
            button.render(batch, font, delta);
        }
        batch.end();
    }
    
    private void addAllButtons() {
        startGameButton = addButton("Start game", 100, 750);
        joinGameButton = addButton("Join game", 100, 560);
        practiceButton = addButton("Solo practice", 100, 370);
        optionsButton = addButton("Options", 100, 180);
        startGameButton.setActive(true);
        currentButton = startGameButton;
        joinGameButton.setNorth(startGameButton);
        practiceButton.setNorth(joinGameButton);
        practiceButton.setSouth(optionsButton);
        startGameButton.setNorth(optionsButton);
    }
    
    private void startServer(boolean lonely) {
        Preferences prefs = Gdx.app.getPreferences("profile");
        GameScreen gameScreen = new GameScreen(game);
        gameScreen.startServer(lonely);
        String name = prefs.getString("name");
        gameScreen.loadLevel("maps/retro-small.tmx", "localhost",
                name);
        game.setScreen(gameScreen);
    }

}
