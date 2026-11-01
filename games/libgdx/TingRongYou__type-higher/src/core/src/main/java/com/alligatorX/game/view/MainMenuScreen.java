package com.alligatorX.game.view;

// Import other classes
import com.alligatorX.game.TypeHigher;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.utils.Align;
import com.badlogic.gdx.utils.ScreenUtils;
import com.badlogic.gdx.utils.viewport.ExtendViewport;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator;
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator.FreeTypeFontParameter;

public class MainMenuScreen implements Screen {

    // Transfer batch
    private TypeHigher game;

    // Camera and font
    private OrthographicCamera camera;
    private ExtendViewport viewport;
    private BitmapFont font;

    // A simple String to hold what the user is typing
    private String currentTyped = "";

    private float popScale = 1.0f; // Control physical size of text
    private String previousTyped = ""; // Detect if a new letter is entered
    private float shakeTimer = 0f; // Typo timer

    private float transitionTimer = -1f; // NOT transitioning
    private int selectedLength = 0;
    private boolean isQuitting = false;

    public MainMenuScreen(TypeHigher game) {
        this.game = game;
    }

    @Override
    public void show() {
        game.playMenuMusic();
        this.camera = new OrthographicCamera();
        this.viewport = new ExtendViewport(800, 600, camera);

        // FreeType font
        // 1. Load .ttf file from assets folder
        FreeTypeFontGenerator generator = new FreeTypeFontGenerator(Gdx.files.internal("fonts/gamefont.ttf"));
        FreeTypeFontParameter parameter = new FreeTypeFontParameter();

        // 2. Set the BASE resolution size to 48 pixels to avoid blurring
        parameter.size = 48;
        parameter.color = Color.WHITE;

        // 3. Generate the font
        this.font =  generator.generateFont(parameter);

        // 4. Dispose generator to avoid memory leaks
        generator.dispose();

        this.font.getData().setScale(1.0f); // Make text larger

        // Listen to user input
        Gdx.input.setInputProcessor(new InputAdapter() {
            @Override
            public boolean keyTyped(char character) {

                // If a transition is already happening, ignore all typing!
                if (transitionTimer >= 0) {
                    return true;
                }

                // Add typed character into currentTyped
                currentTyped += character;

                // Check if what they have typed so far is valid
                boolean isValid = "thirty".startsWith(currentTyped) ||
                    "sixty".startsWith(currentTyped) ||
                    "ninety".startsWith(currentTyped) ||
                    "unlimited".startsWith(currentTyped) ||
                    "quit".startsWith(currentTyped);

                if (isValid) {
                    game.playTypingSound();
                    // Check if it is a valid input
                    if (currentTyped.equals("thirty")) {
                        selectedLength = 30;
                        transitionTimer = 0.1f;
                    } else if (currentTyped.equals("sixty")) {
                        selectedLength = 60;
                        transitionTimer = 0.1f;
                    } else if (currentTyped.equals("ninety")) {
                        selectedLength = 90;
                        transitionTimer = 0.1f;
                    } else if (currentTyped.equals("unlimited")) {
                        selectedLength = -1;
                        transitionTimer = 0.1f;
                    } else if (currentTyped.equals("quit")) {
                        isQuitting = true; // Closes the game instantly
                        transitionTimer = 0.1f;
                    }
                } else {
                    game.playTypoSound();
                    currentTyped = ""; // Reset user typing
                    shakeTimer = 0.2f; // 0.2 second shake
                }
                return true;
            }
            @Override
            public boolean keyDown(int keyCode) {
                // If user press F11, toggle fullscreen
                if (keyCode == Input.Keys.F11) {
                    game.playSystemSound();
                    // Check if already fullscreen
                    boolean isFullScreen = Gdx.graphics.isFullscreen();

                    // If already fullscreen
                    if (isFullScreen) {
                        // Go back to default window mode (800x600)
                        Gdx.graphics.setWindowedMode(800, 600);
                    } else { // If still haven't full screen
                        // Get monitor max resolution and go fullscreen
                        Gdx.graphics.setFullscreenMode(Gdx.graphics.getDisplayMode());
                    }
                }
                return true;
            }
        });

    }

    @Override
    public void render(float delta) {

        // Handle transition countdown
        if (transitionTimer >= 0) {
            transitionTimer -= delta;

            // When the timer hits zero, execute the screen swap!
            if (transitionTimer <= 0) {
                if (isQuitting) {
                    Gdx.app.exit();
                } else {
                    game.setScreen(new GameScreen(game, selectedLength));
                    dispose();
                }
                return;
            }

        }

        ScreenUtils.clear(0, 0, 0.2f, 1); // Dark blue background for the menu

        // LERP MATH
        // Detect keystroke for 'Pop'
        if (currentTyped.length() > previousTyped.length()) {
            popScale = 1.1f; // 1.3x size
        } else if (currentTyped.length() == 0 && previousTyped.length() > 0) {
            popScale = 1.1f; // Pop if they made mistake and word is cleared
        }
        previousTyped = currentTyped;

        // Shrinks smoothly back to normal
        popScale = MathUtils.lerp(popScale, 0.8f, delta * 15f);

        // Tell batch to look through camera lens before start painting
        game.batch.setProjectionMatrix(camera.combined);
        game.batch.begin();

        // Draw Title
        font.getData().setScale(1.3f);
        font.setColor(Color.GOLD);
        font.draw(game.batch, "TYPE HIGHER", 0, viewport.getWorldHeight() - 100, viewport.getWorldWidth(), Align.center, false);

        // Draw Instructions
        float startY = viewport.getWorldHeight() / 2 + 100; // Starts slightly above middle screen
        font.getData().setScale(0.8f);
        font.setColor(Color.WHITE);
        font.draw(game.batch, "> thirty", 0, startY, viewport.getWorldWidth(), Align.center, false);
        font.draw(game.batch, "> sixty", 0, startY - 50, viewport.getWorldWidth(), Align.center, false);
        font.draw(game.batch, "> ninety", 0, startY - 100, viewport.getWorldWidth(), Align.center, false);
        font.draw(game.batch, "> unlimited", 0, startY - 150, viewport.getWorldWidth(), Align.center, false);
        font.draw(game.batch, "> quit", 0, startY - 200, viewport.getWorldWidth(), Align.center, false);
        font.draw(game.batch, "> Press F11 to toggle Fullscreen", 20, 40);
        // Draw popping text
        font.getData().setScale(popScale); // Apply pop scale

        // Shake math
        float shakeOffsetX = 0f;
        if (shakeTimer > 0) {
            shakeTimer -= delta;
            shakeOffsetX = MathUtils.random(-8f, 8f);
        }

        // Draw what the user typed
        if (shakeTimer > 0) {
            font.setColor(Color.RED);
        } else {
            font.setColor(Color.GREEN);
        }

        font.draw(game.batch, "Typing: " + currentTyped, shakeOffsetX, startY - 280, viewport.getWorldWidth(), Align.center, false);

        game.batch.end();

    }

    // Resize windows
    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true);
    }

    @Override
    public void pause() {

    }

    @Override
    public void resume() {

    }


    @Override
    public void hide() {

    }

    @Override
    public void dispose() {
        font.dispose();
    }
}
