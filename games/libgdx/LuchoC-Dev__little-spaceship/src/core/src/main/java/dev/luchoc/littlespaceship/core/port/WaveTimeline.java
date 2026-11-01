package dev.luchoc.littlespaceship.core.port;

import java.util.List;

/**
 * A level as a flat sequence of timestamped events — the shape a level used to be authored in,
 * before {@link WaveDefinition} and {@link WavePlacement} existed.
 *
 * <p><b>Retired from {@code SpawnSystem}'s own read path by issue #112.</b> A level is now an
 * ordered sequence of {@link WavePlacement}s, each naming a reusable {@link WaveDefinition} and its
 * own offset from the placement before it, which {@code SpawnSystem} walks through {@link
 * ContentSource#placements(String)} and {@link ContentSource#wave(String)}. This type, {@link
 * SimpleWaveTimeline} and {@link ContentSource#timeline(String)} are kept only because {@code
 * game}'s {@code JsonContentSource} still populates them to serve {@code
 * assets/data/level-01.json}, which is not yet migrated to waves (issue #114) — deleting them now
 * would break that loader's compile, a module this type may not touch. Once #113 and #114 land, all
 * three can be deleted outright; nothing in {@code core} will read any of them by then.
 */
public interface WaveTimeline {

    /**
     * @return the events of this level, sorted by {@link SpawnEvent#at()}, never null
     */
    List<SpawnEvent> events();
}
