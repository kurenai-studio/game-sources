package dev.meowpow.boxbot.gdx;

import com.badlogic.gdx.utils.ObjectMap;

import java.util.Objects;

/**
 * Read-only live view over a LibGDX {@link ObjectMap}.
 * <p>
 * <strong>API Note:</strong>
 * The view does not copy the backing
 * map and reflects changes made to it.
 *
 * @param <K> map key type
 * @param <V> map value type
 */
public final class ObjectMapView<K, V> {

    private final ObjectMap<K, V> backing;

    ObjectMapView(ObjectMap<K, V> backing) {
        Objects.requireNonNull(backing, "backing map must not be null");
        this.backing = backing;
    }

    /**
     * Returns the number of entries in this view.
     */
    public int size() {
        return backing.size;
    }

    /**
     * Returns whether this view contains no entries.
     */
    public boolean isEmpty() {
        return backing.isEmpty();
    }

    /**
     * Returns whether this view contains {@code key}.
     *
     * @param key the key to find
     */
    public boolean containsKey(K key) {
        return backing.containsKey(key);
    }

    /**
     * Returns the value associated with {@code key}.
     *
     * @param key the key to find
     *
     * @return value associated with {@code key} or null when absent
     */
    public V get(K key) {
        return backing.get(key);
    }

    /**
     * Returns the value associated with {@code key}.
     *
     * @param key the key to find
     * @param defaultValue value returned when {@code key} is absent
     *
     * @return value associated with {@code key}
     * or {@code defaultValue} when absent
     */
    public V get(K key, V defaultValue) {
        return backing.get(key, defaultValue);
    }
}
