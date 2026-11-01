package dev.meowpow.boxbot.engine.spatial.grid;

import java.util.Objects;

/**
 * A named rectangular region of the grid,
 * used to group and label shelves by area.
 *
 * @param name the zone's label prefix
 * @param min the zone's minimum-coordinate corner, inclusive
 * @param max the zone's maximum-coordinate corner, inclusive
 */
public record Zone(String name, GridPos min, GridPos max) {

    /**
     * @throws NullPointerException if any argument is null
     * @throws IllegalArgumentException if {@code name} is
     * blank or the minimum corner exceeds the maximum corner
     */
    public Zone {
        Objects.requireNonNull(name, "name must not be null");
        if (name.isBlank()) {
            throw new IllegalArgumentException("name must not be blank");
        }
        Objects.requireNonNull(min, "min must not be null");
        Objects.requireNonNull(max, "max must not be null");
        if (min.x() > max.x() || min.y() > max.y()) {
            throw new IllegalArgumentException("min must not exceed max");
        }
    }

    /**
     * Returns whether {@code pos} lies
     * within this zone, inclusive of its bounds.
     */
    public boolean contains(GridPos pos) {
        return pos.x() >= min.x() && pos.x() <= max.x()
                && pos.y() >= min.y() && pos.y() <= max.y();
    }
}
