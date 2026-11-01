package com.alligatorX.game.view;

// Import other classes
import com.alligatorX.game.TypeHigher;
import com.alligatorX.game.controller.GameController;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.utils.ScreenUtils;
import com.badlogic.gdx.utils.viewport.ExtendViewport;
import com.badlogic.gdx.utils.Align;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator;
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator.FreeTypeFontParameter;

public class GameScreen implements Screen {

    // Controller attributes
    private GameController gameController;

    // Transfer batch
    private TypeHigher game;

    // Save to pass to game over screen
    private int targetLength;

    // Drawings
    private BitmapFont font;
    private GlyphLayout layout; // Combine typed words and display word into one
    private Texture pixelTexture;
    private Pixmap pixmap;

    public GameScreen(TypeHigher game, int targetLength) {
        this.game = game; // Passed in game for batch
        this.targetLength = targetLength;
        this.gameController = new GameController(targetLength); // Get targeted length
    }

    // Cameras and resizing
    private OrthographicCamera camera; // 2D Camera that decides what part of the game world to look at
    private ExtendViewport viewport; // Scales the game up and down but maintaining aspect ratio by adding black bars if necessary

    // Track pause typing
    private String pauseTyped = "";
    private float pauseTransitionTimer = -1f; // Timer to smooth screen switches
    private String pendingPauseAction = ""; // Remember what command they typed

    private float popScale = 1.0f; // Control physical size of text
    private String previousTyped = ""; // Detect if a new letter is entered
    private float shakeTimer = 0f; // Tracks how long the word shakes

    // Execute once as it runs, initialize the screen
    @Override
    public void show() {
        this.camera = new OrthographicCamera();
        this.viewport = new ExtendViewport(800, 600, camera); // 800x600 as our virtual world size

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
        this.layout = new GlyphLayout();
        this.pixmap = new Pixmap(1, 1, Pixmap.Format.RGBA8888); // Dummy shapes to replace player for demo
        pixmap.setColor(Color.WHITE); // Set color to white
        pixmap.fill(); // Fill (Originally transparent)
        this.pixelTexture = new Texture(pixmap);
        pixmap.dispose(); // Dispose it once created

        if (targetLength == -1) {
            game.playUnlimitedGameMusic();
        } else {
            game.playLimitedGameMusic();
        }

        // Handle keyboard events
        Gdx.input.setInputProcessor(new InputAdapter() {
            @Override
            public boolean keyTyped(char character) {
                // If the current state is PAUSED
                if (gameController.getGameState() == GameController.GameState.PAUSE) {
                    if (pauseTransitionTimer >= 0) {
                        return true; // Block input during transition
                    }

                    pauseTyped += character; // Track the input during pause screen

                    boolean isValid = "restart".startsWith(pauseTyped) ||
                                        "menu".startsWith(pauseTyped) ||
                                        "quit".startsWith(pauseTyped);

                    // Check if it's a valid letter for "quit"
                    if (isValid) {
                        game.playTypingSound(); // Correct

                        if (pauseTyped.equals("restart")) {
                            pendingPauseAction = "restart";
                            pauseTransitionTimer = 0.5f;
                        } else if (pauseTyped.equals("menu")) {
                            pendingPauseAction = "menu";
                            pauseTransitionTimer = 0.5f;
                        } else if (pauseTyped.equals("quit")) {
                            pendingPauseAction = "quit";
                            pauseTransitionTimer = 0.5f;
                        }
                    } else {
                        game.playTypoSound();
                        pauseTyped = "";
                        shakeTimer = 0.2f;
                    }
                } else if (gameController.getGameState() == GameController.GameState.PLAYING) {
                    int previousTypos = gameController.getTotalTypos(); // Track typos before they press the key
                    gameController.handleKeystroke(character); // Process the key

                    // Check if typo count go up
                    if (gameController.getTotalTypos() > previousTypos) {
                        game.playTypoSound();
                        shakeTimer = 0.2f; // Trigger a 0.2 second shake
                    } else {
                        game.playTypingSound();
                    }
                }
                return true; // Return true to tells LibGdx, "I handled this input"
            }
            // Since ESC doesn't produce a specific printable character
            @Override
            public boolean keyDown(int keyCode) {
                // If user press ESC
                if (keyCode == com.badlogic.gdx.Input.Keys.ESCAPE) {
                    game.playSystemSound();
                    gameController.togglePause(); // Pause the game

                    // Reset typing memory snaps
                    if (gameController.getGameState() == GameController.GameState.PAUSE) {
                        pauseTyped = ""; // Wiped the pause String if they unpause
                        previousTyped = ""; // Wiped it so pause screen typing tracks cleanly from 0
                    } else {
                        previousTyped = gameController.getTypedPortion(); // Sync back to game word length
                    }

                    return true;
                }
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
                return false;
            }
        });
    }

    // Infinite loop that runs 60 times a second. Strict order of update logic -> clear screen -> draw
    @Override
    public void render(float delta) {
        gameController.update(delta);

        // Handle pause transitions
        if (pauseTransitionTimer >= 0) {
            pauseTransitionTimer -= delta;
            if (pauseTransitionTimer <= 0) {
                if (pendingPauseAction.equals("restart")) {
                    game.setScreen(new GameScreen(game, targetLength));
                    dispose();
                    return; // Stop rendering this frame
                } else if (pendingPauseAction.equals("menu")) {
                    game.setScreen(new MainMenuScreen(game));
                    dispose();
                    return;
                } else if (pendingPauseAction.equals("quit")) {
                    Gdx.app.exit();
                }
            }
        }

        // Check for speed up audio
        if (gameController.consumeSpeedUpSound()) {
            game.playSpeedUpSound();
        }

        ScreenUtils.clear(0, 0, 0, 1); // Black background

        // Tell the batch to look through the camera lens before starts painting
        game.batch.setProjectionMatrix(camera.combined);

        game.batch.begin(); // Start paintbrush

        // Player
        game.batch.setColor(Color.RED); // Set player to red color
        game.batch.draw(pixelTexture, gameController.getPlayerX(), gameController.getPlayerY(), 50, 100); // Draw player

        // Get String
        String fullWord = gameController.getCurrentWord();
        String typed = gameController.getTypedPortion();
        // Cuts the string (If full word is "apple", typed "app", gives "le")
        String remainingWord = fullWord.substring(typed.length());
        float shakeOffsetX = 0f;
        // Shake math
        if (shakeTimer > 0) {
            shakeTimer -= delta; // Tick down the timer
            shakeOffsetX = MathUtils.random(-8f, 8f); // Random number of -8 and 8 pixels every frame
        }

        // If playing (in game)
        if (gameController.getGameState() == GameController.GameState.PLAYING) {
            // Detect keystroke for 'Pop'
            // If typed word got longer, trigger pop effect
            if (typed.length() > previousTyped.length()) {
                popScale = 1.3f; // Jump to 1.3x size
            } else if (typed.length() == 0 && previousTyped.length() > 0) {
                popScale = 1.3f; // If player made a mistake or finished a word, pop again
            }
            previousTyped = typed; // Update previousTyped for next frame
        }

        // Find center of the String
        float textY = viewport.getWorldHeight() / 2;
        // Measure full word to perfectly center it
        layout.setText(font, fullWord);
        float startX = (viewport.getWorldWidth() - layout.width) / 2;

        // Safety check: only shake the main word if we are playing
        boolean isGameShake = (shakeTimer > 0 && gameController.getGameState() == GameController.GameState.PLAYING);
        float gameWordShakeX = isGameShake ? shakeOffsetX : 0f;
        // Draw typed portion as green
        if (isGameShake) {
            font.setColor(Color.RED);
        } else {
            font.setColor(Color.GREEN);
        }

        // Add shake offset to X coordinates
        font.draw(game.batch, typed, startX + gameWordShakeX, textY);

        // Measure typed portion
        layout.setText(font, typed); // Measure just the green text
        float offset = layout.width;// See how wide it is

        // Draw remaining portion in gray
        if (isGameShake) {
            font.setColor(Color.RED);
        } else {
            font.setColor(Color.GRAY);
        }

        // Draw gray text to starts where the green text ended
        font.draw(game.batch, remainingWord, startX + offset + gameWordShakeX, textY);

        // Display speed up message
        if (gameController.isShowingSpeedUpMessage()) {
            font.getData().setScale(0.8f);
            font.setColor(Color.YELLOW);

            // Draw slightly above main typing area
            float messageY = viewport.getWorldHeight() / 2 + 100;
            font.draw(game.batch, "SPED UP!", 0, messageY, viewport.getWorldWidth(), Align.center, false);

            // Reset scale back to normal
            font.getData().setScale(1.0f);

        }

        // Display Typo Message
        if (gameController.isShowingTypoMessage()) {
            font.getData().setScale(0.8f);
            font.setColor(Color.RED);
            float messageY = viewport.getWorldHeight() / 2 + 200;
            font.draw(game.batch, "TYPO + 1!", 0, messageY, viewport.getWorldWidth(), Align.center, false);
            font.getData().setScale(1.0f);
        }

        // Draw HUD
        // Set HUD to smaller scale
        font.getData().setScale(0.5f);
        font.setColor(Color.WHITE);
        font.draw(game.batch, "Remaining Time: " + (int) gameController.getTimeLeft(), 0, viewport.getWorldHeight() - 20, viewport.getWorldWidth(), Align.center, false);
        font.draw(game.batch, "Score: " + gameController.getScore() + "/" + targetLength, 10, viewport.getWorldHeight() - 20);

        font.setColor(Color.RED);
        font.draw(game.batch, "Typo: " + gameController.getTotalTypos() + "/5", 10, viewport.getWorldHeight() - 40);

        // Draw the overlays
        if (gameController.getGameState() == GameController.GameState.PAUSE) {
            // 2. Detect keystroke for 'Pop'
            // If typed word got longer, trigger pop effect
            if (pauseTyped.length() > previousTyped.length()) {
                popScale = 1.3f; // Jump to 1.3x size
            } else if (pauseTyped.length() == 0 && previousTyped.length() > 0) {
                popScale = 1.3f; // If player made a mistake or finished a word, pop again
            }
            previousTyped = pauseTyped; // Update previousTyped for next frame
            // Dimmed background overlay
            // Set batch color to black with 0.8 opacity
            game.batch.setColor(0, 0, 0, 0.8f);

            // Stretch the 1x1 pixel across the entire screen
            game.batch.draw(pixelTexture, 0, 0, viewport.getWorldWidth(), viewport.getWorldHeight());

            // Reset batch color back to white, so future texture won't be dark
            game.batch.setColor(Color.WHITE);

            // Draw PAUSED text in the middle
            font.setColor(Color.WHITE);
            font.getData().setScale(1.0f);
            font.draw(game.batch, "PAUSED - Press ESC to Resume", 0, viewport.getWorldHeight() / 2 + 100, viewport.getWorldWidth(), Align.center, false);
            font.draw(game.batch, "> restart", 0, viewport.getWorldHeight() / 2 +30, viewport.getWorldWidth(), Align.center, false);
            font.draw(game.batch, "> menu", 0, viewport.getWorldHeight() / 2 - 10, viewport.getWorldWidth(), Align.center, false);
            font.draw(game.batch, "> quit", 0, viewport.getWorldHeight() / 2 - 50, viewport.getWorldWidth(), Align.center, false);

            // Draw interactive "Typing: " feedback
            if (shakeTimer > 0) {
                font.setColor(Color.RED);
            } else {
                font.setColor(Color.GREEN);
            }

            font.getData().setScale(popScale);

            font.draw(game.batch, "Typing: " + pauseTyped, shakeOffsetX, viewport.getWorldHeight() / 2 - 150, viewport.getWorldWidth(), Align.center, false);
        } else if (gameController.getGameState() == GameController.GameState.GAME_OVER) { // 3. If game is over
            game.setScreen(new GameOverScreen(game, gameController.getIsGameWon(), gameController.getScore(), this.targetLength));
            dispose();
        }

        // LERP the Scale
        // Shrinks back to normal scale smoothly
        popScale = MathUtils.lerp(popScale, 1.0f, delta * 15f); // Back to normal 1.0f scale, 'delta * 15f' means speed, higher value faster speed
        font.getData().setScale(popScale); // Apply scale to the font

        game.batch.end();
    }

    // Dispose the font created (release memory)
    @Override
    public void dispose() {
        font.dispose();
    }

    // Player resize the window
    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true); // true tells the camera to center the screens
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

}

