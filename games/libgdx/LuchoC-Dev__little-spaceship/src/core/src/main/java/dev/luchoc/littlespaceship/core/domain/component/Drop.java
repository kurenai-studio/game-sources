package dev.luchoc.littlespaceship.core.domain.component;

/**
 * The pickup this specific entity delivers on defeat.
 *
 * <p>Attached directly by {@code SpawnSystem} when a {@code SpawnEvent} is marked with a drop — it
 * is never part of an {@code EnemyDefinition}'s component list, because a designed drop marks one
 * instance of a wave, not every enemy of that archetype. Per {@code 03-game-systems.md}: "a specific
 * enemy within a wave can drop a power-up without making that a universal property of the
 * archetype."
 *
 * <p>Nothing consumes this yet — resolving it into an actual pickup entity when the holder is
 * destroyed is phase 05's {@code PickupSystem}/enemy-defeat work.
 */
public final class Drop {

    /** Content id of what this entity drops, such as {@code "shield"} or {@code "attachment"}. */
    public String pickupId;

    /**
     * @param pickupId content id of what this entity drops
     */
    public Drop(String pickupId) {
        this.pickupId = pickupId;
    }
}
