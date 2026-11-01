package dev.luchoc.littlespaceship.core.port;

/**
 * Name of the graphic an entity is drawn with.
 *
 * <p>The core does not know what a texture, an atlas or a frame rate is: it carries an identifier
 * defined by the content and hands it over when it is time to draw. Resolving it to an actual
 * region is the adapter's job.
 *
 * <p>It is a value and not an enum on purpose: enumerating the art inside the domain would put the
 * core in charge of deciding which sprites exist.
 *
 * @param value the content identifier, such as {@code "ship-basic"}
 */
public record SpriteId(String value) {

    /**
     * Rejects an identifier that names nothing.
     */
    public SpriteId {
        if (value == null || value.isEmpty()) {
            throw new IllegalArgumentException("a sprite id cannot be empty");
        }
    }
}
