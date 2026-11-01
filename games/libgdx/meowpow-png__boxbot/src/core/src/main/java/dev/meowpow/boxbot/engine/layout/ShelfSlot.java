package dev.meowpow.boxbot.engine.layout;

import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;

import java.util.Objects;

/**
 * A shelf's fixed position in the warehouse layout.
 *
 * @param id the shelf's identifier
 * @param pos the shelf's grid position
 */
public record ShelfSlot(ShelfId id, GridPos pos) {

    /**
     * @throws NullPointerException if {@code id} or {@code pos} is null
     */
    public ShelfSlot {
        Objects.requireNonNull(id, "id must not be null");
        Objects.requireNonNull(pos, "pos must not be null");
    }
}
