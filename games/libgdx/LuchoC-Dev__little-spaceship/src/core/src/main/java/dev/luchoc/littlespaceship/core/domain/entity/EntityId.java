package dev.luchoc.littlespaceship.core.domain.entity;

/**
 * Packing of an entity handle into a single {@code int}.
 *
 * <p>An entity is not a slot number but a slot number plus a generation. When a slot is recycled
 * its generation moves on, so a handle kept from a destroyed entity stops matching and can be
 * detected instead of silently pointing at whatever occupies the slot now. That class of bug is
 * hard to find and easy to prevent.
 *
 * <p>Layout: generation in the upper 16 bits, index in the lower 16. Generations start at one, so
 * the value zero can never be a valid handle and works as {@link #NONE}.
 *
 * <p>Static methods with no state: this is a codec, not a service.
 */
public final class EntityId {

    /** The absence of an entity. Never returned by a live handle. */
    public static final int NONE = 0;

    /** Number of bits reserved for the slot index, which caps live entities at 65536. */
    public static final int INDEX_BITS = 16;

    /** Highest slot index, one below the cap. */
    public static final int MAX_INDEX = (1 << INDEX_BITS) - 1;

    /** Highest generation before wrapping back to one. */
    public static final int MAX_GENERATION = (1 << (32 - INDEX_BITS)) - 1;

    private static final int INDEX_MASK = MAX_INDEX;

    private EntityId() {
    }

    /**
     * Builds a handle from its two parts.
     *
     * @param index the slot index, between 0 and {@link #MAX_INDEX}
     * @param generation the slot generation, between 1 and {@link #MAX_GENERATION}
     * @return the packed handle
     */
    public static int of(int index, int generation) {
        return (generation << INDEX_BITS) | (index & INDEX_MASK);
    }

    /**
     * Returns the slot the handle points at.
     *
     * @param entity a packed handle
     * @return the slot index
     */
    public static int index(int entity) {
        return entity & INDEX_MASK;
    }

    /**
     * Returns the generation the handle was created with.
     *
     * @param entity a packed handle
     * @return the generation
     */
    public static int generation(int entity) {
        return entity >>> INDEX_BITS;
    }

    /**
     * Renders a handle in a readable form, for test messages and logs.
     *
     * @param entity a packed handle
     * @return a description such as {@code entity[12 gen 3]}
     */
    public static String describe(int entity) {
        if (entity == NONE) {
            return "entity[none]";
        }
        return "entity[" + index(entity) + " gen " + generation(entity) + "]";
    }
}
