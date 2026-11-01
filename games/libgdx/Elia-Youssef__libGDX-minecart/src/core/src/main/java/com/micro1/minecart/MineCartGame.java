package com.micro1.minecart;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;

/**
 * Root Game: owns the single set of rendering resources (one SpriteBatch, ShapeRenderer,
 * BitmapFont) shared by every screen, so nothing is allocated in a render loop. Hosts the two
 * screens (title, gameplay). Also provides scaled-text helpers: the default BitmapFont is drawn
 * at requested cap-height sizes by scaling relative to its measured base cap height.
 *
 * The camera uses {@code setToOrtho(true, ...)} so the whole game works in a top-left origin
 * (x right, y down); the BitmapFont is created flipped to render upright in that space.
 */
public class MineCartGame extends Game {

    public OrthographicCamera camera;
    public SpriteBatch batch;
    public ShapeRenderer shapes;
    public BitmapFont font;
    public GlyphLayout layout;

    private float baseCapHeight;

    @Override
    public void create() {
        camera = new OrthographicCamera();
        camera.setToOrtho(true, MineCartWorld.WIDTH, MineCartWorld.HEIGHT);
        camera.update();

        batch = new SpriteBatch();
        shapes = new ShapeRenderer();
        font = new BitmapFont(true); // flipped for the y-down (top-left origin) camera
        layout = new GlyphLayout();
        baseCapHeight = font.getCapHeight();

        setScreen(new TitleScreen(this));
    }

    private void applyScale(float targetCapHeight, Color color) {
        font.getData().setScale(targetCapHeight / baseCapHeight);
        font.setColor(color);
    }

    /** Draw {@code s} centred on (cx, cy) at the requested cap height. */
    public void drawCentered(String s, float targetCapHeight, float cx, float cy, Color color) {
        applyScale(targetCapHeight, color);
        layout.setText(font, s);
        font.draw(batch, layout, cx - layout.width / 2f, cy - layout.height / 2f);
    }

    /** Draw {@code s} left-anchored at x, vertically centred on cy. */
    public void drawLeft(String s, float targetCapHeight, float x, float cy, Color color) {
        applyScale(targetCapHeight, color);
        layout.setText(font, s);
        font.draw(batch, layout, x, cy - layout.height / 2f);
    }

    /** Draw {@code s} right-anchored at rightX, vertically centred on cy. */
    public void drawRight(String s, float targetCapHeight, float rightX, float cy, Color color) {
        applyScale(targetCapHeight, color);
        layout.setText(font, s);
        font.draw(batch, layout, rightX - layout.width, cy - layout.height / 2f);
    }

    /** Bounding rectangle (with padding) of a would-be centred text, for click hit-testing. */
    public Rectangle centeredBounds(String s, float targetCapHeight, float cx, float cy,
                                    float padX, float padY, Rectangle out) {
        font.getData().setScale(targetCapHeight / baseCapHeight);
        layout.setText(font, s);
        out.set(cx - layout.width / 2f - padX, cy - layout.height / 2f - padY,
            layout.width + 2f * padX, layout.height + 2f * padY);
        return out;
    }

    @Override
    public void dispose() {
        if (getScreen() != null) {
            getScreen().dispose();
        }
        if (batch != null) {
            batch.dispose();
        }
        if (shapes != null) {
            shapes.dispose();
        }
        if (font != null) {
            font.dispose();
        }
    }
}
