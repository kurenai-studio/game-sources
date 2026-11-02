package com.bossfight.rendering;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

public final class TextureDraw {
    private TextureDraw() {
    }

    public static void centered(SpriteBatch batch, Texture texture, float centerX, float centerY, float scale) {
        float width = texture.getWidth() * scale;
        float height = texture.getHeight() * scale;
        batch.draw(texture, centerX - width * 0.5f, centerY - height * 0.5f, width, height);
    }

    public static void centeredWithin(SpriteBatch batch, Texture texture, float centerX, float centerY, float scale,
                                      float maxWidth) {
        float width = texture.getWidth() * scale;
        if (width > maxWidth) {
            scale *= maxWidth / width;
            width = texture.getWidth() * scale;
        }

        float height = texture.getHeight() * scale;
        batch.draw(texture, centerX - width * 0.5f, centerY - height * 0.5f, width, height);
    }

    public static void centeredAnimated(SpriteBatch batch, Texture texture, float centerX, float centerY, float scale,
                                        float xOffset, float rotation, float alpha) {
        float width = texture.getWidth() * scale;
        float height = texture.getHeight() * scale;
        float x = centerX - width * 0.5f + xOffset;
        float y = centerY - height * 0.5f;
        batch.setColor(1f, 1f, 1f, alpha);
        batch.draw(texture,
                x,
                y,
                width * 0.5f,
                height * 0.5f,
                width,
                height,
                1f,
                1f,
                rotation,
                0,
                0,
                texture.getWidth(),
                texture.getHeight(),
                false,
                false);
        batch.setColor(Color.WHITE);
    }

    public static void atCenterY(SpriteBatch batch, Texture texture, float x, float centerY, float scale) {
        float width = texture.getWidth() * scale;
        float height = texture.getHeight() * scale;
        batch.draw(texture, x, centerY - height * 0.5f, width, height);
    }
}
