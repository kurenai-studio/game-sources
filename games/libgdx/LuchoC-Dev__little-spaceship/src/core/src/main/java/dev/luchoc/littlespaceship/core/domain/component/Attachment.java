package dev.luchoc.littlespaceship.core.domain.component;

/**
 * The player's single equipped attachment: the third defensive layer, after the shield.
 *
 * <p>Durability is data and not a rule fixed in code: the MVP's attachments absorb exactly one hit,
 * but a tougher protective attachment must be supportable later with no code change. The component
 * is removed once durability reaches zero, which is what destroys the attachment and avoids the life
 * that hit would otherwise have cost.
 *
 * <p>{@link #id} is the content id {@code PickupSystem} resolved through {@code
 * ContentSource#attachment(String)} to equip this instance — the same string {@link
 * dev.luchoc.littlespaceship.core.port.AttachmentDefinition#id()} returns. Nothing inside the core
 * reads it back: the chain only ever consults {@link #durability}. It exists so presentation can
 * name what is equipped without reaching into content itself, which {@code WorldView} never exposes.
 */
public final class Attachment {

    /** The content id this attachment was equipped from. */
    public final String id;

    /** Hits left before the attachment is destroyed. */
    public int durability;

    /**
     * Creates an equipped attachment.
     *
     * @param id the content id it was equipped from, never null or empty
     * @param durability hits it can absorb before being destroyed, strictly positive
     */
    public Attachment(String id, int durability) {
        if (id == null || id.isEmpty()) {
            throw new IllegalArgumentException("an attachment needs a content id");
        }
        this.id = id;
        this.durability = durability;
    }
}
