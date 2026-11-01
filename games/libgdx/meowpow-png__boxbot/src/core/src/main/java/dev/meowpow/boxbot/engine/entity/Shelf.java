package dev.meowpow.boxbot.engine.entity;

import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.gdx.HotPath;

import org.jspecify.annotations.Nullable;

import java.util.Objects;

/**
 * A fixed storage location holding at most one package at a time.
 */
@HotPath
public final class Shelf {

    private final ShelfId id;
    private final GridPos position;
    private final String label;
    private @Nullable Package occupyingPackage;

    /**
     * Creates an empty shelf at the given position.
     *
     * @param id the shelf's identifier
     * @param position the shelf's grid position
     * @param label the shelf's display label
     *
     * @throws NullPointerException if {@code id}, {@code position}, or {@code label} is null
     */
    public Shelf(ShelfId id, GridPos position, String label) {
        this.id = Objects.requireNonNull(id, "id must not be null");
        this.position = Objects.requireNonNull(position, "position must not be null");
        this.label = Objects.requireNonNull(label, "label must not be null");
    }

    /**
     * Returns the shelf's identifier.
     */
    public ShelfId id() {
        return id;
    }

    /**
     * Returns the shelf's grid position.
     */
    public GridPos position() {
        return position;
    }

    /**
     * Returns the shelf's display label.
     */
    public String label() {
        return label;
    }

    /**
     * Returns the package currently
     * stored here, or null if the shelf is empty.
     */
    @Nullable
    public Package occupyingPackage() {
        return occupyingPackage;
    }

    /**
     * Sets the package currently stored here.
     *
     * @param occupyingPackage the package to
     * store here, or null to mark the shelf empty
     */
    public void setOccupyingPackage(@Nullable Package occupyingPackage) {
        this.occupyingPackage = occupyingPackage;
    }

    @Override
    public String toString() {
        return "Shelf[id=%s, position=%s, label=%s, occupyingPackage=%s]".formatted(
                id,
                position,
                label,
                occupyingPackage
        );
    }
}
