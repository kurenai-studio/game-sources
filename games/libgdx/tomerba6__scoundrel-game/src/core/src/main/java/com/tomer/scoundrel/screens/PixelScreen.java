package com.tomer.scoundrel.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.ScreenUtils;
import com.tomer.scoundrel.ScoundrelGame;

/**
 * The frame every navigable screen draws inside: the 1280×720 surface, the
 * viewport that scales it to the window, the torchlit backdrop behind it, and
 * the press gesture that turns clicks into targets.
 *
 * <p><b>{@link #render(float)} is final, and that is the point of this class.</b>
 * Activating a target navigates, and navigating disposes this screen along with
 * its batch and surface — drawing afterwards reads freed native memory and takes
 * the JVM down with an {@code EXCEPTION_ACCESS_VIOLATION} rather than throwing
 * something a test could catch. The guard is written once, here, above a
 * {@link #drawContent} a subclass cannot reach until the check has passed.
 *
 * <p>The two passes are equally load-bearing. Everything is drawn at 1:1 onto
 * the surface, and that one image is scaled to the window once — drawn straight
 * to the window instead, every quad rounds separately and identical features
 * disagree by a pixel.
 *
 * <p>{@code SpriteLab} deliberately does not extend this: it has no press
 * gesture and no backdrop, and it is a developer tool rather than a screen
 * anyone navigates to.
 */
public abstract class PixelScreen extends ScreenAdapter {

    /** Hoisted rather than built per frame, as {@code GameScreen} already did. */
    private static final Color CLEAR = new Color((CardArt.BACKDROP << 8) | 0xff);

    /** The navigator: where a screen goes next, and the shared sounds and music. */
    protected final ScoundrelGame game;
    /** The shared fonts and generated textures. */
    protected final Theme theme;
    /** Scales the 1280×720 surface to the window at a half-step scale, letterboxed. */
    protected final PixelViewport viewport;
    /** This screen's own batch, disposed with it. */
    protected final SpriteBatch batch = new SpriteBatch();
    /** The 1:1 offscreen surface every frame is drawn onto first. */
    protected final PixelSurface surface;
    /** The torchlit glow, vignette and embers behind everything. */
    protected final Backdrop backdrop;
    /** The menu kit: frames, faces, plates and text. */
    protected final Chrome chrome;
    /** The press on a menu target, and whether it has been seen long enough to act. */
    protected final PressGesture press = new PressGesture();

    /**
     * Builds the frame. The batch and surface are GL resources, so on the GL thread only.
     *
     * @param game  the navigator
     * @param theme the shared fonts and textures
     */
    protected PixelScreen(ScoundrelGame game, Theme theme) {
        this.game = game;
        this.theme = theme;
        this.viewport = new PixelViewport(Theme.WORLD_WIDTH, Theme.WORLD_HEIGHT);
        this.surface = new PixelSurface((int) Theme.WORLD_WIDTH, (int) Theme.WORLD_HEIGHT);
        this.backdrop = new Backdrop(theme);
        this.chrome = new Chrome(theme);
    }

    @Override
    public void show() {
        Gdx.input.setInputProcessor(new FrameInput());
    }

    /**
     * One frame: fire any armed target, stop if that navigated away, advance the
     * clocks, draw at 1:1 onto the surface, then scale the surface to the window
     * once. Final — override {@link #drawContent} and the other hooks instead.
     *
     * @param delta seconds since the last frame
     */
    @Override
    public final void render(float delta) {
        // A target acts here rather than the instant it comes up, once its
        // plate has been down long enough to have been seen.
        int fired = press.advance(delta);
        if (fired != PressGesture.NONE) {
            activate(fired);
            if (game.getScreen() != this) {
                return;
            }
        }
        advance(delta);

        // Everything at 1:1 on the surface's own grid first.
        surface.begin(CLEAR);
        batch.setProjectionMatrix(surface.projection());
        batch.begin();
        backdrop.render(batch, backdropLight());
        drawContent(delta);
        batch.end();
        surface.end();

        // Then that one image to the window, in one scale.
        ScreenUtils.clear(Color.BLACK);
        viewport.apply();
        batch.setProjectionMatrix(viewport.getCamera().combined);
        batch.begin();
        surface.draw(batch, Theme.WORLD_WIDTH, Theme.WORLD_HEIGHT);
        batch.end();
    }

    /**
     * Refits the viewport to the window; a zero size (minimised) is ignored.
     *
     * @param width  the window's new width, in screen pixels
     * @param height the window's new height, in screen pixels
     */
    @Override
    public final void resize(int width, int height) {
        if (width <= 0 || height <= 0) {
            return;
        }
        viewport.update(width, height, true);
    }

    @Override
    public void dispose() {
        surface.dispose();
        batch.dispose();
    }

    /**
     * A press went down on {@code target}: the plate sinks, and — if it is a button
     * that clicks — the click plays now, with the sink, rather than on release when
     * the button acts. The sound goes with the picture. Returns whether the press
     * landed on a target, as {@link PressGesture#press} does.
     *
     * @param target what the press hit-tested to, or {@link PressGesture#NONE}
     * @return whether the press landed on a target
     */
    protected final boolean pressAt(int target) {
        boolean again = press.alreadyDown(target);
        boolean landed = press.press(target);
        if (landed && !again && clicks(target)) {
            SoundBank sounds = game.sounds();
            sounds.play(sounds.choice().click());
        }
        return landed;
    }

    /**
     * Whether a press on this target clicks. Every menu button does; the board
     * overrides it, because buttons pressed during a run are silent — the sound
     * of what they do follows at once.
     *
     * @param target the target being pressed
     * @return true here; the board answers per target
     */
    protected boolean clicks(int target) {
        return true;
    }

    /**
     * A window-space point in the 1280×720 design space.
     *
     * @param screenX the pointer's x, in window pixels from the left
     * @param screenY the pointer's y, in window pixels from the top
     * @return a new vector in world space, y pointing up; outside 0..1280 in the letterbox
     * @see com.badlogic.gdx.utils.viewport.Viewport#unproject(Vector2)
     */
    protected final Vector2 unproject(int screenX, int screenY) {
        return viewport.unproject(new Vector2(screenX, screenY));
    }

    /**
     * Moves this screen's clocks on. The backdrop always; more if overridden.
     * An override must call this one.
     *
     * @param delta seconds since the last frame
     */
    protected void advance(float delta) {
        backdrop.advance(delta);
    }

    /**
     * How brightly the torch burns, 0..1. Only the death gutters it.
     *
     * @return 1 here
     */
    protected float backdropLight() {
        return 1f;
    }

    /**
     * The torch's light as drawn, for the torch's crackle to follow: it gutters with it.
     *
     * @return this screen's {@link #backdropLight()}
     */
    public final float torchLight() {
        return backdropLight();
    }

    /**
     * Where ESC goes. Every screen with a back plate leaves to the title; the
     * title itself overrides this, having nowhere to go.
     */
    protected void escape() {
        game.showTitle();
    }

    /**
     * Keys beyond ESC. Return true if handled.
     *
     * @param keycode the key, as {@link Input.Keys} numbers it
     * @return false here: no other keys
     */
    protected boolean keyPressed(int keycode) {
        return false;
    }

    /**
     * Whether something modal is up. A modal screen consumes a click that hit
     * none of its targets, rather than letting it reach what is behind — a
     * destructive confirmation that let the screen underneath take a press
     * would be the worst place in the game to get that wrong.
     *
     * @return false here
     */
    protected boolean modal() {
        return false;
    }

    /**
     * Draws the screen's own content, on top of the backdrop. The batch is
     * already begun, on the surface's 1:1 projection; leave it begun.
     *
     * @param delta seconds since the last frame
     */
    protected abstract void drawContent(float delta);

    /**
     * What a window-space point is on, as a target id, or
     * {@link PressGesture#NONE}.
     *
     * @param screenX the pointer's x, in window pixels from the left
     * @param screenY the pointer's y, in window pixels from the top
     * @return the target's id, or {@link PressGesture#NONE}
     */
    protected abstract int hit(int screenX, int screenY);

    /**
     * What a released target does. Only reached once its press has been seen.
     *
     * @param target the id {@link #hit} returned for it
     */
    protected abstract void activate(int target);

    private final class FrameInput extends InputAdapter {
        @Override
        public boolean touchDown(int screenX, int screenY, int pointer, int button) {
            if (button != Input.Buttons.LEFT) {
                return false;
            }
            return pressAt(hit(screenX, screenY)) || modal();
        }

        @Override
        public boolean touchDragged(int screenX, int screenY, int pointer) {
            press.moveOver(hit(screenX, screenY));
            return false;
        }

        @Override
        public boolean touchUp(int screenX, int screenY, int pointer, int button) {
            if (button != Input.Buttons.LEFT) {
                return false;
            }
            return press.release(hit(screenX, screenY)) || modal();
        }

        @Override
        public boolean keyDown(int keycode) {
            if (keycode == Input.Keys.ESCAPE) {
                escape();
                return true;
            }
            return keyPressed(keycode);
        }
    }
}
