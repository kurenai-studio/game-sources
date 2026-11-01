package dev.luchoc.littlespaceship.game.adapter.render;

import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

/**
 * The distortion probe from {@code spikes/web-viability}: a repeating checkerboard drawn across the
 * playfield. Any fractional scale or filtering mistake shows up as a shimmer or a blurred edge
 * instantly, which is a much faster signal than measuring pixel colours by hand.
 *
 * <p>Kept out of {@link PlaceholderAtlas} on purpose: tiling it needs {@code Repeat} texture
 * wrapping, which would repeat the whole atlas — bleeding into the ship's region — if this shared
 * that texture. It is a diagnostic backdrop, not a drawable entity, so it never goes through
 * {@link dev.luchoc.littlespaceship.core.port.WorldView}.
 */
public final class CheckerboardBackground {

    private static final int TILE_SIZE = 8;
    private static final int CHECKER_DARK = 0x14141EFF;
    private static final int CHECKER_LIGHT = 0x2A2A3AFF;

    private final Texture texture;

    public CheckerboardBackground() {
        Pixmap pixmap = new Pixmap(TILE_SIZE, TILE_SIZE, Pixmap.Format.RGBA8888);
        for (int y = 0; y < TILE_SIZE; y++) {
            for (int x = 0; x < TILE_SIZE; x++) {
                boolean on = ((x + y) & 1) == 0;
                setColor(pixmap, on ? CHECKER_LIGHT : CHECKER_DARK);
                pixmap.drawPixel(x, y);
            }
        }
        texture = new Texture(pixmap);
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        texture.setWrap(Texture.TextureWrap.Repeat, Texture.TextureWrap.Repeat);
        pixmap.dispose();
    }

    private static void setColor(Pixmap pixmap, int rgba8888) {
        pixmap.setColor(
            ((rgba8888 >>> 24) & 0xFF) / 255f,
            ((rgba8888 >>> 16) & 0xFF) / 255f,
            ((rgba8888 >>> 8) & 0xFF) / 255f,
            (rgba8888 & 0xFF) / 255f);
    }

    /**
     * Draws one tile repeated to cover the given area, using the texture's own wrapping instead of
     * one draw call per tile.
     *
     * @param batch the batch to draw into; must already be between {@code begin()} and {@code end()}
     */
    public void draw(SpriteBatch batch, float x, float y, float width, float height) {
        batch.draw(texture, x, y, width, height,
            0, 0, (int) (width / TILE_SIZE), (int) (height / TILE_SIZE));
    }

    public void dispose() {
        texture.dispose();
    }
}
