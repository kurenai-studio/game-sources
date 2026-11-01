package dev.luchoc.littlespaceship.core.domain.entity;

/**
 * Creation, destruction and validity of entities.
 *
 * <p>Slots are reused, which keeps the component arrays dense, and every reuse bumps the slot
 * generation so old handles stop being valid. Nothing else: an entity carries no data, only
 * identity. The data lives in the component stores.
 *
 * <p>Single-threaded by design, like the whole simulation.
 */
public final class EntityRegistry {

    private static final int INITIAL_CAPACITY = 256;

    /** Current generation per slot. A slot that was never used has generation one. */
    private int[] generations = newGenerations(INITIAL_CAPACITY);

    /** Whether the slot currently holds a live entity. */
    private boolean[] alive = new boolean[INITIAL_CAPACITY];

    /** Slots released by {@link #destroy(int)}, waiting to be handed out again. */
    private int[] freeSlots = new int[INITIAL_CAPACITY];

    private int freeCount;

    /** Number of slots ever handed out, which is where a brand new slot comes from. */
    private int used;

    private int aliveCount;

    /**
     * Creates a new entity.
     *
     * @return its handle, never {@link EntityId#NONE}
     * @throws IllegalStateException if the registry runs out of slots
     */
    public int create() {
        int index;
        if (freeCount > 0) {
            index = freeSlots[--freeCount];
        } else {
            if (used > EntityId.MAX_INDEX) {
                throw new IllegalStateException(
                    "entity limit reached: " + (EntityId.MAX_INDEX + 1));
            }
            index = used++;
            ensureCapacity(used);
        }
        alive[index] = true;
        aliveCount++;
        return EntityId.of(index, generations[index]);
    }

    /**
     * Tells whether a handle still refers to the entity it was created for.
     *
     * @param entity a handle, possibly stale or {@link EntityId#NONE}
     * @return true when the entity is alive and the generation still matches
     */
    public boolean isAlive(int entity) {
        if (entity == EntityId.NONE) {
            return false;
        }
        int index = EntityId.index(entity);
        return index < used
            && alive[index]
            && generations[index] == EntityId.generation(entity);
    }

    /**
     * Destroys an entity and releases its slot. A stale handle is ignored, so destroying twice is
     * harmless rather than corrupting.
     *
     * <p>This does not touch components: the caller removes them. In the simulation that caller is
     * always {@code World.destroyEntity}, which knows every store.
     *
     * @param entity the handle to destroy
     * @return true when something was actually destroyed
     */
    public boolean destroy(int entity) {
        if (!isAlive(entity)) {
            return false;
        }
        int index = EntityId.index(entity);
        alive[index] = false;
        aliveCount--;
        // Wrapping back to one and not to zero keeps handle zero reserved for NONE.
        int next = generations[index] + 1;
        generations[index] = next > EntityId.MAX_GENERATION ? 1 : next;
        if (freeCount == freeSlots.length) {
            freeSlots = grow(freeSlots, freeCount + 1);
        }
        freeSlots[freeCount++] = index;
        return true;
    }

    /**
     * Returns how many entities are alive right now.
     *
     * @return the live entity count
     */
    public int aliveCount() {
        return aliveCount;
    }

    /**
     * Returns how many slots have ever been handed out, which is the size the component stores need
     * to index by slot.
     *
     * @return the number of slots in use, free ones included
     */
    public int slotCount() {
        return used;
    }

    private void ensureCapacity(int needed) {
        if (needed <= generations.length) {
            return;
        }
        int size = generations.length;
        while (size < needed) {
            size <<= 1;
        }
        int[] grownGenerations = new int[size];
        System.arraycopy(generations, 0, grownGenerations, 0, generations.length);
        for (int i = generations.length; i < size; i++) {
            grownGenerations[i] = 1;
        }
        generations = grownGenerations;

        boolean[] grownAlive = new boolean[size];
        System.arraycopy(alive, 0, grownAlive, 0, alive.length);
        alive = grownAlive;
    }

    private static int[] newGenerations(int capacity) {
        int[] generations = new int[capacity];
        for (int i = 0; i < capacity; i++) {
            generations[i] = 1;
        }
        return generations;
    }

    private static int[] grow(int[] array, int needed) {
        int size = array.length;
        while (size < needed) {
            size <<= 1;
        }
        int[] grown = new int[size];
        System.arraycopy(array, 0, grown, 0, array.length);
        return grown;
    }
}
