package dev.luchoc.littlespaceship.core.port;

/**
 * A pickup content places directly, with no enemy carrying it — a reward tied to reaching a place
 * and a moment, not to a kill. Per issue #255: "a reward the player flies to rather than one that
 * falls out of something they shot."
 *
 * <p>Deliberately shaped like {@link SpawnEvent}, the other kind of timestamped thing a {@link
 * WaveDefinition} places: {@code at} means exactly what {@link SpawnEvent#at()} means, seconds
 * since the wave carrying it started, never an absolute level time. Living on {@link
 * WaveDefinition} rather than as a level-level list of its own is what lets {@code SpawnSystem}
 * schedule it with the {@code ActiveWave} clock and cursor that already exist for spawns, instead
 * of a second scheduling mechanism for a capability with exactly this one shape of user.
 *
 * <p>Whether {@code kind} actually names one of {@code PickupSystem}'s six recognised kinds is not
 * checked here — the same reason a {@link SpawnEvent#dropId()} is not checked by that record
 * either: {@code SpawnSystem} is the one place with a real answer, and it fails the moment this
 * placement is due, naming this wave's id and this timestamp, the same way an unrecognised {@code
 * Drop} already does for an enemy's designed drop.
 *
 * @param at seconds since the wave that carries it started, when this pickup enters the world
 * @param kind which of {@code PickupSystem}'s six recognised kinds this is, resolved by {@code
 *     Pickup.kind} exactly like an enemy's {@link SpawnEvent#dropId()} is
 * @param atX the pickup's horizontal position, a fraction of the playfield width in {@code [0, 1]},
 *     0 at the left edge and 1 at the right — the same convention {@link SpawnEvent#atX()} uses
 * @param atY the pickup's vertical position, a fraction of the playfield height in {@code [0, 1]},
 *     0 at the bottom edge and 1 at the top — {@code Transform.y} grows upward, per {@code
 *     SpawnSystem.PLAYFIELD_HEIGHT}'s own convention
 */
public record PlacedPickup(float at, String kind, float atX, float atY) {

    /**
     * Rejects a malformed placement: a negative or non-finite timestamp, a missing kind, or a
     * position outside the playfield. Mirrors {@link SpawnEvent}'s own constructor checks.
     */
    public PlacedPickup {
        if (at < 0f || Float.isNaN(at) || Float.isInfinite(at)) {
            throw new IllegalArgumentException("a placed pickup needs a finite, non-negative timestamp");
        }
        if (kind == null || kind.isEmpty()) {
            throw new IllegalArgumentException("a placed pickup at " + at + "s needs a kind");
        }
        if (atX < 0f || atX > 1f || Float.isNaN(atX)) {
            throw new IllegalArgumentException(
                "placed pickup at " + at + "s has atX " + atX + ", outside [0, 1]");
        }
        if (atY < 0f || atY > 1f || Float.isNaN(atY)) {
            throw new IllegalArgumentException(
                "placed pickup at " + at + "s has atY " + atY + ", outside [0, 1]");
        }
    }
}
