package dev.luchoc.littlespaceship.core.port;

import java.util.Map;

/**
 * A {@link ComponentSpec} backed by a plain map, for whoever builds one — the loader in {@code game}
 * reading a JSON object, or a core test building content by hand.
 *
 * <p>Values are boxed {@link Number}, {@link String} or {@link Boolean}. Every accessor is required:
 * a missing key and a key present with the wrong type both fail, with different messages, naming the
 * component and the field either way. Falling back to a default on a wrong-typed value was tried and
 * rejected — {@code "fragile": "true"} as a JSON string silently read as {@code false} in an earlier
 * version of this class, which is exactly the class of bug the malformed-content acceptance criterion
 * exists to catch, not produce.
 */
public final class MapComponentSpec implements ComponentSpec {

    private final String name;
    private final Map<String, Object> params;

    /**
     * @param name the component name, never null or empty
     * @param params the raw parameters, copied defensively; null is treated as empty
     */
    public MapComponentSpec(String name, Map<String, Object> params) {
        if (name == null || name.isEmpty()) {
            throw new IllegalArgumentException("a component spec needs a name");
        }
        this.name = name;
        this.params = params == null ? Map.of() : Map.copyOf(params);
    }

    @Override
    public String name() {
        return name;
    }

    @Override
    public float number(String key) {
        Object value = require(key);
        if (!(value instanceof Number number)) {
            throw wrongType(key, "numeric", value);
        }
        return number.floatValue();
    }

    @Override
    public float numberOr(String key, float defaultValue) {
        if (!params.containsKey(key)) {
            return defaultValue;
        }
        return number(key);
    }

    @Override
    public String text(String key) {
        Object value = require(key);
        if (!(value instanceof String text) || text.isEmpty()) {
            throw wrongType(key, "text", value);
        }
        return text;
    }

    @Override
    public boolean flag(String key) {
        Object value = require(key);
        if (!(value instanceof Boolean flag)) {
            throw wrongType(key, "a boolean", value);
        }
        return flag;
    }

    private Object require(String key) {
        if (!params.containsKey(key)) {
            throw new IllegalArgumentException(
                "component '" + name + "' is missing required field '" + key + "'");
        }
        return params.get(key);
    }

    private IllegalArgumentException wrongType(String key, String expected, Object actual) {
        return new IllegalArgumentException(
            "component '" + name + "' field '" + key + "' should be " + expected
                + ", was " + describe(actual));
    }

    private static String describe(Object value) {
        return value == null ? "null" : value + " (" + value.getClass().getSimpleName() + ")";
    }
}
