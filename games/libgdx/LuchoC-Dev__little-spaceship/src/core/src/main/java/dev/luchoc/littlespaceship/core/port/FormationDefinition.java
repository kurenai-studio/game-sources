package dev.luchoc.littlespaceship.core.port;

import java.util.List;

/**
 * The shape a wave spawns in: line, diagonal, single, or whatever a level needs.
 *
 * <p>A formation is unrelated to the archetype spawning in it. {@code SpawnSystem} creates one entity
 * per slot, all of the same {@link EnemyDefinition}, positioned at the wave's anchor plus that slot's
 * offset — which is what keeps formation and archetype independent and combinable, per
 * {@code 03-game-systems.md}.
 */
public interface FormationDefinition {

    /**
     * @return the content id
     */
    String id();

    /**
     * @return the slots of this formation, never null or empty
     */
    List<FormationSlot> slots();
}
