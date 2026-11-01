package dev.meowpow.boxbot.testing;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.graphics.GL20;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.nio.IntBuffer;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * A {@link GL20} that does nothing.
 * <p>
 * <strong>API Note:</strong>
 * A headless application leaves {@code Gdx.gl} unset,
 * so real asset loading crashes the moment it touches
 * a texture or shader. This stands in for it.
 */
final class NoOpGL20 {

    private NoOpGL20() {}

    static GL20 create() {
        return (GL20) Proxy.newProxyInstance(
                GL20.class.getClassLoader(),
                new Class<?>[]{GL20.class},
                new Handler()
        );
    }

    /**
     * Answers every {@link GL20} call with a
     * harmless default, forwarding nothing to a real driver.
     * <p>
     * <strong>Implementation Note:</strong>
     * A handful of calls need more than a blank no-op:
     * libGDX treats a zero id as a failed resource allocation,
     * and a zero status as an incomplete shader, program,
     * or framebuffer, so those specific calls are answered
     * with a success value instead of the default.
     */
    private static final class Handler implements InvocationHandler {

        private static final Set<String> STATUS_QUERIES = Set.of(
                "glGetShaderiv",
                "glGetProgramiv"
        );
        private static final Set<Integer> STATUS_PNAMES = Set.of(
                GL20.GL_COMPILE_STATUS,
                GL20.GL_LINK_STATUS
        );
        private static final Set<String> ID_FACTORIES = Set.of(
                "glCreateShader",
                "glCreateProgram",
                "glGenTexture",
                "glGenBuffer",
                "glGenFramebuffer",
                "glGenRenderbuffer"
        );
        private final AtomicInteger nextId = new AtomicInteger(1);

        @Override
        public @Nullable Object invoke(Object proxy, Method method, Object[] args) {
            if (STATUS_QUERIES.contains(method.getName()) && STATUS_PNAMES.contains((Integer) args[1])) {
                ((IntBuffer) args[2]).put(0, GL20.GL_TRUE);
                return null;
            }
            if (ID_FACTORIES.contains(method.getName())) {
                return nextId.getAndIncrement();
            }
            if (method.getName().equals("glCheckFramebufferStatus")) {
                return GL20.GL_FRAMEBUFFER_COMPLETE;
            }
            return switch (method.getReturnType().getName()) {
                case "int" -> 0;
                case "long" -> 0L;
                case "float" -> 0f;
                case "boolean" -> false;
                default -> null;
            };
        }
    }
}
