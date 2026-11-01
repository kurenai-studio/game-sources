package com.micro1.mooncourier;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.ScreenUtils;

/**
 * Shared boilerplate for the four screens: convenient handles to the game's
 * shared batch / shape /
 * fonts and a mouse-to-world-coordinate helper. Screens own no GL resources, so
 * the inherited
 * {@code dispose()} is a no-op.
 */
abstract class BaseScreen extends ScreenAdapter {

    protected final MoonCourierGame game;
    protected final SpriteBatch batch;
    protected final ShapeRenderer shape;
    protected final Assets a;
    protected final GlyphLayout layout;
    private final Vector2 tmp = new Vector2();

    BaseScreen(MoonCourierGame game) {
        this.game = game;
        this.batch = game.getBatch();
        this.shape = game.getShape();
        this.a = game.getAssets();
        this.layout = a.layout;
    }

    /** Current mouse position in 1280x720 world coordinates. */
    protected Vector2 mouse() {
        return game.getViewport().unproject(tmp.set(Gdx.input.getX(), Gdx.input.getY()));
    }

    protected void clear(Color c) {
        ScreenUtils.clear(c);
    }
}
