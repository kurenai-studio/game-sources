package dev.luchoc.littlespaceship.game.testsupport;

import com.badlogic.gdx.Graphics;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

/**
 * A JDK dynamic proxy standing in for {@code Gdx.graphics}, sized only to answer
 * {@link Graphics#getWidth()} — the one method {@code InputAdapter} reads, to turn a pixel
 * displacement into logical units. See {@link FakeInput} for why this technique needs no LWJGL.
 */
public final class FakeGraphics implements InvocationHandler {

    private final int width;

    public FakeGraphics(int width) {
        this.width = width;
    }

    public Graphics asGdxGraphics() {
        return (Graphics) Proxy.newProxyInstance(
            getClass().getClassLoader(), new Class<?>[] {Graphics.class}, this);
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) {
        switch (method.getName()) {
            case "getWidth":
                return width;
            case "toString":
                return "FakeGraphics";
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
