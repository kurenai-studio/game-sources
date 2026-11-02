package com.micro1.monstercafe;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.ScreenUtils;

/**
 * The Main Menu: the supplied {@code menu_background.png}, the dynamic "Monster Café Madness" title text, and
 * the supplied {@code play_button.png}. Clicking Play goes straight to Gameplay. No gameplay systems run here
 * (there is no {@link CafeSession} on this screen at all).
 */
public class MainMenuScreen extends BaseScreen {

    private static final Color TITLE_GOLD = new Color(0.99f, 0.82f, 0.25f, 1f);
    private static final Color TITLE_SHADOW = new Color(0.12f, 0.05f, 0.16f, 1f);

    private final SpriteButton playButton;
    private final Vector2 touch = new Vector2();

    public MainMenuScreen(MonsterCafeGame game) {
        super(game);
        playButton = new SpriteButton(game.assets.playButton).setCentered(430f, 330f, 320f, 225f);
    }

    @Override
    public void render(float delta) {
        if (Gdx.input.justTouched()) {
            worldTouch(touch);
            if (playButton.contains(touch.x, touch.y)) {
                game.setScreen(new GameplayScreen(game));
                return;
            }
        }

        ScreenUtils.clear(0f, 0f, 0f, 1f);
        game.viewport.apply();
        game.batch.setProjectionMatrix(game.viewport.getCamera().combined);
        game.batch.begin();
        game.batch.draw(game.assets.menuBackground, 0f, 0f,
                MonsterCafeGame.WORLD_WIDTH, MonsterCafeGame.WORLD_HEIGHT);
        // Title with a soft drop shadow for readability over the busy art.
        drawCentered(game.titleFont, "Monster Café", 434f, 676f, TITLE_SHADOW);
        drawCentered(game.titleFont, "Monster Café", 430f, 680f, TITLE_GOLD);
        drawCentered(game.titleFont, "Madness", 434f, 616f, TITLE_SHADOW);
        drawCentered(game.titleFont, "Madness", 430f, 620f, TITLE_GOLD);
        playButton.draw(game.batch);
        game.batch.end();
    }
}
