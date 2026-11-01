package dev.meowpow.boxbot.input.selection;

import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.GdxCollections;
import dev.meowpow.boxbot.gdx.HotPath;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.utils.Array;

import java.util.Objects;

/**
 * A FIFO queue of selection pairs
 * waiting to run once the robot is free.
 */
@HotPath
public final class SelectionQueue {

    private final int limit;
    private final Array<SelectionPair> pairs;
    private final ArrayView<SelectionPair> pairsView;

    /**
     * Creates a queue that holds at most {@code limit} pairs.
     *
     * @throws IllegalArgumentException if {@code limit} is not positive
     */
    public SelectionQueue(int limit) {
        if (limit <= 0) {
            throw new IllegalArgumentException("limit must be > 0, got " + limit);
        }
        this.limit = limit;
        this.pairs = new Array<>(limit);
        this.pairsView = GdxCollections.viewOf(pairs);
    }

    /**
     * Returns the queued pairs, in
     * the order they'll be dispatched.
     */
    public ArrayView<SelectionPair> pairs() {
        return pairsView;
    }

    /**
     * Adds the given pair or removes an already-queued
     * pair with the same primary target if one exists.
     * <p>
     * No-op if the queue is already at
     * capacity and no matching pair exists.
     *
     * @return true if the queue changed
     * @throws NullPointerException if {@code pair} is null
     */
    public boolean toggle(SelectionPair pair) {
        Objects.requireNonNull(pair, "pair must not be null");
        if (remove(pair.primary())) {
            return true;
        }
        if (pairs.size >= limit) {
            return false;
        }
        pairs.add(pair);
        return true;
    }

    /**
     * Removes the queued pair whose primary
     * matches the given primary target, if any.
     *
     * @return true if a queued pair was removed
     */
    public boolean remove(SelectionTarget primaryTarget) {
        var index = indexOfPrimary(primaryTarget);
        if (index < 0) {
            return false;
        }
        pairs.removeIndex(index);
        return true;
    }

    /**
     * Removes the queued pair whose secondary
     * matches the given secondary target, if any.
     *
     * @return true if a queued pair was removed
     */
    public boolean removeBySecondary(SelectionTarget secondaryTarget) {
        var index = indexOfSecondary(secondaryTarget);
        if (index < 0) {
            return false;
        }
        pairs.removeIndex(index);
        return true;
    }

    /**
     * Removes and returns the front
     * pair, or null if the queue is empty.
     */
    public @Nullable SelectionPair pollFirst() {
        if (pairs.size == 0) {
            return null;
        }
        return pairs.removeIndex(0);
    }

    /**
     * Drops queued pairs whose primary
     * or secondary no longer exists in the given world.
     */
    public void pruneStale(World world) {
        for (int i = pairs.size - 1; i >= 0; i--) {
            var pair = pairs.get(i);
            if (!pair.primary().isPresent(world) || !pair.secondary().isPresent(world)) {
                pairs.removeIndex(i);
            }
        }
    }

    private int indexOfPrimary(SelectionTarget primaryTarget) {
        for (int i = 0; i < pairs.size; i++) {
            if (pairs.get(i).primary().equals(primaryTarget)) {
                return i;
            }
        }
        return -1;
    }

    private int indexOfSecondary(SelectionTarget secondaryTarget) {
        for (int i = 0; i < pairs.size; i++) {
            if (pairs.get(i).secondary().equals(secondaryTarget)) {
                return i;
            }
        }
        return -1;
    }
}
