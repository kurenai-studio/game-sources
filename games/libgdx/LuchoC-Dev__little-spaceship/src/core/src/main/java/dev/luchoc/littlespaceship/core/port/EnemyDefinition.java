package dev.luchoc.littlespaceship.core.port;

import java.util.List;

/**
 * An enemy archetype: an id and a list of components, never a class.
 *
 * <p>{@code SpawnSystem} does not know what a tank is. It walks {@link #components()} and, for each
 * spec, looks up a factory by {@link ComponentSpec#name()} in its registry. A tank on the super-fast
 * archetype's trajectory is a data change — editing which trajectory id the {@code "motion"} spec
 * names — never a new Java type.
 */
public interface EnemyDefinition {

    /**
     * @return the content id, in English, matching the sprite name agreed at synchronisation point 2
     */
    String id();

    /**
     * @return the components this archetype is made of, never null
     */
    List<ComponentSpec> components();
}
