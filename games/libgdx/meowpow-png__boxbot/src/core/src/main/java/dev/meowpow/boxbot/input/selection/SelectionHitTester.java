package dev.meowpow.boxbot.input.selection;

import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.LoadingBay;
import dev.meowpow.boxbot.engine.spatial.grid.TileBounds;
import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.gdx.ArrayView;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.math.Rectangle;

/**
 * Finds the selectable entity,
 * if any, at a given world point.
 */
public final class SelectionHitTester {

    private final Rectangle bounds = new Rectangle();

    /**
     * Returns the selectable entity occupying
     * the given world point, or null if none does.
     *
     * @param world the world to search
     * @param tileSize the map's tile size, in pixels
     * @param worldX the point's x coordinate, in world (pixel) units
     * @param worldY the point's y coordinate, in world (pixel) units
     */
    public @Nullable SelectionTarget hitTest(
            World world,
            TileSize tileSize,
            float worldX,
            float worldY
    ) {
        var shelves = world.shelves();
        for (int i = 0; i < shelves.size(); i++) {
            var shelf = shelves.get(i);
            if (shelf.occupyingPackage() == null) {
                continue;
            }
            TileBounds.set(bounds, shelf.position(), tileSize);
            if (bounds.contains(worldX, worldY)) {
                return new SelectionTarget.ShelfPackage(shelf);
            }
        }
        var loadingBay = world.loadingBay();
        var placement = hitTestBay(loadingBay.incomingPackagePlacements(), tileSize, worldX, worldY);
        if (placement != null) {
            return new SelectionTarget.BayPackage(placement);
        }
        TileBounds.set(bounds, world.chargingStation().footprint(), tileSize);
        if (bounds.contains(worldX, worldY)) {
            return new SelectionTarget.Station(world.chargingStation());
        }
        return null;
    }

    /**
     * Returns the empty shelf or loading bay
     * at the given world point, or null if neither is there.
     *
     * @param world the world to search
     * @param tileSize the map's tile size, in pixels
     * @param worldX the point's x coordinate, in world (pixel) units
     * @param worldY the point's y coordinate, in world (pixel) units
     */
    public @Nullable SelectionTarget hitTestDestination(
            World world,
            TileSize tileSize,
            float worldX,
            float worldY
    ) {
        var shelves = world.shelves();
        for (int i = 0; i < shelves.size(); i++) {
            var shelf = shelves.get(i);
            if (shelf.occupyingPackage() != null) {
                continue;
            }
            TileBounds.set(bounds, shelf.position(), tileSize);
            if (bounds.contains(worldX, worldY)) {
                return new SelectionTarget.EmptyShelf(shelf);
            }
        }
        var loadingBay = world.loadingBay();
        if (loadingBay.freeTiles() > 0) {
            TileBounds.set(bounds, loadingBay.footprint(), tileSize);
            if (bounds.contains(worldX, worldY)) {
                return new SelectionTarget.BayDestination(loadingBay);
            }
        }
        return null;
    }

    private LoadingBay.@Nullable PackagePlacement hitTestBay(
            ArrayView<LoadingBay.PackagePlacement> placements,
            TileSize tileSize,
            float worldX,
            float worldY
    ) {
        for (int i = 0; i < placements.size(); i++) {
            var placement = placements.get(i);
            TileBounds.set(bounds, placement.position(), tileSize);
            if (bounds.contains(worldX, worldY)) {
                return placement;
            }
        }
        return null;
    }
}
