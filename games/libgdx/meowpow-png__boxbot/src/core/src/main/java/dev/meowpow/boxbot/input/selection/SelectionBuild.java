package dev.meowpow.boxbot.input.selection;

import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.gdx.HotPath;

import org.jspecify.annotations.Nullable;

/**
 * The selection pair being built for the queue.
 */
@HotPath
public final class SelectionBuild {

    private @Nullable SelectionTarget primary;
    private @Nullable SelectionTarget secondary;

    /**
     * Returns the staged primary,
     * or null if nothing is staged.
     */
    public @Nullable SelectionTarget primary() {
        return primary;
    }

    /**
     * Returns the staged secondary,
     * or null if nothing is staged yet.
     */
    public @Nullable SelectionTarget secondary() {
        return secondary;
    }

    /**
     * Sets the staged primary from a hit-test result.
     * <p>
     * Clicking the current staged primary again
     * clears it. A miss leaves the current staging untouched.
     *
     * @param hit the entity the player's click landed on, or null if it hit nothing
     */
    public void stagePrimary(@Nullable SelectionTarget hit) {
        if (hit == null) {
            return;
        }
        primary = hit.equals(primary) ? null : hit;
        secondary = null;
    }

    /**
     * Sets the staged secondary from a hit-test result.
     * <p>
     * No-op unless the staged primary is currently a package.
     * Clicking the current staged secondary again clears it instead of completing.
     *
     * @param hit the entity the player's click landed on, or null if it hit nothing
     *
     * @return the completed pair once both halves are staged, otherwise null
     */
    public @Nullable SelectionPair stageSecondary(@Nullable SelectionTarget hit) {
        if (!(primary instanceof SelectionTarget.WorldPackage) || hit == null) {
            return null;
        }
        secondary = hit.equals(secondary) ? null : hit;
        return secondary != null ? new SelectionPair(primary, secondary) : null;
    }

    /**
     * Clears the pair being staged.
     */
    public void clear() {
        primary = null;
        secondary = null;
    }

    /**
     * Abandons the in-progress build if either
     * half no longer exists in the given world.
     */
    public void pruneStale(World world) {
        if (primary == null) {
            return;
        }
        if (!primary.isPresent(world)) {
            clear();
            return;
        }
        if (secondary != null && !secondary.isPresent(world)) {
            clear();
        }
    }
}
