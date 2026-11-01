package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;

import org.jspecify.annotations.Nullable;

import java.util.Objects;

/**
 * Snapshot of a shelf's occupancy at decision time.
 *
 * @param shelfId the shelf's identifier
 * @param position the shelf's grid position
 * @param occupied whether the shelf currently holds a package
 * @param packageId id of the package occupying the shelf;
 * null when the shelf is unoccupied
 * @param color the occupying package's color; null when unoccupied
 */
public record ShelfView(
        ShelfId shelfId,
        GridPos position,
        boolean occupied,
        @Nullable PackageId packageId,
        @Nullable PackageColor color
) {

    /**
     * @throws NullPointerException if {@code shelfId} or {@code position} is null
     * @throws IllegalArgumentException if {@code occupied} is inconsistent
     * with {@code packageId}, or {@code color}'s presence is inconsistent with {@code packageId}
     */
    public ShelfView {
        Objects.requireNonNull(shelfId, "shelfId must not be null");
        Objects.requireNonNull(position, "position must not be null");
        if (occupied == (packageId == null)) {
            var message = "occupied must match packageId presence: occupied=%s, packageId=%s";
            throw new IllegalArgumentException(message.formatted(occupied, packageId));
        }
        if (packageId == null && color != null) {
            throw new IllegalArgumentException("color must be null when packageId is absent, got " + color);
        }
        if (packageId != null && color == null) {
            throw new IllegalArgumentException("color must be present when packageId is present");
        }
    }
}
