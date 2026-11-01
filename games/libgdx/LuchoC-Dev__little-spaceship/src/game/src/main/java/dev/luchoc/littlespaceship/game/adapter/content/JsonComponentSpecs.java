package dev.luchoc.littlespaceship.game.adapter.content;

import com.badlogic.gdx.utils.JsonValue;
import dev.luchoc.littlespaceship.core.port.ComponentSpec;
import dev.luchoc.littlespaceship.core.port.MapComponentSpec;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Turns the {@code "components"} object of an {@code enemies.json} entry into the
 * {@code List<ComponentSpec>} {@link dev.luchoc.littlespaceship.core.port.SimpleEnemyDefinition}
 * needs.
 *
 * <p>The JSON shape mirrors {@code 12-architecture.md}'s own example: an object keyed by component
 * name, each value an object of typed fields —
 * {@code "collider": {"radius": 7, "layer": "enemy"}} — which maps onto {@link MapComponentSpec}
 * directly, one instance per key. Nothing here validates a field's meaning; that is
 * {@code ComponentFactoryRegistry}'s job once the spec reaches {@code core} — this class only
 * has to get the JSON's shape into the contract's shape.
 */
final class JsonComponentSpecs {

    private JsonComponentSpecs() {
    }

    /**
     * @param componentsValue the {@code "components"} object of one enemy entry, never null
     * @return one {@link ComponentSpec} per child object, in file order
     */
    static List<ComponentSpec> parse(JsonValue componentsValue) {
        List<ComponentSpec> specs = new ArrayList<>();
        for (JsonValue component : componentsValue) {
            specs.add(new MapComponentSpec(component.name(), toParams(component)));
        }
        return specs;
    }

    private static Map<String, Object> toParams(JsonValue component) {
        Map<String, Object> params = new LinkedHashMap<>();
        for (JsonValue field : component) {
            params.put(field.name(), toValue(component.name(), field));
        }
        return params;
    }

    /**
     * Converts one field to the boxed type {@link MapComponentSpec} expects: a JSON number becomes
     * a {@link Float} (matching {@link ComponentSpec#number(String)}'s return type), a string stays
     * a {@link String}, a boolean stays a {@link Boolean}. Anything else — a nested object or an
     * array — has no field in any of the six level 1 archetypes and is rejected rather than guessed.
     */
    private static Object toValue(String componentName, JsonValue field) {
        if (field.isNumber()) {
            return field.asFloat();
        }
        if (field.isBoolean()) {
            return field.asBoolean();
        }
        if (field.isString()) {
            return field.asString();
        }
        throw new IllegalArgumentException(
            "component '" + componentName + "' field '" + field.name()
                + "' has an unsupported JSON type (" + field.type() + ")");
    }
}
