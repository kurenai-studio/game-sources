package com.micro1.minecart;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.ScreenUtils;

/**
 * Title screen: centered white MINE CART (64px) and a clickable white START (24px). Clicking
 * START switches immediately to the gameplay screen.
 */
public class TitleScreen extends ScreenAdapter {

    private static final Color BACKGROUND = new Color(0.06f, 0.07f, 0.09f, 1f);

    private final MineCartGame game;
    private final Rectangle startButton = new Rectangle();
    private final Vector3 touch = new Vector3();

    public TitleScreen(MineCartGame game) {
        this.game = game;
    }

    @Override
    public void render(float delta) {
        game.centeredBounds("START", 24f, 640f, 430f, 30f, 18f, startButton);

        if (Gdx.input.justTouched()) {
            game.camera.unproject(touch.set(Gdx.input.getX(), Gdx.input.getY(), 0f));
            if (startButton.contains(touch.x, touch.y)) {
                game.setScreen(new GameplayScreen(game));
                return;
            }
        }

        ScreenUtils.clear(BACKGROUND);
        game.batch.setProjectionMatrix(game.camera.combined);
        game.batch.begin();
        game.drawCentered("MINE CART", 64f, 640f, 300f, Color.WHITE);
        game.drawCentered("START", 24f, 640f, 430f, Color.WHITE);
        game.batch.end();
    }
}
