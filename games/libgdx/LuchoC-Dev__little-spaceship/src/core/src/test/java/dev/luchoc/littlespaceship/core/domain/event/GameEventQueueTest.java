package dev.luchoc.littlespaceship.core.domain.event;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class GameEventQueueTest {

    /** No real event exists yet; the queue does not care what it carries. */
    private record Noise(int value) implements GameEvent {
    }

    private final GameEventQueue queue = new GameEventQueue();
    private final List<GameEvent> received = new ArrayList<>();

    @Test
    @DisplayName("delivers what was emitted, in order")
    void deliversInOrder() {
        queue.emit(new Noise(1));
        queue.emit(new Noise(2));
        queue.emit(new Noise(3));

        queue.drainTo(received::add);

        assertEquals(List.of(new Noise(1), new Noise(2), new Noise(3)), received);
    }

    @Test
    @DisplayName("draining empties the queue, so a tick never delivers twice")
    void drainingEmpties() {
        queue.emit(new Noise(1));

        queue.drainTo(received::add);
        queue.drainTo(received::add);

        assertEquals(1, received.size());
        assertEquals(0, queue.pendingCount());
    }

    @Test
    @DisplayName("nothing is delivered until the tick is over")
    void holdsUntilDrained() {
        queue.emit(new Noise(1));

        assertEquals(0, received.size());
        assertEquals(1, queue.pendingCount());
    }

    /**
     * A sink that emits back would otherwise be delivered inside the same drain, which is the
     * reentrancy the architecture rules out.
     */
    @Test
    @DisplayName("what the sink emits back waits for the next drain")
    void reentrantEmissionWaits() {
        queue.emit(new Noise(1));

        queue.drainTo(event -> {
            received.add(event);
            queue.emit(new Noise(99));
        });

        assertEquals(1, received.size());
        assertEquals(1, queue.pendingCount());

        queue.drainTo(received::add);

        assertEquals(List.of(new Noise(1), new Noise(99)), received);
    }

    @Test
    @DisplayName("clearing discards without delivering")
    void clearDiscards() {
        queue.emit(new Noise(1));

        queue.clear();
        queue.drainTo(received::add);

        assertEquals(0, received.size());
    }

    @Test
    @DisplayName("rejects a null event")
    void rejectsNull() {
        assertThrows(IllegalArgumentException.class, () -> queue.emit(null));
    }
}
