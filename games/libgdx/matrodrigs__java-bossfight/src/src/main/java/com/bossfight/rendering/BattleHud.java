package com.bossfight.rendering;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Disposable;
import com.bossfight.config.Constants;
import com.bossfight.entities.Player;

public final class BattleHud implements Disposable {
    private static final float PLAYER_HUD_X = 34f;
    private static final float PLAYER_HUD_Y = 24f;
    private static final float HP_BOX_WIDTH = 106f;
    private static final float HP_BOX_HEIGHT = 58f;
    private static final float HP_TEXT_PADDING_X = 11f;
    private static final float HP_TEXT_PADDING_Y = 8f;
    private static final float PLAYER_HUD_GAP = 3f;
    private static final float SPECIAL_CLOCK_SIZE = 70f;
    private static final float SPECIAL_CLOCK_X = PLAYER_HUD_X + HP_BOX_WIDTH + PLAYER_HUD_GAP;
    private static final float SPECIAL_CLOCK_Y = PLAYER_HUD_Y + (HP_BOX_HEIGHT - SPECIAL_CLOCK_SIZE) * 0.5f;

    private final Texture[] hpTexts;
    private final Texture hpBoxTexture;
    private final Texture specialClockTexture;
    private final TextureRegion specialClockFillRegion;

    public BattleHud(RetroTextFactory textFactory) {
        hpBoxTexture = TextureLoader.loadLinear("sprites/ui/player_hp_box.png");
        specialClockTexture = TextureLoader.loadLinear("sprites/ui/special_clock.png");
        specialClockFillRegion = new TextureRegion(specialClockTexture);
        hpTexts = new Texture[Constants.PLAYER_MAX_HEALTH + 1];
        for (int i = 0; i < hpTexts.length; i++) {
            hpTexts[i] = textFactory.createPlayerHealthHud(i);
        }
    }

    public void render(SpriteBatch batch, Player player, float elapsed) {
        batch.draw(hpBoxTexture, PLAYER_HUD_X, PLAYER_HUD_Y, HP_BOX_WIDTH, HP_BOX_HEIGHT);
        drawPlayerHealthText(batch, player);
        drawSpecialClock(batch, player, elapsed);
    }

    @Override
    public void dispose() {
        hpBoxTexture.dispose();
        specialClockTexture.dispose();
    }

    private void drawPlayerHealthText(SpriteBatch batch, Player player) {
        int healthIndex = MathUtils.clamp(player.getHealth(), 0, hpTexts.length - 1);
        drawTextureInBox(batch, hpTexts[healthIndex],
                PLAYER_HUD_X + HP_TEXT_PADDING_X,
                PLAYER_HUD_Y + HP_TEXT_PADDING_Y,
                HP_BOX_WIDTH - HP_TEXT_PADDING_X * 2f,
                HP_BOX_HEIGHT - HP_TEXT_PADDING_Y * 2f);
    }

    private void drawSpecialClock(SpriteBatch batch, Player player, float elapsed) {
        if (player.isSpecialReady()) {
            drawReadySpecialClock(batch, elapsed);
            return;
        }

        float percent = MathUtils.clamp(player.getSpecialEnergyPercent(), 0f, 1f);
        batch.setColor(0.28f, 0.25f, 0.2f, 0.48f);
        batch.draw(specialClockTexture, SPECIAL_CLOCK_X, SPECIAL_CLOCK_Y,
                SPECIAL_CLOCK_SIZE, SPECIAL_CLOCK_SIZE);

        if (percent > 0.01f) {
            int sourceHeight = Math.max(1, Math.round(specialClockTexture.getHeight() * percent));
            int sourceY = specialClockTexture.getHeight() - sourceHeight;
            float fillHeight = SPECIAL_CLOCK_SIZE * sourceHeight / specialClockTexture.getHeight();
            specialClockFillRegion.setRegion(0, sourceY, specialClockTexture.getWidth(), sourceHeight);
            batch.setColor(1f, 1f, 1f, 0.96f);
            batch.draw(specialClockFillRegion, SPECIAL_CLOCK_X, SPECIAL_CLOCK_Y,
                    SPECIAL_CLOCK_SIZE, fillHeight);
        }
        batch.setColor(Color.WHITE);
    }

    private void drawReadySpecialClock(SpriteBatch batch, float elapsed) {
        float bob = MathUtils.sin(elapsed * 10f) * 3.4f;
        float rotation = MathUtils.sin(elapsed * 13f) * 6.5f;
        float scale = 1f + MathUtils.sin(elapsed * 16f) * 0.045f;
        float size = SPECIAL_CLOCK_SIZE * scale;
        float x = SPECIAL_CLOCK_X + (SPECIAL_CLOCK_SIZE - size) * 0.5f;
        float y = SPECIAL_CLOCK_Y + (SPECIAL_CLOCK_SIZE - size) * 0.5f + bob;

        batch.setColor(0.02f, 0.015f, 0.01f, 0.32f);
        drawClockTexture(batch, x + 3f, y - 4f, size, rotation);
        batch.setColor(Color.WHITE);
        drawClockTexture(batch, x, y, size, rotation);
    }

    private void drawClockTexture(SpriteBatch batch, float x, float y, float size, float rotation) {
        batch.draw(specialClockTexture,
                x, y,
                size * 0.5f, size * 0.5f,
                size, size,
                1f, 1f,
                rotation,
                0, 0,
                specialClockTexture.getWidth(), specialClockTexture.getHeight(),
                false, false);
    }

    private void drawTextureInBox(SpriteBatch batch, Texture texture,
                                  float x, float y, float width, float height) {
        float scale = Math.min(width / texture.getWidth(), height / texture.getHeight());
        float drawWidth = texture.getWidth() * scale;
        float drawHeight = texture.getHeight() * scale;
        batch.draw(texture,
                x + (width - drawWidth) * 0.5f,
                y + (height - drawHeight) * 0.5f,
                drawWidth, drawHeight);
    }
}
