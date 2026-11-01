package dev.luchoc.littlespaceship.core.port;

/**
 * An attachment type: an id and how many hits it absorbs before being destroyed.
 *
 * <p>Durability is data and not a rule fixed in code, per {@code 03-game-systems.md}: "by default
 * all attachments share the same durability, but that value is data per attachment and not a rule
 * fixed in code; it must be possible to raise it for cases such as a protection attachment." Looking
 * it up by id, the same way {@link EnemyDefinition} and {@link TrajectoryDefinition} are, is what
 * makes a tougher attachment a content change instead of a code change.
 */
public interface AttachmentDefinition {

    /**
     * @return the content id, the same string {@code PickupSystem} reads from {@code Pickup.kind}
     */
    String id();

    /**
     * @return hits this attachment absorbs before being destroyed, strictly positive
     */
    int durability();
}
