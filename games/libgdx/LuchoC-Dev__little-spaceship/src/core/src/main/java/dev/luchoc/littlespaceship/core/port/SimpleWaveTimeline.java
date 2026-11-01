package dev.luchoc.littlespaceship.core.port;

import java.util.List;

/**
 * The straightforward {@link WaveTimeline}.
 *
 * @param events the events of this level; rejected if not sorted by {@link SpawnEvent#at()}
 */
public record SimpleWaveTimeline(List<SpawnEvent> events) implements WaveTimeline {

    /**
     * Rejects an empty or unsorted timeline, naming the offending index. A parser that emitted
     * events out of order — or a hand-edited JSON file with a typo in one timestamp — would
     * otherwise make {@code SpawnSystem}'s single cursor skip or reorder waves silently.
     */
    public SimpleWaveTimeline {
        if (events == null || events.isEmpty()) {
            throw new IllegalArgumentException("a wave timeline has no events");
        }
        for (int i = 1; i < events.size(); i++) {
            if (events.get(i).at() < events.get(i - 1).at()) {
                throw new IllegalArgumentException(
                    "wave timeline event " + i + " is out of order: "
                        + events.get(i).at() + "s comes after " + events.get(i - 1).at() + "s");
            }
        }
        events = List.copyOf(events);
    }
}
