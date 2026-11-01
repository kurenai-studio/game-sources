package dev.meowpow.boxbot.testing;

import com.badlogic.gdx.Graphics;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

/**
 * A {@link Graphics} that reports a fixed window size,
 * delegating everything else to a real instance.
 * <p>
 * <strong>API Note:</strong>
 * A headless application has no real window, so
 * {@code Gdx.graphics} always reports a size of zero.
 * Code that reads the window size directly, such as
 * {@code ScreenLayout}, needs this wrapper instead.
 */
final class FixedSizeGraphics {

    private FixedSizeGraphics() {}

    static Graphics wrap(Graphics delegate, int width, int height) {
        return (Graphics) Proxy.newProxyInstance(
                Graphics.class.getClassLoader(),
                new Class<?>[]{Graphics.class},
                new Handler(delegate, width, height)
        );
    }

    /**
     * Answers window-size queries with a fixed size,
     * forwarding every other {@link Graphics}
     * call through to a real instance.
     */
    @SuppressWarnings("ClassCanBeRecord")
    private static final class Handler implements InvocationHandler {

        private final Graphics delegate;
        private final int width, height;

        Handler(Graphics delegate, int width, int height) {
            this.delegate = delegate;
            this.width = width;
            this.height = height;
        }

        @Override
        public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            switch (method.getName()) {
                case "getWidth", "getBackBufferWidth" -> {
                    return width;
                }
                case "getHeight", "getBackBufferHeight" -> {
                    return height;
                }
                default -> {
                    try {
                        return method.invoke(delegate, args);
                    }
                    catch (InvocationTargetException e) {
                        throw e.getCause();
                    }
                }
            }
        }
    }
}
