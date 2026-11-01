package dev.luchoc.littlespaceship.core.port;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class MapComponentSpecTest {

    @Test
    @DisplayName("reads the fields it was given, typed")
    void readsFields() {
        ComponentSpec spec = new MapComponentSpec("collider",
            Map.of("radius", 5.5f, "layer", "enemy", "fragile", true));

        assertEquals("collider", spec.name());
        assertEquals(5.5f, spec.number("radius"));
        assertEquals("enemy", spec.text("layer"));
        assertTrue(spec.flag("fragile"));
    }

    @Test
    @DisplayName("a missing required numeric field names the component and the field")
    void missingRequiredNumberFails() {
        ComponentSpec spec = new MapComponentSpec("collider", Map.of());

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> spec.number("radius"));

        assertTrue(e.getMessage().contains("collider"));
        assertTrue(e.getMessage().contains("radius"));
    }

    @Test
    @DisplayName("a missing required text field names the component and the field")
    void missingRequiredTextFails() {
        ComponentSpec spec = new MapComponentSpec("sprite", Map.of());

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> spec.text("id"));

        assertTrue(e.getMessage().contains("sprite"));
        assertTrue(e.getMessage().contains("id"));
    }

    @Test
    @DisplayName("a missing required boolean field names the component and the field")
    void missingRequiredFlagFails() {
        ComponentSpec spec = new MapComponentSpec("collider", Map.of("radius", 5.5f));

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> spec.flag("fragile"));

        assertTrue(e.getMessage().contains("collider"));
        assertTrue(e.getMessage().contains("fragile"));
    }

    @Test
    @DisplayName("an optional numeric field falls back to the default when the key is absent")
    void numberOrFallsBackWhenAbsent() {
        ComponentSpec spec = new MapComponentSpec("weapon", Map.of("rate", 1.8f));

        assertEquals(1.8f, spec.numberOr("firstShotDelay", 1.8f));
    }

    @Test
    @DisplayName("an optional numeric field reads the given value when present, not the default")
    void numberOrReadsValueWhenPresent() {
        ComponentSpec spec = new MapComponentSpec("weapon", Map.of("firstShotDelay", 0.4f));

        assertEquals(0.4f, spec.numberOr("firstShotDelay", 1.8f));
    }

    @Test
    @DisplayName("an optional numeric field present with the wrong type still fails, not silently ignored")
    void numberOrWrongTypeFails() {
        ComponentSpec spec = new MapComponentSpec("weapon", Map.of("firstShotDelay", "soon"));

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> spec.numberOr("firstShotDelay", 1.8f));
        assertTrue(e.getMessage().contains("firstShotDelay"));
    }

    @Test
    @DisplayName("a numeric field present with the wrong type fails naming the value, not silently")
    void wrongTypeNumberFails() {
        ComponentSpec spec = new MapComponentSpec("collider", Map.of("radius", "not a number"));

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> spec.number("radius"));
        assertTrue(e.getMessage().contains("radius"));
    }

    @Test
    @DisplayName("a boolean field present as a string fails instead of quietly reading as false")
    void wrongTypeFlagFails() {
        ComponentSpec spec = new MapComponentSpec("collider",
            Map.of("radius", 5.5f, "fragile", "true"));

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> spec.flag("fragile"));
        assertTrue(e.getMessage().contains("fragile"));
    }

    @Test
    @DisplayName("rejects a spec with no name")
    void rejectsEmptyName() {
        assertThrows(IllegalArgumentException.class, () -> new MapComponentSpec("", Map.of()));
        assertThrows(IllegalArgumentException.class, () -> new MapComponentSpec(null, Map.of()));
    }

    @Test
    @DisplayName("a null parameter map is treated as empty, failing the same way as an empty one")
    void nullParamsIsEmpty() {
        ComponentSpec spec = new MapComponentSpec("sprite", null);

        assertThrows(IllegalArgumentException.class, () -> spec.text("id"));
    }
}
