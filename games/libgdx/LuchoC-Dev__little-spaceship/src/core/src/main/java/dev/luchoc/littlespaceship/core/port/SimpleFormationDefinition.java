package dev.luchoc.littlespaceship.core.port;

import java.util.List;

/**
 * The straightforward {@link FormationDefinition}.
 *
 * @param id the content id
 * @param slots the slots of this formation
 */
public record SimpleFormationDefinition(String id, List<FormationSlot> slots) implements FormationDefinition {

    /**
     * Rejects a formation that names nothing or has no slot to spawn into.
     */
    public SimpleFormationDefinition {
        if (id == null || id.isEmpty()) {
            throw new IllegalArgumentException("a formation needs an id");
        }
        if (slots == null || slots.isEmpty()) {
            throw new IllegalArgumentException("formation '" + id + "' has no slots");
        }
        slots = List.copyOf(slots);
    }
}
