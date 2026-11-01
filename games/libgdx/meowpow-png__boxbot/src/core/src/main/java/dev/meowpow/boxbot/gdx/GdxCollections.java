package dev.meowpow.boxbot.gdx;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ObjectMap;

/**
 * Provides helpers for creating
 * read-only views over LibGDX collections.
 */
public final class GdxCollections {

    private static final ArrayView<Object> EMPTY_VIEW =
            new ArrayView<>(new Array<>(0));

    private static final ObjectMapView<Object, Object> EMPTY_MAP_VIEW =
            new ObjectMapView<>(new ObjectMap<>(0));

    private GdxCollections() {}

    /**
     * Returns a shared empty array view.
     *
     * @param <T> element type
     *
     * @return an empty array view
     */
    @SuppressWarnings("unchecked")
    public static <T> ArrayView<T> emptyView() {
        return (ArrayView<T>) EMPTY_VIEW;
    }

    /**
     * Returns a shared empty object-map view.
     *
     * @param <K> map key type
     * @param <V> map value type
     *
     * @return an empty object-map view
     */
    @SuppressWarnings("unchecked")
    public static <K, V> ObjectMapView<K, V> emptyMapView() {
        return (ObjectMapView<K, V>) EMPTY_MAP_VIEW;
    }

    /**
     * Creates a read-only live view over {@code array}.
     * <p>
     * <strong>API Note:</strong>
     * This method creates a new view instance on
     * each call. Callers that expose the same backing
     * array repeatedly should retain and reuse the returned view.
     *
     * @param array backing array
     * @param <T> element type
     *
     * @return a live view over {@code array}
     * @throws NullPointerException if {@code array} is null
     */
    public static <T> ArrayView<T> viewOf(Array<T> array) {
        return new ArrayView<>(array);
    }

    /**
     * Creates a read-only live view over {@code map}.
     * <p>
     * <strong>API Note:</strong>
     * This method creates a new view instance on
     * each call. Callers that expose the same backing
     * map repeatedly should retain and reuse the returned view.
     *
     * @param map backing map
     * @param <K> map key type
     * @param <V> map value type
     *
     * @return a live view over {@code map}
     * @throws NullPointerException if {@code map} is null
     */
    public static <K, V> ObjectMapView<K, V> viewOf(ObjectMap<K, V> map) {
        return new ObjectMapView<>(map);
    }
}
