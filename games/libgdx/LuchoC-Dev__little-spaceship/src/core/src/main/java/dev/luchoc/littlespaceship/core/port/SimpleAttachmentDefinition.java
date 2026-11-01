package dev.luchoc.littlespaceship.core.port;

/**
 * The straightforward {@link AttachmentDefinition}.
 *
 * @param id the content id
 * @param durability hits this attachment absorbs before being destroyed
 */
public record SimpleAttachmentDefinition(String id, int durability) implements AttachmentDefinition {

    /**
     * Rejects an attachment that names nothing or that could never be destroyed by a hit.
     */
    public SimpleAttachmentDefinition {
        if (id == null || id.isEmpty()) {
            throw new IllegalArgumentException("an attachment definition needs an id");
        }
        if (durability <= 0) {
            throw new IllegalArgumentException(
                "attachment '" + id + "' needs a durability strictly greater than zero");
        }
    }
}
