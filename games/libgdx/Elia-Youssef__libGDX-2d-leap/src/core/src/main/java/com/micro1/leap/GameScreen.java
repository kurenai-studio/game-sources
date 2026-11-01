package com.micro1.leap;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.glutils.HdpiUtils;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;

/**
 * Gameplay screen. Renders in two passes with a GL viewport split:
 *   - World pass: the bottom 800x560 of the window is the scrolling play field,
 *     drawn with a world camera that scrolls only in x (world y=0..560 maps 1:1
 *     to the bottom 560px, so there is no vertical scroll or stretch).
 *   - HUD/overlay pass: the full 800x600 window with a fixed screen camera draws
 *     the top 40px HUD strip and (when won) the win overlay, so both stay locked
 *     to the screen during scrolling, fall resets and the win state.
 * All gameplay logic lives in {@link World}; this class only samples input and draws.
 */
public class GameScreen implements Screen {

    private static final Color PLAYFIELD_BG = Color.valueOf("061426");
    private static final Color PLATFORM = Color.valueOf("8b5a2b");
    private static final Color PLAYER = Color.valueOf("00cc00");
    private static final Color GOAL = Color.valueOf("ffff00");
    private static final Color HUD = Color.valueOf("333333");

    private static final int HUD_HEIGHT = 40;
    private static final int FIELD_HEIGHT = 560;
    private static final int WINDOW_W = 800;
    private static final int WINDOW_H = 600;

    private final LeapGame game;
    private final World world = new World();

    private final OrthographicCamera worldCam = new OrthographicCamera();
    private final OrthographicCamera screenCam = new OrthographicCamera();

    // PLAY AGAIN button, screen-space, in the 800x560 play field, centered at (400, 230),
    // directly below the YOU WIN message (which sits at the play-field center).
    private final Rectangle playAgain = new Rectangle(400f - 110f, 230f - 25f, 220f, 50f);

    private boolean jumpWasDown = false;

    public GameScreen(LeapGame game) {
        this.game = game;
        worldCam.setToOrtho(false, WINDOW_W, FIELD_HEIGHT);
        screenCam.setToOrtho(false, WINDOW_W, WINDOW_H);
    }

    @Override
    public void show() {
        // Seed the jump edge-tracker so a jump key already held while clicking
        // START is not treated as a fresh press on the first gameplay frame.
        jumpWasDown = isJumpDown();
    }

    @Override
    public void render(float delta) {
        handleInput(delta);
        draw();
    }

    private void handleInput(float delta) {
        if (world.state == World.State.WON) {
            // Only the PLAY AGAIN click acts; movement/jump keys are ignored.
            if (Gdx.input.justTouched()) {
                float x = Gdx.input.getX();
                float y = WINDOW_H - Gdx.input.getY();
                if (playAgain.contains(x, y)) {
                    world.playAgain();
                }
            }
            jumpWasDown = isJumpDown();
            return;
        }

        boolean left = Gdx.input.isKeyPressed(Input.Keys.LEFT) || Gdx.input.isKeyPressed(Input.Keys.A);
        boolean right = Gdx.input.isKeyPressed(Input.Keys.RIGHT) || Gdx.input.isKeyPressed(Input.Keys.D);
        boolean jumpDown = isJumpDown();
        boolean jumpPressed = jumpDown && !jumpWasDown;   // edge trigger: one jump per press
        jumpWasDown = jumpDown;

        world.update(delta, left, right, jumpPressed);
    }

    private boolean isJumpDown() {
        return Gdx.input.isKeyPressed(Input.Keys.SPACE) || Gdx.input.isKeyPressed(Input.Keys.UP);
    }

    private void draw() {
        Gdx.gl.glClearColor(PLAYFIELD_BG.r, PLAYFIELD_BG.g, PLAYFIELD_BG.b, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        // ---- World pass: bottom 800x560 viewport, horizontally scrolling camera ----
        // HdpiUtils maps these logical sizes to physical backbuffer pixels, so the
        // split stays correct under any OS display scaling (not just 100%).
        HdpiUtils.glViewport(0, 0, WINDOW_W, FIELD_HEIGHT);
        worldCam.position.set(world.cameraX, FIELD_HEIGHT / 2f, 0f);
        worldCam.update();
        ShapeRenderer shapes = game.shapes;
        shapes.setProjectionMatrix(worldCam.combined);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(PLATFORM);
        for (Rectangle p : world.level.platforms) {
            shapes.rect(p.x, p.y, p.width, p.height);
        }
        shapes.setColor(GOAL);
        Rectangle g = world.level.goal;
        shapes.rect(g.x, g.y, g.width, g.height);
        shapes.setColor(PLAYER);
        shapes.rect(world.player.x, world.player.y, World.PLAYER_W, World.PLAYER_H);
        shapes.end();

        // ---- HUD + overlay pass: full 800x600 viewport, fixed screen camera ----
        HdpiUtils.glViewport(0, 0, WINDOW_W, WINDOW_H);
        screenCam.update();
        shapes.setProjectionMatrix(screenCam.combined);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(HUD);
        shapes.rect(0f, WINDOW_H - HUD_HEIGHT, WINDOW_W, HUD_HEIGHT);
        if (world.state == World.State.WON) {
            shapes.setColor(HUD); // same dark grey #333333 for the button
            shapes.rect(playAgain.x, playAgain.y, playAgain.width, playAgain.height);
        }
        shapes.end();

        game.batch.setProjectionMatrix(screenCam.combined);
        game.batch.begin();
        Ui.drawCentered(game.batch, game.font, "LEAP", 400f, WINDOW_H - HUD_HEIGHT / 2f, 28f, Color.WHITE);
        if (world.state == World.State.WON) {
            Ui.drawCentered(game.batch, game.font, "YOU WIN", 400f, 300f, 48f, Color.WHITE);
            Ui.drawCentered(game.batch, game.font, "PLAY AGAIN",
                    playAgain.x + playAgain.width / 2f,
                    playAgain.y + playAgain.height / 2f, 22f, Color.WHITE);
        }
        game.batch.end();
    }

    @Override public void resize(int width, int height) {}
    @Override public void pause() {}
    @Override public void resume() {}
    @Override public void hide() {}
    @Override public void dispose() {}
}
