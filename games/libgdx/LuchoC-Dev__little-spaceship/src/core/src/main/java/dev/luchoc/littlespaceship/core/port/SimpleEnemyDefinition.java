package dev.luchoc.littlespaceship.core.port;

import java.util.List;

/**
 * The straightforward {@link EnemyDefinition}: an id plus the exact component list handed in.
 *
 * <p>Reused by the loader in {@code game}, which builds one per entry of {@code enemies.json}, and
 * by core tests, which build archetypes inline without reading a file.
 *
 * @param id the content id
 * @param components the components this archetype is made of
 */
public record SimpleEnemyDefinition(String id, List<ComponentSpec> components) implements EnemyDefinition {

    /**
     * Rejects a definition that names nothing or lists no component.
     */
    public SimpleEnemyDefinition {
        if (id == null || id.isEmpty()) {
            throw new IllegalArgumentException("an enemy definition needs an id");
        }
        if (components == null || components.isEmpty()) {
            throw new IllegalArgumentException("enemy '" + id + "' has no components");
        }
        components = List.copyOf(components);
    }
}
