package dev.meowpow.boxbot.gdx;

import com.badlogic.gdx.utils.Array;

import java.util.NoSuchElementException;
import java.util.Objects;

/**
 * Read-only live view over a LibGDX {@link Array}.
 *
 * <p>
 * <strong>API Note:</strong>
 * The view does not copy the backing
 * array and reflects changes made to it.
 */
public final class ArrayView<T> {

    private final Array<T> backing;

    ArrayView(Array<T> backing) {
        Objects.requireNonNull(backing, "backing array must not be null");
        this.backing = backing;
    }

    /**
     * Returns the number of elements in this view.
     */
    public int size() {
        return backing.size;
    }

    /**
     * Returns whether this view contains no elements.
     */
    public boolean isEmpty() {
        return backing.size == 0;
    }

    /**
     * Returns the element at {@code index}.
     * <p>
     * <strong>Implementation Note:</strong>
     * Delegates bounds checking to the backing array
     * so its logical size, rather than capacity, is enforced.
     *
     * @param index element index
     *
     * @return the element at {@code index}
     * @throws IndexOutOfBoundsException if {@code index} is outside the view
     */
    public T get(int index) {
        return backing.get(index);
    }

    /**
     * Returns the first element.
     *
     * @return the first element
     * @throws NoSuchElementException if the view is empty
     */
    public T first() {
        if (backing.size == 0) {
            throw new NoSuchElementException();
        }
        return backing.items[0];
    }

    /**
     * Returns the last element.
     *
     * @return the last element
     * @throws NoSuchElementException if the view is empty
     */
    public T last() {
        if (backing.size == 0) {
            throw new NoSuchElementException();
        }
        return backing.items[backing.size - 1];
    }
}
