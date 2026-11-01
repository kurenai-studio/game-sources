package dev.meowpow.boxbot.input.selection;

import dev.meowpow.boxbot.gdx.HotPath;

import org.jspecify.annotations.Nullable;

import java.util.Objects;

/**
 * Tracks the player's active primary and secondary selection.
 */
@HotPath
public final class SelectionState {

    private @Nullable SelectionTarget primary;
    private @Nullable SelectionTarget secondary;

    private final SelectionBuild build = new SelectionBuild();
    private final SelectionQueue queue;

    /**
     * Creates a state whose queue
     * holds at most {@code queueLimit} pairs.
     *
     * @throws IllegalArgumentException if {@code queueLimit} is not positive
     */
    public SelectionState(int queueLimit) {
        queue = new SelectionQueue(queueLimit);
    }

    /**
     * Returns the current primary
     * selection, or null if nothing is selected.
     */
    public @Nullable SelectionTarget primary() {
        return primary;
    }

    /**
     * Returns the current secondary
     * selection, or null if nothing is selected.
     */
    public @Nullable SelectionTarget secondary() {
        return secondary;
    }

    /**
     * Returns the pair being built for the queue.
     */
    public SelectionBuild build() {
        return build;
    }

    /**
     * Returns the queue of pairs waiting
     * to run once the active selection is done.
     */
    public SelectionQueue queue() {
        return queue;
    }

    /**
     * Sets the primary selection from a
     * hit-test result, clearing the secondary selection.
     * <p>
     * Clicking the current primary selection again clears it.
     * A miss leaves the current selection untouched.
     *
     * @param hit the entity the player's click landed on, or null if it hit nothing
     */
    public void select(@Nullable SelectionTarget hit) {
        if (hit == null) {
            return;
        }
        primary = hit.equals(primary) ? null : hit;
        secondary = null;
    }

    /**
     * Sets the secondary selection from a hit-test result.
     * <p>
     * No-op unless the primary selection is currently a package.
     * Clicking the current secondary selection again clears it.
     * A miss leaves the current selection untouched.
     *
     * @param hit the entity the player's click landed on, or null if it hit nothing
     */
    public void selectSecondary(@Nullable SelectionTarget hit) {
        if (!(primary instanceof SelectionTarget.WorldPackage)) {
            return;
        }
        if (hit == null) {
            return;
        }
        secondary = hit.equals(secondary) ? null : hit;
    }

    /**
     * Sets the secondary selection directly,
     * regardless of the primary selection.
     * <p>
     * Re-selecting the same target has no effect.
     *
     * @param hit the entity the player's click landed on, or null to clear it
     */
    public void redirectSecondary(@Nullable SelectionTarget hit) {
        secondary = hit;
    }

    /**
     * Sets the primary and secondary selection
     * directly to {@code pair}'s targets.
     *
     * @throws NullPointerException if {@code pair} is null
     */
    public void activateQueuedPair(SelectionPair pair) {
        Objects.requireNonNull(pair, "pair must not be null");
        primary = pair.primary();
        secondary = pair.secondary();
    }

    /**
     * Clears only the primary selection,
     * leaving the secondary selection untouched.
     */
    public void clearPrimary() {
        primary = null;
    }

    /**
     * Clears only the secondary selection.
     * <p>
     * Not gated on the primary selection being a package.
     * <p>
     * <strong>API Note:</strong>
     * Meant for invalidating a stale
     * secondary, not for choosing a new one.
     */
    public void clearSecondary() {
        secondary = null;
    }
}
