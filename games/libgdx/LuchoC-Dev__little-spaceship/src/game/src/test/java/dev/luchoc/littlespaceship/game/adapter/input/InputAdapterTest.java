package dev.luchoc.littlespaceship.game.adapter.input;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.utils.viewport.Viewport;
import dev.luchoc.littlespaceship.core.port.BalanceValues;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.game.adapter.content.JsonBalanceValues;
import dev.luchoc.littlespaceship.game.testsupport.FakeGraphics;
import dev.luchoc.littlespaceship.game.testsupport.FakeInput;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Proves the harness this phase adds — {@link FakeInput}/{@link FakeGraphics} standing in for
 * {@code Gdx.input}/{@code Gdx.graphics} — actually exercises {@code game} code, per
 * {@code docs/plan/11g-shield-and-test-harness/plan.md} task 2.
 *
 * <p>The rule under test is {@link InputAdapter}'s own javadoc: keyboard and mouse are two additive
 * devices summed before the core ever sees them, per {@code 10-mvp-initial-values.md}, so holding
 * them in opposite directions cancels to a still ship instead of one device overriding the other.
 * Phase 03 verified this once with two uncommitted throwaway programs — see
 * {@code docs/plan/03-first-playable/status.md} — using the same JDK dynamic-proxy technique;
 * this class is that verification, committed and reproducible under {@code ./gradlew build}.
 *
 * <p>{@code Gdx.input}/{@code Gdx.graphics} are static fields on a class with no instance state,
 * so each test assigns them directly rather than through any dependency injection — the same seam
 * production code already reads through. They are restored to {@code null} afterwards so no test
 * leaks a fake into another test class that happens to run in the same JVM.
 */
final class InputAdapterTest {

    private static final BalanceValues BALANCE = new JsonBalanceValues(
        3, 5, 3, 5, 3,
        2f, 1f, 500,
        140f, 0.5f,
        104f, 30f,
        0.2f, 220f,
        6f,
        5f,
        1000, 500,
        1, 4,
        20f);

    @AfterEach
    void clearGdxStatics() {
        Gdx.input = null;
        Gdx.graphics = null;
    }

    @Test
    @DisplayName("keyboard alone drives the ship at the balance-defined top speed")
    void keyboardAloneReachesTopSpeed() {
        FakeInput fakeInput = new FakeInput().pressKey(Input.Keys.RIGHT);
        Gdx.input = fakeInput.asGdxInput();
        Gdx.graphics = new FakeGraphics(480).asGdxGraphics();

        InputFrame frame = new InputAdapter(fixedViewport()).sample(1f / 60f, BALANCE, true);

        assertEquals(140f, frame.moveX(), 0.001f);
        assertEquals(0f, frame.moveY(), 0.001f);
    }

    @Test
    @DisplayName("an opposing keyboard hold and mouse delta cancel to a still ship")
    void keyboardAndMouseCancelExactly() {
        // The mouse delta is chosen so its contribution matches the keyboard's magnitude exactly:
        // pixelsToLogical() = worldWidth / screenWidth = 208 / 208 = 1, frameDelta = 1s, so a
        // -140px delta contributes -140 units/s, cancelling +140 units/s from the held key.
        FakeInput fakeInput = new FakeInput().pressKey(Input.Keys.RIGHT).mouseDelta(-140, 0);
        Gdx.input = fakeInput.asGdxInput();
        Gdx.graphics = new FakeGraphics(208).asGdxGraphics();

        InputFrame frame = new InputAdapter(fixedViewport()).sample(1f, BALANCE, true);

        assertEquals(0f, frame.moveX(), 0.001f);
        assertEquals(0f, frame.moveY(), 0.001f);
    }

    private static Viewport fixedViewport() {
        Viewport viewport = new Viewport() {};
        viewport.setWorldWidth(208f);
        viewport.setWorldHeight(270f);
        return viewport;
    }
}
