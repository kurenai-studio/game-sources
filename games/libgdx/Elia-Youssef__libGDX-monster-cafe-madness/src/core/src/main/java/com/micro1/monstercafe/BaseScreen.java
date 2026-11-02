package com.micro1.monstercafe;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.math.Vector3;

/**
 * Common scaffolding shared by the four screens: the {@link MonsterCafeGame} reference, viewport-aware
 * pointer unprojection, centered-text helpers, and aspect-preserving region drawing. Each concrete screen
 * supplies its own {@code render()} (drawing + input polling). Extending {@link ScreenAdapter} stubs the
 * lifecycle methods a screen does not need; screens own no disposable resources (all heavy resources live on
 * the game), so transitions never leak.
 */
public abstract class BaseScreen extends ScreenAdapter {

    protected final MonsterCafeGame game;
    private final Vector3 tmp = new Vector3();

    protected BaseScreen(MonsterCafeGame game) {
        this.game = game;
    }

    /** The current pointer position in world coordinates (y-up), mapped through the viewport. */
    protected Vector2 worldTouch(Vector2 out) {
        tmp.set(Gdx.input.getX(), Gdx.input.getY(), 0);
        game.viewport.unproject(tmp);
        return out.set(tmp.x, tmp.y);
    }

    /** Draw text horizontally centered on cx, baseline at y, in the given color (font color reset to white). */
    protected void drawCentered(BitmapFont font, String text, float cx, float y, Color color) {
        font.setColor(color);
        game.layout.setText(font, text);
        font.draw(game.batch, game.layout, cx - game.layout.width / 2f, y);
        font.setColor(Color.WHITE);
    }

    /** Draw text centered on (cx, cy) both horizontally and vertically, in the given color. */
    protected void drawCenteredBoth(BitmapFont font, String text, float cx, float cy, Color color) {
        font.setColor(color);
        game.layout.setText(font, text);
        font.draw(game.batch, game.layout, cx - game.layout.width / 2f, cy + game.layout.height / 2f);
        font.setColor(Color.WHITE);
    }

    /** Draw a region centered on (cx, cy) at width w, height derived from the region's aspect ratio. */
    protected void drawRegionByWidth(TextureRegion r, float cx, float cy, float w) {
        float h = w * r.getRegionHeight() / (float) r.getRegionWidth();
        game.batch.draw(r, cx - w / 2f, cy - h / 2f, w, h);
    }

    /** Draw a region centered on (cx, cy) at height h, width derived from the region's aspect ratio. */
    protected void drawRegionByHeight(TextureRegion r, float cx, float cy, float h) {
        float w = h * r.getRegionWidth() / (float) r.getRegionHeight();
        game.batch.draw(r, cx - w / 2f, cy - h / 2f, w, h);
    }

    @Override
    public void resize(int width, int height) {
        game.viewport.update(width, height, true);
    }
}
