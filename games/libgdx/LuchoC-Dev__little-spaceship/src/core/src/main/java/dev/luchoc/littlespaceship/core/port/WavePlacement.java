package dev.luchoc.littlespaceship.core.port;

/**
 * One entry of a level's ordered sequence of waves: which {@link WaveDefinition} to spawn and where,
 * relative to the placement before it — never to an absolute level time. A level carries no absolute
 * timestamps any more, per {@code docs/planning/08-decisions-and-open-items.md}, "The 11 group,
 * 27/08/2026".
 *
 * <p>The offset lives here, not on {@link WaveDefinition}, precisely so a wave stays reusable: the
 * same wave id can appear in two {@link WavePlacement}s of the same level, or of two different
 * levels, each with its own offset, without the wave's own declaration ever changing. Moving a
 * placement earlier in a level's list changes no other placement's own offset — each is relative
 * only to the one immediately before it in sequence, never to the file position of any declaration.
 *
 * <p>Resolved by {@code SpawnSystem} through {@link ContentSource#placements(String)} — a level's
 * ordered list of these, one per level id — decided by issue #112.
 *
 * @param waveId the {@link WaveDefinition} to place, resolved through {@link ContentSource#wave(String)}
 * @param offsetSeconds seconds after the previous placement in the sequence ends when this one
 *     starts; may be negative to overlap it. For the first placement of a level, "the one before it"
 *     is level time zero.
 */
public record WavePlacement(String waveId, float offsetSeconds) {

    /**
     * Rejects a placement that names no wave or carries a non-finite offset. Overlap is a real,
     * intended case — {@code post-mvp-roadmap.md}'s "high-pressure combinations" beat is built from a
     * negative offset — so only NaN and infinity are refused, never a negative value on its own.
     */
    public WavePlacement {
        if (waveId == null || waveId.isEmpty()) {
            throw new IllegalArgumentException("a wave placement needs a wave id");
        }
        if (Float.isNaN(offsetSeconds) || Float.isInfinite(offsetSeconds)) {
            throw new IllegalArgumentException(
                "wave placement '" + waveId + "' has a non-finite offset " + offsetSeconds);
        }
    }
}
