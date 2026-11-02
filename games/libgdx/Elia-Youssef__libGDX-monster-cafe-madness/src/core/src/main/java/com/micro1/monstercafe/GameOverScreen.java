package com.micro1.monstercafe;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.ScreenUtils;

/**
 * The Game Over screen, shown when happiness reaches zero. Displays a clear failure message, the final score,
 * and the supplied {@code retry_button.png}. Retry starts a brand-new gameplay session in the same process;
 * Main Menu returns to the menu. No gameplay runs here.
 */
public class GameOverScreen extends BaseScreen {

    private static final Color RED = new Color(0.90f, 0.26f, 0.18f, 1f);
    private static final Color SHADOW = new Color(0.10f, 0.05f, 0.14f, 1f);
    private static final Color PURPLE = new Color(0.46f, 0.33f, 0.70f, 1f);

    private final int finalScore;
    private final SpriteButton retryButton;
    private final MenuButton mainMenu;
    private final Vector2 touch = new Vector2();

    public GameOverScreen(MonsterCafeGame game, int finalScore) {
        super(game);
        this.finalScore = finalScore;
        retryButton = new SpriteButton(game.assets.retryButton).setCenteredByHeight(515f, 235f, 140f);
        mainMenu = new MenuButton("MAIN MENU", PURPLE, 825f, 235f, 258f, 76f);
    }

    @Override
    public void render(float delta) {
        if (Gdx.input.justTouched()) {
            worldTouch(touch);
            if (retryButton.contains(touch.x, touch.y)) {
                game.setScreen(new GameplayScreen(game));
                return;
            }
            if (mainMenu.contains(touch.x, touch.y)) {
                game.setScreen(new MainMenuScreen(game));
                return;
            }
        }

        ScreenUtils.clear(0f, 0f, 0f, 1f);
        game.viewport.apply();
        game.batch.setProjectionMatrix(game.viewport.getCamera().combined);
        game.shapes.setProjectionMatrix(game.viewport.getCamera().combined);

        game.batch.begin();
        game.batch.draw(game.assets.menuBackground, 0f, 0f,
                MonsterCafeGame.WORLD_WIDTH, MonsterCafeGame.WORLD_HEIGHT);
        game.batch.end();

        Gdx.gl.glEnable(GL20.GL_BLEND);
        game.shapes.begin(ShapeType.Filled);
        game.shapes.setColor(0f, 0f, 0f, 0.6f);
        game.shapes.rect(0f, 0f, MonsterCafeGame.WORLD_WIDTH, MonsterCafeGame.WORLD_HEIGHT);
        mainMenu.drawFill(game.shapes);
        game.shapes.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);

        game.batch.begin();
        drawCentered(game.titleFont, "GAME OVER", 643f, 561f, SHADOW);
        drawCentered(game.titleFont, "GAME OVER", 640f, 565f, RED);
        drawCentered(game.msgFont, "The monsters left angry...", 640f, 492f, Color.WHITE);
        drawCentered(game.msgFont, "Final Score: " + finalScore, 640f, 440f, Color.WHITE);
        retryButton.draw(game.batch);
        drawCenteredBoth(game.msgFont, mainMenu.caption, mainMenu.centerX(), mainMenu.centerY(), Color.WHITE);
        game.batch.end();
    }
}
