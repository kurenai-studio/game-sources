package dev.luchoc.littlespaceship.core.domain.entity;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class EntityRegistryTest {

    private final EntityRegistry registry = new EntityRegistry();

    @Test
    @DisplayName("a created entity is alive and is never the none handle")
    void createsLiveEntities() {
        int entity = registry.create();

        assertTrue(registry.isAlive(entity));
        assertNotEquals(EntityId.NONE, entity);
        assertEquals(1, registry.aliveCount());
    }

    @Test
    @DisplayName("handles are unique while they are alive")
    void handlesAreUnique() {
        int first = registry.create();
        int second = registry.create();

        assertNotEquals(first, second);
        assertTrue(registry.isAlive(first));
        assertTrue(registry.isAlive(second));
    }

    @Test
    @DisplayName("a destroyed entity stops being alive")
    void destroysEntities() {
        int entity = registry.create();

        assertTrue(registry.destroy(entity));
        assertFalse(registry.isAlive(entity));
        assertEquals(0, registry.aliveCount());
    }

    /**
     * The reason the handle carries a generation. Without it, a reference kept from a destroyed
     * entity would silently start pointing at whoever landed on the recycled slot, which is the
     * kind of bug that only shows up as something impossible on screen.
     */
    @Test
    @DisplayName("a handle from a destroyed entity does not match the one that reuses its slot")
    void detectsStaleHandles() {
        int old = registry.create();
        registry.destroy(old);

        int reused = registry.create();

        assertEquals(EntityId.index(old), EntityId.index(reused), "the slot should be recycled");
        assertNotEquals(old, reused);
        assertFalse(registry.isAlive(old));
        assertTrue(registry.isAlive(reused));
    }

    @Test
    @DisplayName("destroying twice is harmless")
    void destroyingTwiceIsHarmless() {
        int entity = registry.create();

        assertTrue(registry.destroy(entity));
        assertFalse(registry.destroy(entity));
        assertEquals(0, registry.aliveCount());
    }

    @Test
    @DisplayName("the none handle is never alive")
    void noneIsNeverAlive() {
        assertFalse(registry.isAlive(EntityId.NONE));
        assertFalse(registry.destroy(EntityId.NONE));
    }

    @Test
    @DisplayName("slots are reused instead of growing without limit")
    void reusesSlots() {
        for (int i = 0; i < 1000; i++) {
            int entity = registry.create();
            registry.destroy(entity);
        }

        assertEquals(1, registry.slotCount());
        assertEquals(0, registry.aliveCount());
    }

    @Test
    @DisplayName("holds the hundreds of entities the MVP needs, and then some")
    void holdsManyEntities() {
        int[] entities = new int[5000];
        for (int i = 0; i < entities.length; i++) {
            entities[i] = registry.create();
        }

        assertEquals(entities.length, registry.aliveCount());
        for (int entity : entities) {
            assertTrue(registry.isAlive(entity), EntityId.describe(entity) + " should be alive");
        }
    }

    @Test
    @DisplayName("the packing survives a round trip")
    void packingRoundTrip() {
        int entity = EntityId.of(4321, 7);

        assertEquals(4321, EntityId.index(entity));
        assertEquals(7, EntityId.generation(entity));
    }
}
