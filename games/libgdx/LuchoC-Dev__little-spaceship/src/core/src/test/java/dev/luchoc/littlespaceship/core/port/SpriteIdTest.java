package dev.luchoc.littlespaceship.core.port;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class SpriteIdTest {

    @Test
    @DisplayName("carries the identifier the content gave it")
    void carriesTheIdentifier() {
        assertEquals("ship-basic", new SpriteId("ship-basic").value());
    }

    @Test
    @DisplayName("two identifiers with the same name are the same identifier")
    void comparesByValue() {
        assertEquals(new SpriteId("ship-basic"), new SpriteId("ship-basic"));
    }

    @Test
    @DisplayName("rejects an identifier that names nothing")
    void rejectsEmptyNames() {
        assertThrows(IllegalArgumentException.class, () -> new SpriteId(null));
        assertThrows(IllegalArgumentException.class, () -> new SpriteId(""));
    }
}
