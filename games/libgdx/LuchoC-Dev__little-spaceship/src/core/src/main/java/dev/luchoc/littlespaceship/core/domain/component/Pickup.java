package dev.luchoc.littlespaceship.core.domain.component;

/**
 * A collectable lying in the playfield, waiting for the player to reach it.
 *
 * <p>Not the same thing as {@link Drop}. A {@link Drop} marks what an archetype's instance delivers
 * on defeat; a {@code Pickup} is the entity actually collectable, created by {@code CleanupSystem}
 * from that {@link Drop} the moment its holder is destroyed. {@code PickupSystem} is what reads this
 * component once {@code CollisionSystem} reports the player reaching it.
 *
 * <p>{@code kind} carries the same content id as {@link Drop#pickupId} — one of the fixed power-up
 * kinds {@code PickupSystem} recognises, or an attachment's content id, resolved through {@link
 * dev.luchoc.littlespaceship.core.port.ContentSource#attachment(String)}.
 */
public final class Pickup {

    /** What this pickup grants when collected. */
    public String kind;

    /**
     * @param kind content id of what this pickup grants
     */
    public Pickup(String kind) {
        this.kind = kind;
    }
}
