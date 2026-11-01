package com.alligatorX.game.view;

// Import other classes
import com.alligatorX.game.TypeHigher;
import com.badlogic.gdx.Gdx;
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

public class GameOverScreen implements Screen {

    // Transfer batch
    private TypeHigher game;

    // Cameras and drawings
    private OrthographicCamera camera;
    private ExtendViewport viewport;
    private BitmapFont font;

    private boolean isPlayerWon; // Check if player has won
    private int finalScore; // Check user final score
    private int targetLength; // Need for restart

    private String currentTyped = "";

    private float popScale = 1.0f; // Control physical size of text
    private String previousTyped = ""; // Detect if a new letter is entered
    private float shakeTimer = 0f; // Typo timer

    private float transitionTimer = -1f; // NOT transitioning
    private boolean isQuitting = false;
    private boolean isGoingToMenu = false;

    public GameOverScreen(TypeHigher game, boolean isPlayerWon, int finalScore, int targetLength) {
        this.game = game;
        this.isPlayerWon = isPlayerWon;
        this.finalScore = finalScore;
        this.targetLength = targetLength;
    }

    @Override
    public void show() {
        game.playMenuMusic();

        if (isPlayerWon) {
            game.playWinSound();
        } else {
            game.playLoseSound();
        }

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

        Gdx.input.setInputProcessor(new InputAdapter() {
            @Override
            public boolean keyTyped(char character) {

                // If a transition is already happening, ignore all typing!
                if (transitionTimer >= 0) {
                    return true;
                }

                currentTyped += character; // Add character typed into currentTyped

                boolean isValid = "restart".startsWith(currentTyped) ||
                    "menu".startsWith(currentTyped) ||
                    "quit".startsWith(currentTyped);

                if (isValid) {
                    game.playTypingSound();
                    // Check user input
                    if (currentTyped.equals("restart")) { // if user chooses restart
                        transitionTimer = 0.1f;
                    } else if (currentTyped.equals("menu")) { // If user chooses menu
                        isGoingToMenu = true;
                        transitionTimer = 0.1f;
                    } else if (currentTyped.equals("quit")) {
                        isQuitting = true;
                        transitionTimer = 0.1f;
                    }
                } else {
                    game.playTypoSound();
                    currentTyped = "";
                    shakeTimer = 0.2f;
                }
                return true;
            }
            @Override
            public boolean keyDown(int keyCode) {
                // If user press F11, toggle fullscreen
                if (keyCode == com.badlogic.gdx.Input.Keys.F11) {
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
                } else if (isGoingToMenu) {
                    game.setScreen(new MainMenuScreen(game));
                } else {
                    game.setScreen(new GameScreen(game, targetLength));
                    dispose();
                }
                return;
            }

        }

        // Dark red background if lost, dark green background if won
        if (isPlayerWon) {
            ScreenUtils.clear(0, 0.2f, 0, 1);
        } else {
            ScreenUtils.clear(0.2f, 0, 0, 1);
        }

        // LERP MATH
        // Detect keystroke for 'Pop'
        if (currentTyped.length() > previousTyped.length()) {
            popScale = 1.3f; // 1.3x size
        } else if (currentTyped.length() == 0 && previousTyped.length() > 0) {
            popScale = 1.3f; // Pop if they made mistake and word is cleared
        }
        previousTyped = currentTyped;

        // Shrinks smoothly back to normal
        popScale = MathUtils.lerp(popScale, 1.0f, delta * 15f);

        // Tell batch to look through camera lens before start painting
        game.batch.setProjectionMatrix(camera.combined);
        game.batch.begin();

        // Draw title
        font.setColor(Color.WHITE);
        if (isPlayerWon) {
            font.draw(game.batch, "YOU SURVIVED!", 0, viewport.getWorldHeight() - 50, viewport.getWorldWidth(), Align.center, false);
        } else {
            font.draw(game.batch, "YOU FELL...", 0, viewport.getWorldHeight() - 50, viewport.getWorldWidth(), Align.center, false);
        }

        // Draw Information
        font.draw(game.batch, "Final Score: " + finalScore, 0,viewport.getWorldHeight() - 100, viewport.getWorldWidth(), Align.center, false);

        // Draw Instructions
        float startY = viewport.getWorldHeight() / 2 + 100; // Starts slightly above middle screen
        font.draw(game.batch, "> restart", 0, startY, viewport.getWorldWidth(), Align.center, false);
        font.draw(game.batch, "> menu", 0, startY - 50, viewport.getWorldWidth(), Align.center, false);
        font.draw(game.batch, "> quit", 0, startY - 100, viewport.getWorldWidth(), Align.center, false);

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

        font.draw(game.batch, "Typing: " + currentTyped, shakeOffsetX, startY - 180, viewport.getWorldWidth(), Align.center, false);

        // Reset Scale
        font.getData().setScale(1.0f);

        game.batch.end();
    }

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
