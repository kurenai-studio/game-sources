package com.micro1.leap;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.glutils.HdpiUtils;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;

/**
 * Entry screen: the LEAP title on a dark background and a clickable START button.
 * Drawn in plain 800x600 screen space. Movement and jump keys do nothing here;
 * gameplay only begins once START opens the GameScreen.
 */
public class TitleScreen implements Screen {

    private static final Color BG = Color.valueOf("061426");
    private static final Color BUTTON = Color.valueOf("333333");

    private final LeapGame game;
    private final OrthographicCamera cam = new OrthographicCamera();
    // START button centered at (400, 260), size 180x50.
    private final Rectangle startButton = new Rectangle(400f - 90f, 260f - 25f, 180f, 50f);

    public TitleScreen(LeapGame game) {
        this.game = game;
        cam.setToOrtho(false, 800f, 600f);
    }

    @Override
    public void show() {}

    @Override
    public void render(float delta) {
        // Click START -> game screen, immediately. Only mouse clicks act here.
        if (Gdx.input.justTouched()) {
            float x = Gdx.input.getX();
            float y = 600f - Gdx.input.getY();      // screen y-down -> world y-up
            if (startButton.contains(x, y)) {
                game.setScreen(new GameScreen(game));
                return;
            }
        }

        HdpiUtils.glViewport(0, 0, 800, 600);
        Gdx.gl.glClearColor(BG.r, BG.g, BG.b, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        cam.update();
        ShapeRenderer shapes = game.shapes;
        shapes.setProjectionMatrix(cam.combined);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(BUTTON);
        shapes.rect(startButton.x, startButton.y, startButton.width, startButton.height);
        shapes.end();

        game.batch.setProjectionMatrix(cam.combined);
        game.batch.begin();
        Ui.drawCentered(game.batch, game.font, "LEAP", 400f, 360f, 50f, Color.WHITE);
        Ui.drawCentered(game.batch, game.font, "START",
                startButton.x + startButton.width / 2f,
                startButton.y + startButton.height / 2f, 22f, Color.WHITE);
        game.batch.end();
    }

    @Override public void resize(int width, int height) {}
    @Override public void pause() {}
    @Override public void resume() {}
    @Override public void hide() {}
    @Override public void dispose() {}
}
