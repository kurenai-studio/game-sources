package com.micro1.monstercafe;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.ScreenUtils;

/**
 * The Victory screen, shown when the score reaches 100. Clearly communicates success and offers two actions:
 * Play Again (a fresh gameplay session) and Main Menu. No gameplay runs here.
 */
public class VictoryScreen extends BaseScreen {

    private static final Color GOLD = new Color(0.99f, 0.82f, 0.25f, 1f);
    private static final Color SHADOW = new Color(0.10f, 0.05f, 0.14f, 1f);
    private static final Color GREEN = new Color(0.30f, 0.68f, 0.22f, 1f);
    private static final Color PURPLE = new Color(0.46f, 0.33f, 0.70f, 1f);

    private final int finalScore;
    private final MenuButton playAgain;
    private final MenuButton mainMenu;
    private final Vector2 touch = new Vector2();

    public VictoryScreen(MonsterCafeGame game, int finalScore) {
        super(game);
        this.finalScore = finalScore;
        playAgain = new MenuButton("PLAY AGAIN", GREEN, 470f, 240f, 264f, 78f);
        mainMenu = new MenuButton("MAIN MENU", PURPLE, 810f, 240f, 264f, 78f);
    }

    @Override
    public void render(float delta) {
        if (Gdx.input.justTouched()) {
            worldTouch(touch);
            if (playAgain.contains(touch.x, touch.y)) {
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

        // Dim the backdrop so the result text pops, and draw the two button fills.
        Gdx.gl.glEnable(GL20.GL_BLEND);
        game.shapes.begin(ShapeType.Filled);
        game.shapes.setColor(0f, 0f, 0f, 0.55f);
        game.shapes.rect(0f, 0f, MonsterCafeGame.WORLD_WIDTH, MonsterCafeGame.WORLD_HEIGHT);
        playAgain.drawFill(game.shapes);
        mainMenu.drawFill(game.shapes);
        game.shapes.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);

        game.batch.begin();
        drawCentered(game.titleFont, "VICTORY!", 643f, 561f, SHADOW);
        drawCentered(game.titleFont, "VICTORY!", 640f, 565f, GOLD);
        drawCentered(game.msgFont, "You served the monsters like a pro!", 640f, 492f, Color.WHITE);
        drawCentered(game.msgFont, "Final Score: " + finalScore, 640f, 440f, GOLD);
        drawCenteredBoth(game.msgFont, playAgain.caption, playAgain.centerX(), playAgain.centerY(), Color.WHITE);
        drawCenteredBoth(game.msgFont, mainMenu.caption, mainMenu.centerX(), mainMenu.centerY(), Color.WHITE);
        game.batch.end();
    }
}
