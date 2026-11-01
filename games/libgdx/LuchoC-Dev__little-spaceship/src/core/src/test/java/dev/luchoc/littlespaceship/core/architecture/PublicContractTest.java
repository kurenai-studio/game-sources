package dev.luchoc.littlespaceship.core.architecture;

import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.architecture.CoreSources.SourceFile;
import java.lang.reflect.Constructor;
import java.lang.reflect.Executable;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * No type of {@code core} reachable from {@code game} exposes an implementation class.
 *
 * <p>This is the rule that decays first. One getter returning the concrete class, added for
 * convenience, and the boundary is gone: whoever receives it can reach the entity registry, the
 * component stores and the world. Checking it by reflection is what keeps the convenience from
 * winning.
 *
 * <p><b>Scope.</b> This test inspects only {@code core.port} and {@code core.application} —
 * {@code core.domain} is excluded on purpose, not by oversight. {@link
 * dev.luchoc.littlespaceship.core.domain.World} itself publicly returns implementation classes
 * ({@code ComponentStore}, {@code EntityRegistry}, {@code Rng}, {@code GameEventQueue}), and that
 * is safe only because none of the domain is reachable from {@code game}: systems live in the
 * domain and must mutate the world directly, so hiding it from itself would break them; Java
 * without JPMS has no way to say "public within {@code core}", so the domain's own machinery has
 * to be a public type even though it is never meant to leave the module; and {@code game} can
 * never reach a running {@code World} because {@link
 * dev.luchoc.littlespaceship.core.application.Simulation#world()} is package-private and {@link
 * dev.luchoc.littlespaceship.core.application.Simulation#view()} returns a {@code WorldView}
 * instead. If any of those three facts stops being true, this test's scope stops being safe and
 * must widen.
 *
 * <p>What is allowed to cross: primitives, strings, the ports themselves, what the application
 * layer composes with, and the domain events, which are immutable and exist precisely to be read
 * from outside.
 */
class PublicContractTest {

    private static final String ROOT = "dev.luchoc.littlespaceship.core";
    private static final List<String> BOUNDARY_PACKAGES = List.of(
        ROOT + ".port", ROOT + ".application");
    private static final List<String> ALLOWED_PACKAGES = List.of(
        ROOT + ".port", ROOT + ".application", ROOT + ".domain.event");
    /**
     * The only {@code java.util} types a contract is allowed to carry — interfaces the caller reads
     * through, never a concrete collection. {@code List} and {@code Map} are what {@code core.port}
     * and {@code core.application} actually use today; add to this set only when a real public
     * signature needs one, not speculatively.
     */
    private static final List<Class<?>> ALLOWED_JAVA_UTIL_TYPES = List.of(
        java.util.List.class, java.util.Map.class);

    @Test
    @DisplayName("what crosses the boundary is a contract, never the machinery behind it")
    void boundaryExposesOnlyContracts() {
        List<String> violations = new ArrayList<>();

        for (Class<?> type : boundaryTypes()) {
            for (Constructor<?> constructor : type.getDeclaredConstructors()) {
                if (Modifier.isPublic(constructor.getModifiers())) {
                    checkParameters(constructor, violations);
                }
            }
            for (Method method : type.getDeclaredMethods()) {
                if (!Modifier.isPublic(method.getModifiers()) || method.isSynthetic()) {
                    continue;
                }
                checkParameters(method, violations);
                if (!isAllowed(method.getReturnType())) {
                    violations.add(type.getName() + "." + method.getName()
                        + " returns " + method.getReturnType().getName());
                }
            }
            for (Field field : type.getDeclaredFields()) {
                if (Modifier.isPublic(field.getModifiers()) && !isAllowed(field.getType())) {
                    violations.add(type.getName() + "." + field.getName()
                        + " exposes " + field.getType().getName());
                }
            }
        }

        assertTrue(violations.isEmpty(),
            () -> "implementation classes leaking out of core:\n" + String.join("\n", violations));
    }

    @Test
    @DisplayName("the boundary is actually being inspected")
    void inspectsTheBoundary() {
        assertTrue(boundaryTypes().size() >= 8,
            "ports and application types should be more than this");
    }

    private static void checkParameters(Executable executable, List<String> violations) {
        for (Class<?> parameter : executable.getParameterTypes()) {
            if (!isAllowed(parameter)) {
                violations.add(executable.getDeclaringClass().getName()
                    + "." + executable.getName() + " takes " + parameter.getName());
            }
        }
    }

    private static boolean isAllowed(Class<?> type) {
        Class<?> component = type;
        while (component.isArray()) {
            component = component.getComponentType();
        }
        if (component.isPrimitive()) {
            return true;
        }
        String name = component.getName();
        if (name.startsWith("java.lang.")) {
            return true;
        }
        if (ALLOWED_JAVA_UTIL_TYPES.contains(component)) {
            return true;
        }
        for (String allowed : ALLOWED_PACKAGES) {
            if (name.startsWith(allowed + ".")) {
                return true;
            }
        }
        return false;
    }

    private static List<Class<?>> boundaryTypes() {
        List<Class<?>> types = new ArrayList<>();
        for (SourceFile file : CoreSources.all()) {
            String className = file.path().replace(".java", "").replace('/', '.');
            boolean atBoundary = false;
            for (String boundary : BOUNDARY_PACKAGES) {
                atBoundary |= file.packageName().equals(boundary);
            }
            if (!atBoundary) {
                continue;
            }
            Class<?> type;
            try {
                type = Class.forName(className);
            } catch (ClassNotFoundException e) {
                throw new IllegalStateException("cannot load " + className, e);
            }
            if (!Modifier.isPublic(type.getModifiers())) {
                continue;
            }
            types.add(type);
            for (Class<?> nested : type.getDeclaredClasses()) {
                if (Modifier.isPublic(nested.getModifiers())) {
                    types.add(nested);
                }
            }
        }
        return types;
    }
}
