package dev.luchoc.littlespaceship.core.domain.content;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.port.ComponentSpec;

/**
 * Turns one {@link ComponentSpec} into a real component, attached to an entity.
 *
 * <p>Registered by name in a {@link ComponentFactoryRegistry}. This is the one seam where content
 * data becomes ECS state — everything before it is opaque strings and numbers, everything after it
 * is a typed component a system can read.
 */
@FunctionalInterface
public interface ComponentFactory {

    /**
     * Reads {@code spec} and attaches the component it describes to {@code entity}.
     *
     * @param world the world to attach into, and the source of any content this factory needs to
     *     resolve further, such as a trajectory referenced by id
     * @param entity the entity to attach to
     * @param spec the parameters to read
     * @throws IllegalArgumentException if a required field is missing or names something unresolvable
     */
    void attach(World world, int entity, ComponentSpec spec);
}
