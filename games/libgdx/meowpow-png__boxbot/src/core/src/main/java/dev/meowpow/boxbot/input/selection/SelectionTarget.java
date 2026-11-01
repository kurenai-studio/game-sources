package dev.meowpow.boxbot.input.selection;

import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.ChargingStation;
import dev.meowpow.boxbot.engine.entity.LoadingBay;
import dev.meowpow.boxbot.engine.entity.Shelf;
import dev.meowpow.boxbot.engine.spatial.grid.TileBounds;
import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.gdx.ArrayView;

import com.badlogic.gdx.math.Rectangle;

import java.util.Objects;

/**
 * A selectable world entity the player clicked on.
 */
public sealed interface SelectionTarget {

    /**
     * Sets {@code out} to this target's pixel bounds.
     *
     * @param out the rectangle to populate
     * @param tileSize the map's tile size, in pixels
     */
    default void bounds(Rectangle out, TileSize tileSize) {
        switch (this) {
            case ShelfPackage(var shelf) -> {
                var position = shelf.position();
                TileBounds.set(out, position, tileSize);
            }
            case BayPackage(var placement) -> {
                var position = placement.position();
                TileBounds.set(out, position, tileSize);
            }
            case Station(var station) -> {
                var footprint = station.footprint();
                TileBounds.set(out, footprint, tileSize);
            }
            case EmptyShelf(var shelf) -> {
                var position = shelf.position();
                TileBounds.set(out, position, tileSize);
            }
            case BayDestination(var loadingBay) -> {
                var footprint = loadingBay.footprint();
                TileBounds.set(out, footprint, tileSize);
            }
        }
    }

    /**
     * Returns whether this target is still there,
     * rather than having since been removed from the world.
     *
     * @param world the world to check against
     */
    default boolean isPresent(World world) {
        return switch (this) {
            case ShelfPackage(var shelf) -> shelf.occupyingPackage() != null;
            case BayPackage(var placement) -> isInBay(world.loadingBay(), placement);
            case Station ignored -> true;
            case EmptyShelf(var shelf) -> shelf.occupyingPackage() == null;
            case BayDestination(var loadingBay) -> loadingBay.freeTiles() > 0;
        };
    }

    /**
     * Returns whether this target can
     * currently be relocated to a different shelf.
     *
     * @param world the world to check against
     */
    default boolean canRelocate(World world) {
        return switch (this) {
            case ShelfPackage ignored -> true;
            case BayPackage(var placement) -> contains(
                    world.loadingBay().incomingPackagePlacements(), placement
            );
            case Station ignored -> false;
            case EmptyShelf ignored -> false;
            case BayDestination ignored -> false;
        };
    }

    private static boolean isInBay(LoadingBay bay, LoadingBay.PackagePlacement placement) {
        var inPlacements = bay.incomingPackagePlacements();
        var outPlacements = bay.outgoingPackagePlacements();

        return contains(inPlacements, placement) || contains(outPlacements, placement);
    }

    private static boolean contains(
            ArrayView<LoadingBay.PackagePlacement> placements,
            LoadingBay.PackagePlacement placement
    ) {
        for (int i = 0; i < placements.size(); i++) {
            if (placements.get(i).equals(placement)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Represents a package sitting in the world.
     */
    sealed interface WorldPackage extends SelectionTarget {}

    /**
     * A package sitting on a shelf.
     *
     * @param shelf the occupied shelf
     */
    record ShelfPackage(Shelf shelf) implements WorldPackage {

        /**
         * @throws NullPointerException if {@code shelf} is null
         */
        public ShelfPackage {
            Objects.requireNonNull(shelf, "shelf must not be null");
        }
    }

    /**
     * A package sitting in the loading bay,
     * awaiting storage or shipment.
     *
     * @param placement the package's loading-bay placement
     */
    record BayPackage(LoadingBay.PackagePlacement placement) implements WorldPackage {

        /**
         * @throws NullPointerException if {@code placement} is null
         */
        public BayPackage {
            Objects.requireNonNull(placement, "placement must not be null");
        }
    }

    /**
     * The charging station.
     *
     * @param station the charging station
     */
    record Station(ChargingStation station) implements SelectionTarget {

        /**
         * @throws NullPointerException if {@code station} is null
         */
        public Station {
            Objects.requireNonNull(station, "station must not be null");
        }
    }

    /**
     * An empty shelf, selectable as a destination
     * while a relocatable package is the primary selection.
     *
     * @param shelf the empty shelf
     */
    record EmptyShelf(Shelf shelf) implements SelectionTarget {

        /**
         * @throws NullPointerException if {@code shelf} is null
         */
        public EmptyShelf {
            Objects.requireNonNull(shelf, "shelf must not be null");
        }
    }

    /**
     * The loading bay, selectable as a destination,
     * while a relocatable package is the primary selection.
     *
     * @param loadingBay the loading bay
     */
    record BayDestination(LoadingBay loadingBay) implements SelectionTarget {

        /**
         * @throws NullPointerException if {@code loadingBay} is null
         */
        public BayDestination {
            Objects.requireNonNull(loadingBay, "loadingBay must not be null");
        }
    }
}
