package dev.luchoc.littlespaceship.game.adapter.input;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import dev.luchoc.littlespaceship.core.port.BalanceValues;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * Turns keyboard and mouse into one {@link InputFrame} per rendered frame.
 *
 * <p>This is the one place the additive-devices rule from {@code 10-mvp-initial-values.md} is
 * implemented: keyboard and mouse each contribute a vector in logical units per second and the two
 * are summed here, before the core ever sees them. {@code MotionSystem} only clamps the magnitude
 * it is handed — it does not know two devices exist. Summing here is what
 * makes opposite directions cancel instead of one device overriding the other.
 *
 * <p>The mouse is relative, not positional: it contributes the cursor's displacement since the last
 * frame, scaled from screen pixels to logical units and divided by elapsed time, which is what
 * {@link InputFrame}'s unit contract asks for. A positional mouse could not be summed with the
 * keyboard the way the rule requires — teleporting to a target and nudging by a held key are not
 * the same kind of quantity.
 *
 * <p>Reading the pointer's raw displacement needs the pointer captured, or it stops generating
 * delta the moment the cursor reaches a window edge while the player keeps moving the physical
 * mouse. Capture only engages after a click, which is also what the browser's Pointer Lock API
 * requires; on web this is unverified against a real browser, per {@code CLAUDE.md}.
 */
public final class InputAdapter {

    /**
     * Frame time floor used only to avoid a division by zero when converting a pixel delta into a
     * velocity. It does not affect the fixed step the simulation runs at.
     */
    private static final float MIN_FRAME_DELTA = 1f / 1000f;

    private final Viewport viewport;

    private boolean pointerCaptureRequested;
    private boolean pointerCaptureConfirmed;
    private boolean pointerCaptureLostUnexpectedly;

    public InputAdapter(Viewport viewport) {
        if (viewport == null) {
            throw new IllegalArgumentException("the input adapter needs the render viewport");
        }
        this.viewport = viewport;
    }

    /**
     * Samples every device once and returns the frame every tick of this render frame will share.
     *
     * @param frameDelta seconds since the previous rendered frame, used only to turn a pixel
     *     displacement into a velocity
     * @param balance where the keyboard's full-deflection magnitude and the slow multiplier come
     *     from — the adapter does not invent numbers the content already owns
     * @param mouseEnabled the Options screen's mouse-control switch, per
     *     {@code docs/planning/02-mvp-functional-spec.md}; when false the mouse contributes nothing,
     *     including to fire and bomb, so a disabled mouse cannot fire either
     * @return an immutable frame ready for {@link dev.luchoc.littlespaceship.core.application.GameLoop#advance}
     */
    public InputFrame sample(float frameDelta, BalanceValues balance, boolean mouseEnabled) {
        managePointerCapture(mouseEnabled);

        float safeDelta = Math.max(frameDelta, MIN_FRAME_DELTA);
        boolean slow = Gdx.input.isKeyPressed(Input.Keys.SHIFT_LEFT)
            || Gdx.input.isKeyPressed(Input.Keys.SHIFT_RIGHT);
        float cap = balance.playerSpeed() * (slow ? balance.playerSlowFactor() : 1f);

        float moveX = keyboardX(cap) + (mouseEnabled ? mouseX(safeDelta) : 0f);
        float moveY = keyboardY(cap) + (mouseEnabled ? mouseY(safeDelta) : 0f);

        boolean fire = Gdx.input.isKeyPressed(Input.Keys.SPACE)
            || (mouseEnabled && Gdx.input.isButtonPressed(Input.Buttons.LEFT));
        boolean bomb = Gdx.input.isKeyJustPressed(Input.Keys.X)
            || (mouseEnabled && Gdx.input.isButtonJustPressed(Input.Buttons.RIGHT));

        return new InputFrame(moveX, moveY, fire, slow, bomb);
    }

    /**
     * Keyboard contribution on the horizontal axis, at the same magnitude the input contract
     * expects at full deflection. Left and right held together cancel to zero before the core ever
     * sees a value, the same way the mouse cancels against the keyboard.
     */
    private static float keyboardX(float magnitude) {
        float x = 0f;
        if (Gdx.input.isKeyPressed(Input.Keys.LEFT)) {
            x -= 1f;
        }
        if (Gdx.input.isKeyPressed(Input.Keys.RIGHT)) {
            x += 1f;
        }
        return x * magnitude;
    }

    /** Keyboard contribution on the vertical axis. See {@link #keyboardX(float)}. */
    private static float keyboardY(float magnitude) {
        float y = 0f;
        if (Gdx.input.isKeyPressed(Input.Keys.DOWN)) {
            y -= 1f;
        }
        if (Gdx.input.isKeyPressed(Input.Keys.UP)) {
            y += 1f;
        }
        return y * magnitude;
    }

    /**
     * Mouse contribution on the horizontal axis: the pointer's displacement since last frame,
     * converted from screen pixels to logical units and turned into a velocity by dividing by
     * elapsed time.
     */
    private float mouseX(float safeDelta) {
        return Gdx.input.getDeltaX() * pixelsToLogical() / safeDelta;
    }

    /**
     * Mouse contribution on the vertical axis. Screen Y grows down; the world's Y grows up, hence
     * the sign flip.
     */
    private float mouseY(float safeDelta) {
        return -Gdx.input.getDeltaY() * pixelsToLogical() / safeDelta;
    }

    private float pixelsToLogical() {
        return viewport.getWorldWidth() / Math.max(1, Gdx.graphics.getWidth());
    }

    /**
     * True for exactly the frame the browser revoked pointer lock on its own — a notification,
     * alt-tab, or a click outside the canvas can all do this without the game asking. Distinguished
     * from the player's own Escape release in {@link #managePointerCapture(boolean)}: only this path
     * should pause the game, because the deltas {@link #mouseX(float)}/{@link #mouseY(float)} would
     * otherwise keep reading now come from a free cursor rather than a locked one, which is exactly
     * the bug in issue #41.
     */
    public boolean pointerCaptureLostUnexpectedly() {
        return pointerCaptureLostUnexpectedly;
    }

    /**
     * Captures the pointer on the first click, which is both what a relative mouse needs to keep
     * producing deltas past the window edge and what the browser's Pointer Lock API requires before
     * it will engage. Escape releases it deliberately, so the player is never stuck without a
     * visible cursor.
     *
     * <p>The browser can also revoke the lock on its own, without the game asking — that is the case
     * {@code isCursorCatched()} exists to observe rather than trust {@link #pointerCaptureRequested},
     * a flag this class set itself and has no way to know the browser overrode. This method is the
     * one place that distinguishes the two: Escape sets {@link #pointerCaptureLostUnexpectedly} to
     * false, an unasked-for revocation sets it to true, for
     * {@link dev.luchoc.littlespaceship.game.screen.PlayScreen} to react to.
     *
     * <p>The web backend's {@code requestPointerLock()} is asynchronous: {@code isCursorCatched()}
     * can keep reporting false for an unknown number of frames after the request, until the browser
     * grants the lock and fires {@code pointerlockchange}. The desktop LWJGL3 backend grants it
     * synchronously, which is why this only shows up on web. Testing for loss the very frame capture
     * is requested — or even the next one — would read the still-pending grant as an unexpected
     * revocation and pause the game on the click meant to start it. {@link #pointerCaptureConfirmed}
     * exists for this: the loss check only arms once {@code isCursorCatched()} has been observed
     * true at least once since the request, so a slow grant is just silently waited out rather than
     * bounded to a fixed number of frames.
     */
    private void managePointerCapture(boolean mouseEnabled) {
        pointerCaptureLostUnexpectedly = false;
        boolean escapeJustPressed = Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE);

        if (mouseEnabled && !pointerCaptureRequested
            && (Gdx.input.isButtonJustPressed(Input.Buttons.LEFT)
                || Gdx.input.isButtonJustPressed(Input.Buttons.RIGHT))) {
            Gdx.input.setCursorCatched(true);
            pointerCaptureRequested = true;
            pointerCaptureConfirmed = false;
        }

        if (escapeJustPressed && pointerCaptureRequested) {
            Gdx.input.setCursorCatched(false);
            pointerCaptureRequested = false;
            pointerCaptureConfirmed = false;
        } else if (pointerCaptureRequested) {
            if (Gdx.input.isCursorCatched()) {
                // The asynchronous grant has landed; the loss check below may now fire on a future
                // frame where the browser actually revokes it.
                pointerCaptureConfirmed = true;
            } else if (pointerCaptureConfirmed) {
                pointerCaptureRequested = false;
                pointerCaptureConfirmed = false;
                pointerCaptureLostUnexpectedly = true;
            }
            // else: the grant is still pending — not yet confirmed, so not yet a loss.
        }
    }
}
