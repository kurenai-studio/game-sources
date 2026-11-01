package dev.luchoc.littlespaceship.core.port;

import java.util.List;

/**
 * The straightforward {@link WaveDefinition}.
 *
 * @param id the content id
 * @param spawns the spawns of this wave; rejected if empty or not sorted by {@link SpawnEvent#at()}
 * @param pickups the pickups this wave places directly, with no enemy carrying them; rejected only
 *     if not sorted by {@link PlacedPickup#at()} — unlike {@code spawns}, empty is the common case
 * @param endCondition what ends this wave
 */
public record SimpleWaveDefinition(
    String id, List<SpawnEvent> spawns, List<PlacedPickup> pickups, WaveEndCondition endCondition)
    implements WaveDefinition {

    /**
     * Rejects a wave that names nothing, has no spawn, spawns or places pickups out of order, or
     * has no end condition. A hand-edited {@code waves.json} with a typo in one spawn's or one
     * pickup's timestamp would otherwise make whatever walks {@link #spawns()} or {@link #pickups()}
     * with a single cursor (issue #112, issue #318) skip or reorder them silently — the same
     * reasoning {@link SimpleWaveTimeline} already applies to a level.
     */
    public SimpleWaveDefinition {
        if (id == null || id.isEmpty()) {
            throw new IllegalArgumentException("a wave needs an id");
        }
        if (spawns == null || spawns.isEmpty()) {
            throw new IllegalArgumentException("wave '" + id + "' has no spawns");
        }
        for (int i = 1; i < spawns.size(); i++) {
            if (spawns.get(i).at() < spawns.get(i - 1).at()) {
                throw new IllegalArgumentException(
                    "wave '" + id + "' spawn " + i + " is out of order: "
                        + spawns.get(i).at() + "s comes after " + spawns.get(i - 1).at() + "s");
            }
        }
        if (pickups == null) {
            throw new IllegalArgumentException("wave '" + id + "' needs a pickup list, even if empty");
        }
        for (int i = 1; i < pickups.size(); i++) {
            if (pickups.get(i).at() < pickups.get(i - 1).at()) {
                throw new IllegalArgumentException(
                    "wave '" + id + "' pickup " + i + " is out of order: "
                        + pickups.get(i).at() + "s comes after " + pickups.get(i - 1).at() + "s");
            }
        }
        if (endCondition == null) {
            throw new IllegalArgumentException("wave '" + id + "' needs an end condition");
        }
        spawns = List.copyOf(spawns);
        pickups = List.copyOf(pickups);
    }

    /**
     * Convenience for the common case — a wave with no placed pickup — kept so every call site that
     * predates issue #318 (across {@code core}'s tests and {@code game}'s content loader) keeps
     * compiling unchanged, the same reasoning {@code SpawnEvent}'s own back-compat constructors use.
     *
     * @param id the content id
     * @param spawns the spawns of this wave
     * @param endCondition what ends this wave
     */
    public SimpleWaveDefinition(String id, List<SpawnEvent> spawns, WaveEndCondition endCondition) {
        this(id, spawns, List.of(), endCondition);
    }
}
