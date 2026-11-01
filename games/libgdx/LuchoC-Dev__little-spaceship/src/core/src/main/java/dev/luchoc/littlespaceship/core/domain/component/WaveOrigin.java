package dev.luchoc.littlespaceship.core.domain.component;

/**
 * Which wave spawned this entity, needed to answer a "cleared" wave's end condition: a wave is not
 * cleared until every entity carrying its id has been destroyed or has left the playfield.
 *
 * <p>Attached by {@code SpawnSystem} to every entity a wave's own {@code spawnWave} call creates, and
 * copied — never recomputed — onto every child {@code SpawnerSystem} spawns from a carrier that
 * itself carries one. That copy is the carrier-children rule the project owner decided on 28/08/2026,
 * recorded in {@code docs/planning/08-decisions-and-open-items.md}: a child inherits its parent's
 * wave, because what the player reads on screen is "the wave's encounter is still there", not
 * "the entity that originally carried it is still there". A carrier with no {@link WaveOrigin} of
 * its own — one built outside a wave, such as by a test — simply produces children with none either.
 *
 * <p>{@link #waveId} is the wave's own content id — {@code WaveDefinition.id()} — the string a
 * {@code waves.json} entry is named by, not a synthetic per-call counter. It started as an {@code int}
 * taken from {@code SpawnSystem}'s old flat-list cursor, an admitted stopgap issue #85 recorded and
 * issue #112 promoted once a wave had a real content id to carry: two entities from two different
 * spawns of the <em>same</em> wave id correctly compare equal here, which is exactly what {@code
 * WaveEndCondition.Cleared} needs to ask "has every entity of this wave gone" without also caring how
 * many times {@code spawnWave} happened to run.
 */
public final class WaveOrigin {

    /** The content id of the wave that spawned this entity, directly or through a carrier. */
    public final String waveId;

    /**
     * @param waveId content id of the spawning wave
     */
    public WaveOrigin(String waveId) {
        this.waveId = waveId;
    }
}
