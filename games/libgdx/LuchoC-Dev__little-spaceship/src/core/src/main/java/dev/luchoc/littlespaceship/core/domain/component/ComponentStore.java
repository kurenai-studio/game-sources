package dev.luchoc.littlespaceship.core.domain.component;

import dev.luchoc.littlespaceship.core.domain.entity.EntityId;

/**
 * Storage of one component type, indexed by entity.
 *
 * <p>Two arrays and nothing more. A sparse one, indexed by slot, answers "does this entity have the
 * component" in constant time; a dense one lets a system walk every holder without touching entities
 * that do not have it and without allocating an iterator. The MVP moves a few hundred entities, so
 * anything beyond this would be machinery without a case.
 *
 * <p>Iteration is by index:
 *
 * <pre>{@code
 * for (int i = 0; i < motions.size(); i++) {
 *     int entity = motions.entityAt(i);
 *     Motion motion = motions.valueAt(i);
 * }
 * }</pre>
 *
 * <p>Removing during that loop reorders the dense array and would skip an element. Systems do not
 * do it: destruction is marked and resolved by the cleanup stage, which is the last one in the
 * pipeline precisely so nothing iterates afterwards.
 *
 * @param <T> the component type held by this store
 */
public final class ComponentStore<T> {

    private static final int INITIAL_CAPACITY = 256;
    private static final int ABSENT = -1;

    /** Component per slot, null when the slot has none. */
    private Object[] values = new Object[INITIAL_CAPACITY];

    /** Handle that owns each slot, so a stale handle does not read a recycled component. */
    private int[] owners = new int[INITIAL_CAPACITY];

    /** Position of each slot inside the dense array, or {@link #ABSENT}. */
    private int[] positions = filled(INITIAL_CAPACITY);

    /** Handles that hold the component, packed with no gaps. */
    private int[] dense = new int[INITIAL_CAPACITY];

    private int size;

    /**
     * Attaches a component to an entity, replacing whatever it had.
     *
     * @param entity the owning entity
     * @param value the component, never null
     */
    public void set(int entity, T value) {
        if (value == null) {
            throw new IllegalArgumentException("a component cannot be null");
        }
        int index = EntityId.index(entity);
        ensureCapacity(index + 1);
        int position = positions[index];
        if (position == ABSENT) {
            if (size == dense.length) {
                dense = grow(dense, size + 1);
            }
            positions[index] = size;
            dense[size++] = entity;
        } else if (owners[index] != entity) {
            // The slot was recycled by a new generation without the old component being removed.
            // Overwriting the dense entry keeps the array free of handles nobody can resolve.
            dense[position] = entity;
        }
        values[index] = value;
        owners[index] = entity;
    }

    /**
     * Tells whether the entity holds this component.
     *
     * @param entity the handle to check
     * @return true when the component is present and belongs to this exact handle
     */
    public boolean has(int entity) {
        int index = EntityId.index(entity);
        return entity != EntityId.NONE
            && index < positions.length
            && owners[index] == entity
            && positions[index] != ABSENT;
    }

    /**
     * Returns the component of an entity.
     *
     * @param entity the handle to read
     * @return the component, or null when the entity does not have it
     */
    @SuppressWarnings("unchecked")
    public T get(int entity) {
        return has(entity) ? (T) values[EntityId.index(entity)] : null;
    }

    /**
     * Detaches the component from an entity. Doing it twice is harmless.
     *
     * @param entity the handle to strip
     * @return true when something was actually removed
     */
    public boolean remove(int entity) {
        if (!has(entity)) {
            return false;
        }
        int index = EntityId.index(entity);
        int position = positions[index];
        int last = dense[--size];
        dense[position] = last;
        positions[EntityId.index(last)] = position;
        positions[index] = ABSENT;
        values[index] = null;
        owners[index] = EntityId.NONE;
        return true;
    }

    /**
     * Returns how many entities hold this component.
     *
     * @return the number of holders
     */
    public int size() {
        return size;
    }

    /**
     * Returns the entity at a position of the dense array.
     *
     * @param position a value between 0 and {@link #size()} - 1
     * @return the entity handle at that position
     */
    public int entityAt(int position) {
        if (position < 0 || position >= size) {
            throw new IndexOutOfBoundsException("position " + position + " of " + size);
        }
        return dense[position];
    }

    /**
     * Returns the component at a position of the dense array.
     *
     * @param position a value between 0 and {@link #size()} - 1
     * @return the component at that position
     */
    @SuppressWarnings("unchecked")
    public T valueAt(int position) {
        return (T) values[EntityId.index(entityAt(position))];
    }

    private void ensureCapacity(int needed) {
        if (needed <= values.length) {
            return;
        }
        int capacity = values.length;
        while (capacity < needed) {
            capacity <<= 1;
        }
        Object[] grownValues = new Object[capacity];
        System.arraycopy(values, 0, grownValues, 0, values.length);
        values = grownValues;

        owners = grow(owners, capacity);

        int[] grownPositions = filled(capacity);
        System.arraycopy(positions, 0, grownPositions, 0, positions.length);
        positions = grownPositions;
    }

    private static int[] filled(int capacity) {
        int[] array = new int[capacity];
        for (int i = 0; i < capacity; i++) {
            array[i] = ABSENT;
        }
        return array;
    }

    private static int[] grow(int[] array, int needed) {
        int capacity = array.length;
        while (capacity < needed) {
            capacity <<= 1;
        }
        int[] grown = new int[capacity];
        System.arraycopy(array, 0, grown, 0, array.length);
        return grown;
    }
}
