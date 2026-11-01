package dev.luchoc.littlespaceship.core.port;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class InputFrameTest {

    @Test
    @DisplayName("carries what the player asked for")
    void carriesTheIntent() {
        InputFrame frame = new InputFrame(-1f, 0.5f, true, false, true);

        assertEquals(-1f, frame.moveX());
        assertEquals(0.5f, frame.moveY());
        assertEquals(true, frame.fire());
        assertEquals(false, frame.slow());
        assertEquals(true, frame.bomb());
    }

    @Test
    @DisplayName("the idle frame has nothing pressed")
    void idleFrameIsEmpty() {
        assertEquals(0f, InputFrame.IDLE.moveX());
        assertEquals(0f, InputFrame.IDLE.moveY());
        assertFalse(InputFrame.IDLE.fire());
        assertFalse(InputFrame.IDLE.slow());
        assertFalse(InputFrame.IDLE.bomb());
    }

    @Test
    @DisplayName("two frames with the same content are the same frame")
    void comparesByValue() {
        assertEquals(new InputFrame(1f, 0f, true, false, false),
            new InputFrame(1f, 0f, true, false, false));
        assertNotEquals(new InputFrame(1f, 0f, true, false, false),
            new InputFrame(1f, 0f, false, false, false));
    }

    /**
     * A NaN reaching the simulation spreads through every position that touches it and shows up
     * much later as an entity that vanished, with nothing pointing back at the input that caused it.
     */
    @Test
    @DisplayName("rejects a movement that is not finite")
    void rejectsNonFiniteMovement() {
        assertThrows(IllegalArgumentException.class,
            () -> new InputFrame(Float.NaN, 0f, false, false, false));
        assertThrows(IllegalArgumentException.class,
            () -> new InputFrame(0f, Float.NaN, false, false, false));
        assertThrows(IllegalArgumentException.class,
            () -> new InputFrame(Float.POSITIVE_INFINITY, 0f, false, false, false));
        assertThrows(IllegalArgumentException.class,
            () -> new InputFrame(0f, Float.NEGATIVE_INFINITY, false, false, false));
    }

    @Test
    @DisplayName("accepts a vector longer than one, because clamping is a game rule")
    void acceptsUnnormalisedVectors() {
        InputFrame both = new InputFrame(2f, -2f, false, false, false);

        assertEquals(2f, both.moveX());
        assertEquals(-2f, both.moveY());
    }
}
