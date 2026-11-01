package dev.luchoc.littlespaceship.game.testsupport;

import com.badlogic.gdx.Input;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.HashSet;
import java.util.Set;

/**
 * A JDK dynamic proxy standing in for {@code Gdx.input} in tests.
 *
 * <p>{@link Input} is an interface with no native implementation of its own — LWJGL only supplies
 * one at runtime — so a {@link Proxy} answering the handful of methods {@code InputAdapter} actually
 * calls is enough to exercise it with no display, no window and no LWJGL on the test classpath.
 * Phase 03's throwaway verification programs used the same technique; this class is that technique,
 * committed, per {@code docs/plan/11g-shield-and-test-harness/plan.md} task 2.
 *
 * <p>Only the methods {@code InputAdapter} reads are implemented. Any other {@link Input} method
 * returns the type's default (false/0/null) rather than throwing, so a proxy built here can stand in
 * for the whole interface without every test needing to know every method it does not use.
 */
public final class FakeInput implements InvocationHandler {

    private final Set<Integer> pressedKeys = new HashSet<>();
    private final Set<Integer> justPressedKeys = new HashSet<>();
    private final Set<Integer> pressedButtons = new HashSet<>();
    private final Set<Integer> justPressedButtons = new HashSet<>();
    private int deltaX;
    private int deltaY;
    private boolean cursorCatched;

    /** Wraps this handler in a proxy typed as {@link Input}, ready to assign to {@code Gdx.input}. */
    public Input asGdxInput() {
        return (Input) Proxy.newProxyInstance(
            getClass().getClassLoader(), new Class<?>[] {Input.class}, this);
    }

    public FakeInput pressKey(int keycode) {
        pressedKeys.add(keycode);
        return this;
    }

    public FakeInput justPressKey(int keycode) {
        pressedKeys.add(keycode);
        justPressedKeys.add(keycode);
        return this;
    }

    public FakeInput pressButton(int button) {
        pressedButtons.add(button);
        return this;
    }

    public FakeInput justPressButton(int button) {
        pressedButtons.add(button);
        justPressedButtons.add(button);
        return this;
    }

    /** Sets the pointer displacement since the previous frame, in screen pixels. */
    public FakeInput mouseDelta(int dx, int dy) {
        this.deltaX = dx;
        this.deltaY = dy;
        return this;
    }

    public boolean cursorCatched() {
        return cursorCatched;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) {
        switch (method.getName()) {
            case "isKeyPressed":
                return pressedKeys.contains((Integer) args[0]);
            case "isKeyJustPressed":
                return justPressedKeys.contains((Integer) args[0]);
            case "isButtonPressed":
                return pressedButtons.contains((Integer) args[0]);
            case "isButtonJustPressed":
                return justPressedButtons.contains((Integer) args[0]);
            case "getDeltaX":
                return deltaX;
            case "getDeltaY":
                return deltaY;
            case "isCursorCatched":
                return cursorCatched;
            case "setCursorCatched":
                cursorCatched = (Boolean) args[0];
                return null;
            case "toString":
                return "FakeInput";
            case "hashCode":
                return System.identityHashCode(proxy);
            case "equals":
                return proxy == args[0];
            default:
                return defaultValueFor(method.getReturnType());
        }
    }

    private static Object defaultValueFor(Class<?> returnType) {
        if (!returnType.isPrimitive() || returnType == void.class) {
            return null;
        }
        if (returnType == boolean.class) {
            return false;
        }
        return 0;
    }
}
