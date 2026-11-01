package dev.luchoc.littlespaceship.core.domain.component;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.entity.EntityRegistry;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class ComponentStoreTest {

    private final EntityRegistry registry = new EntityRegistry();
    private final ComponentStore<Transform> store = new ComponentStore<>();

    @Test
    @DisplayName("stores and reads a component")
    void storesAndReads() {
        int entity = registry.create();
        Transform transform = new Transform(3f, 4f);

        store.set(entity, transform);

        assertTrue(store.has(entity));
        assertSame(transform, store.get(entity));
        assertEquals(1, store.size());
    }

    @Test
    @DisplayName("an entity without the component reads as absent")
    void absentComponent() {
        int entity = registry.create();

        assertFalse(store.has(entity));
        assertNull(store.get(entity));
        assertEquals(0, store.size());
    }

    @Test
    @DisplayName("setting twice replaces without duplicating the entity")
    void replaces() {
        int entity = registry.create();
        Transform second = new Transform(9f, 9f);

        store.set(entity, new Transform(1f, 1f));
        store.set(entity, second);

        assertSame(second, store.get(entity));
        assertEquals(1, store.size());
    }

    @Test
    @DisplayName("removing detaches the component and compacts the dense array")
    void removes() {
        int first = registry.create();
        int second = registry.create();
        store.set(first, new Transform(1f, 1f));
        store.set(second, new Transform(2f, 2f));

        assertTrue(store.remove(first));

        assertFalse(store.has(first));
        assertTrue(store.has(second));
        assertEquals(1, store.size());
        assertEquals(second, store.entityAt(0));
    }

    @Test
    @DisplayName("removing twice is harmless")
    void removingTwiceIsHarmless() {
        int entity = registry.create();
        store.set(entity, new Transform(0f, 0f));

        assertTrue(store.remove(entity));
        assertFalse(store.remove(entity));
    }

    @Test
    @DisplayName("iteration only visits the entities that hold the component")
    void iteratesHoldersOnly() {
        int withComponent = registry.create();
        registry.create();
        int alsoWithComponent = registry.create();
        store.set(withComponent, new Transform(1f, 0f));
        store.set(alsoWithComponent, new Transform(2f, 0f));

        int visited = 0;
        float sum = 0f;
        for (int i = 0; i < store.size(); i++) {
            visited++;
            sum += store.valueAt(i).x;
            assertTrue(store.has(store.entityAt(i)));
        }

        assertEquals(2, visited);
        assertEquals(3f, sum);
    }

    /**
     * If the store answered a stale handle, a system holding a reference to a destroyed entity
     * would read the component of whoever took over its slot.
     */
    @Test
    @DisplayName("a stale handle does not read the component of the entity that reused its slot")
    void ignoresStaleHandles() {
        int old = registry.create();
        store.set(old, new Transform(1f, 1f));
        store.remove(old);
        registry.destroy(old);

        int reused = registry.create();
        store.set(reused, new Transform(2f, 2f));

        assertFalse(store.has(old));
        assertNull(store.get(old));
        assertEquals(2f, store.get(reused).x);
        assertEquals(1, store.size());
    }

    @Test
    @DisplayName("a slot recycled without removing the component leaves no ghost behind")
    void recycledSlotWithoutRemoval() {
        int old = registry.create();
        store.set(old, new Transform(1f, 1f));
        registry.destroy(old);

        int reused = registry.create();
        store.set(reused, new Transform(2f, 2f));

        assertEquals(1, store.size());
        assertEquals(reused, store.entityAt(0));
        assertEquals(2f, store.valueAt(0).x);
    }

    @Test
    @DisplayName("rejects a null component")
    void rejectsNull() {
        int entity = registry.create();

        assertThrows(IllegalArgumentException.class, () -> store.set(entity, null));
    }

    @Test
    @DisplayName("rejects a position outside the dense array")
    void rejectsBadPosition() {
        assertThrows(IndexOutOfBoundsException.class, () -> store.entityAt(0));
    }

    @Test
    @DisplayName("grows beyond its initial capacity")
    void grows() {
        int count = 2000;
        int[] entities = new int[count];
        for (int i = 0; i < count; i++) {
            entities[i] = registry.create();
            store.set(entities[i], new Transform(i, 0f));
        }

        assertEquals(count, store.size());
        for (int i = 0; i < count; i++) {
            assertEquals(i, store.get(entities[i]).x);
        }
    }
}
