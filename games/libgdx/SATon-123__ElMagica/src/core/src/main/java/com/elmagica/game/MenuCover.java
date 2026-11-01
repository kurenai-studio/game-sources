package com.elmagica.game;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

public class MenuCover {
    private final Texture picture = new Texture(Gdx.files.internal("ui/menu/cover.png"));
    private final ShapeRenderer shapes;
    private final SpriteBatch batch;
    private final BitmapFont font;
    private final Color gold = new Color(0.88f, 0.65f, 0.32f, 1);
    private final Color ink = new Color(0.035f, 0.025f, 0.07f, 1);
    private final Color ivory = new Color(1, 0.91f, 0.70f, 1);

    public MenuCover(ShapeRenderer shapes, SpriteBatch batch, BitmapFont font) {
        this.shapes = shapes;
        this.batch = batch;
        this.font = font;
        picture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
    }

    public void drawBackground() {
        // Подгоняем фон, координаты кнопок не трогаем.
        float scale = Math.max(1280f / picture.getWidth(), 720f / picture.getHeight());
        float width = picture.getWidth() * scale;
        float height = picture.getHeight() * scale;
        batch.begin();
        batch.setColor(Color.WHITE);
        batch.draw(picture, (1280 - width) / 2, (720 - height) / 2, width, height);
        batch.end();
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        // Приглушаем фон под кнопками, чтобы они не терялись.
        shapes.setColor(0.025f, 0.02f, 0.055f, 0.52f);
        shapes.rect(458, 102, 364, 418);
        shapes.setColor(0.025f, 0.02f, 0.055f, 0.7f);
        shapes.rect(0, 0, 1280, 62);
        shapes.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);
    }

    public void drawTitle() {
        batch.begin();
        // Обводка спасает название на пёстром фоне.
        for (int x = -4; x <= 4; x += 4) {
            for (int y = -4; y <= 4; y += 4) text("ElMagica", 640 + x, 642 + y, 9, ink);
        }
        text("ElMagica", 640, 638, 9, gold);
        text("ElMagica", 640, 644, 9, ivory);
        text("Арена стихий", 642, 555, 2, ink);
        text("Арена стихий", 640, 557, 2, ivory);
        text(ElMagicaGame.VERSION_LABEL, 640, 48, 1, ivory);
        text(ElMagicaGame.AUTHOR_LABEL, 640, 32, 1, ivory);
        text(ElMagicaGame.THANKS_LABEL, 640, 16, 1, ivory);
        batch.end();
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(gold);
        shapes.rect(481, 535, 120, 2);
        shapes.rect(679, 535, 120, 2);
        for (int i = 0; i < 4; i++) {
            shapes.setColor(DamageSystem.PLAYER_ELEMENTS[i].color);
            shapes.rect(614 + i * 15, 532, 7, 7);
        }
        shapes.end();
    }

    public void drawNeutralBackground() {
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(0.035f, 0.025f, 0.065f, 1);
        shapes.rect(0, 0, 1280, 720);
        for (int x = 32; x < 1280; x += 64) {
            for (int y = 32; y < 704; y += 64) {
                shapes.setColor(0.075f, 0.055f, 0.105f, 1);
                shapes.rect(x - 1, y - 7, 2, 14);
                shapes.rect(x - 7, y - 1, 14, 2);
            }
        }
        shapes.setColor(gold);
        shapes.rect(24, 24, 1232, 2);
        shapes.rect(24, 694, 1232, 2);
        shapes.rect(24, 24, 2, 672);
        shapes.rect(1254, 24, 2, 672);
        shapes.end();
    }

    // Вызывать между shapes.begin() и shapes.end().
    public void panel(float x, float y, float width, float height) {
        panel(x, y, width, height, 1);
    }

    public void panel(float x, float y, float width, float height, float alpha) {
        shapes.setColor(ink.r, ink.g, ink.b, alpha);
        shapes.rect(x - 4, y - 6, width + 8, 6);
        shapes.rect(x + width, y, 4, height + 2);
        shapes.setColor(gold.r, gold.g, gold.b, alpha);
        shapes.rect(x, y, width, 2);
        shapes.rect(x, y + height - 2, width, 2);
        shapes.rect(x, y + 2, 2, height - 4);
        shapes.rect(x + width - 2, y + 2, 2, height - 4);
        shapes.setColor(0.075f, 0.06f, 0.12f, alpha);
        shapes.rect(x + 2, y + 2, width - 4, height - 4);
        shapes.setColor(0.24f, 0.18f, 0.29f, alpha);
        shapes.rect(x + 8, y + height - 8, width - 16, 2);
    }

    public void heading(String label, float y) {
        batch.begin();
        text(label, 642, y - 3, 4, ink);
        text(label, 640, y, 4, ivory);
        batch.end();
    }

    public void drawButton(String label, float x, float y, float width, float height,
                           boolean primary, boolean hover) {
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(ink);
        shapes.rect(x - 4, y - 6, width + 8, height + 8);
        shapes.setColor(hover ? ivory : gold);
        shapes.rect(x, y, width, height);
        shapes.setColor(primary ? new Color(0.43f, 0.18f, 0.09f, 1) : new Color(0.10f, 0.09f, 0.18f, 1));
        if (hover) shapes.setColor(primary ? new Color(0.62f, 0.28f, 0.10f, 1) : new Color(0.18f, 0.17f, 0.29f, 1));
        shapes.rect(x + 3, y + 3, width - 6, height - 6);
        shapes.setColor(primary ? gold : new Color(0.32f, 0.27f, 0.40f, 1));
        shapes.rect(x + 6, y + height - 7, width - 12, 2);
        shapes.setColor(ink);
        shapes.rect(x + 6, y + 5, width - 12, 3);
        shapes.setColor(hover ? ivory : gold);
        float middle = y + height / 2;
        shapes.triangle(x + 15, middle, x + 21, middle + 6, x + 27, middle);
        shapes.triangle(x + 15, middle, x + 21, middle - 6, x + 27, middle);
        shapes.triangle(x + width - 27, middle, x + width - 21, middle + 6, x + width - 15, middle);
        shapes.triangle(x + width - 27, middle, x + width - 21, middle - 6, x + width - 15, middle);
        shapes.end();
        batch.begin();
        text(label, x + width / 2 + 2, middle + 5, 2, ink);
        text(label, x + width / 2, middle + 7, 2, ivory);
        batch.end();
    }

    private void text(String label, float center, float y, int scale, Color color) {
        label = GameText.tr(label);
        font.getData().setScale(scale);
        font.setColor(color);
        font.draw(batch, label, center - (label.length() * 6 - 1) * scale / 2f, y);
    }

    public void dispose() {
        picture.dispose();
    }
}
