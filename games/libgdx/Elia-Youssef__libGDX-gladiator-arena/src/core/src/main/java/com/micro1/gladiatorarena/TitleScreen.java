package com.micro1.gladiatorarena;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.ScreenUtils;

/**
 * Title screen: centered white GLADIATOR ARENA (64px) and a clickable, outlined START (24px).
 * Clicking START switches immediately to the gameplay screen.
 */
public class TitleScreen extends ScreenAdapter {

    private static final Color BACKGROUND = new Color(0f, 0f, 0f, 1f);
    private static final Color BORDER = new Color(0.72f, 0.72f, 0.75f, 1f);

    private final GladiatorArenaGame game;
    private final Rectangle startButton = new Rectangle();
    private final Vector3 touch = new Vector3();

    public TitleScreen(GladiatorArenaGame game) {
        this.game = game;
    }

    @Override
    public void render(float delta) {
        game.centeredBounds("START", 24f, 640f, 430f, 28f, 16f, startButton);

        if (Gdx.input.justTouched()) {
            game.camera.unproject(touch.set(Gdx.input.getX(), Gdx.input.getY(), 0f));
            if (startButton.contains(touch.x, touch.y)) {
                game.setScreen(new GameplayScreen(game));
                return;
            }
        }

        ScreenUtils.clear(BACKGROUND);

        game.shapes.setProjectionMatrix(game.camera.combined);
        game.shapes.begin(ShapeRenderer.ShapeType.Filled);
        game.shapes.setColor(BORDER);
        game.shapes.rect(startButton.x, startButton.y, startButton.width, startButton.height);
        game.shapes.setColor(BACKGROUND);
        game.shapes.rect(startButton.x + 2f, startButton.y + 2f, startButton.width - 4f, startButton.height - 4f);
        game.shapes.end();

        game.batch.setProjectionMatrix(game.camera.combined);
        game.batch.begin();
        game.drawCentered("GLADIATOR ARENA", 64f, 640f, 280f, Color.WHITE);
        game.drawCentered("START", 24f, 640f, 430f, Color.WHITE);
        game.batch.end();
    }
}
