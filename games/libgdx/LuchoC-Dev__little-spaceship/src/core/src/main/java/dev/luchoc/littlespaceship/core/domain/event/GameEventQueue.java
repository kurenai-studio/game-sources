package dev.luchoc.littlespaceship.core.domain.event;

import dev.luchoc.littlespaceship.core.port.GameEventSink;
import java.util.ArrayList;
import java.util.List;

/**
 * Buffers the events of one tick and hands them over once the tick is finished.
 *
 * <p>The queue exists so that no listener runs in the middle of the pipeline. If audio could react
 * the instant an enemy is destroyed, it would run between two systems and their order —which is a
 * game rule— would depend on who is listening. Draining afterwards keeps every tick identical with
 * a sink attached and without one.
 *
 * <p>Emission order is preserved, so a replay compares the same list twice.
 */
public final class GameEventQueue {

    private final List<GameEvent> pending = new ArrayList<>();

    /**
     * Records an event. Called by the systems during the tick.
     *
     * @param event what happened, never null
     */
    public void emit(GameEvent event) {
        if (event == null) {
            throw new IllegalArgumentException("an event cannot be null");
        }
        pending.add(event);
    }

    /**
     * Hands every buffered event to the sink, in emission order, and empties the queue.
     *
     * <p>Anything the sink emits back lands in the next tick, never in this drain: the loop below
     * walks a fixed size on purpose.
     *
     * @param sink the receiver, never null
     */
    public void drainTo(GameEventSink sink) {
        int count = pending.size();
        for (int i = 0; i < count; i++) {
            sink.emit(pending.get(i));
        }
        pending.subList(0, count).clear();
    }

    /**
     * Discards everything buffered without delivering it, for when a run is abandoned.
     */
    public void clear() {
        pending.clear();
    }

    /**
     * Returns how many events are waiting to be drained.
     *
     * @return the number of pending events
     */
    public int pendingCount() {
        return pending.size();
    }
}
