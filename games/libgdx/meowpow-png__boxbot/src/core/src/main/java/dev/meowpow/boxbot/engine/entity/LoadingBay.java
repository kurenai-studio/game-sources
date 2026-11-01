package dev.meowpow.boxbot.engine.entity;

import dev.meowpow.boxbot.engine.spatial.grid.Footprint;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.GdxCollections;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.gdx.ObjectMapView;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ObjectMap;

import java.util.Objects;

/**
 * The warehouse's only connection to the outside world.
 */
@HotPath
public final class LoadingBay {

    /**
     * A package and the loading-bay tile it occupies.
     */
    public record PackagePlacement(GridPos position, Package pkg) {}

    private final Footprint footprint;
    private final Array<GridPos> footprintTiles = new Array<>();
    private final ObjectMap<GridPos, PackagePlacement> tiles = new ObjectMap<>();

    private final Array<PackagePlacement> incomingPackages = new Array<>();
    private final Array<PackagePlacement> outgoingPackages = new Array<>();
    private final ObjectMap<GridPos, Package> incomingPackagesByTile = new ObjectMap<>();
    private final ObjectMap<GridPos, Package> outgoingPackagesByTile = new ObjectMap<>();

    private final ArrayView<PackagePlacement> inPkgPlacements = GdxCollections.viewOf(incomingPackages);
    private final ArrayView<PackagePlacement> outPkgPlacements = GdxCollections.viewOf(outgoingPackages);

    private final ObjectMapView<GridPos, Package> inPkgView = GdxCollections.viewOf(incomingPackagesByTile);
    private final ObjectMapView<GridPos, Package> outPkgView = GdxCollections.viewOf(outgoingPackagesByTile);

    /**
     * Creates a bay covering the given footprint, empty.
     *
     * @param footprint the bay's occupiable grid tiles
     *
     * @throws NullPointerException if {@code footprint} is null
     */
    public LoadingBay(Footprint footprint) {
        this.footprint = Objects.requireNonNull(footprint, "footprint must not be null");
        footprint.addTiles(footprintTiles);
    }

    /**
     * Returns the bay's grid tiles.
     */
    public Footprint footprint() {
        return footprint;
    }

    /**
     * Returns the capacity available for a new package.
     */
    public int freeTiles() {
        return footprint.tileCount() - tiles.size;
    }

    /**
     * Returns the bay's total tile capacity.
     */
    public int totalTiles() {
        return footprint.tileCount();
    }

    /**
     * Places an inbound package on a free tile if one is available.
     *
     * @param pkg the package to place
     *
     * @return true if the package was placed, false if the bay is full
     * @throws NullPointerException if {@code pkg} is null
     */
    public boolean tryPlaceIncoming(Package pkg) {
        Objects.requireNonNull(pkg, "pkg must not be null");
        return tryPlace(pkg, incomingPackages, incomingPackagesByTile);
    }

    /**
     * Places an outbound package on a free tile if one is available.
     *
     * @param pkg the package to place
     *
     * @return true if the package was placed, false if the bay is full
     * @throws NullPointerException if {@code pkg} is null
     */
    public boolean tryPlaceOutgoing(Package pkg) {
        Objects.requireNonNull(pkg, "pkg must not be null");
        return tryPlace(pkg, outgoingPackages, outgoingPackagesByTile);
    }

    /**
     * Removes a package from the bay, freeing its tile.
     *
     * @param pkg the package to remove
     *
     * @throws NullPointerException if {@code pkg} is null
     */
    public void remove(Package pkg) {
        Objects.requireNonNull(pkg, "pkg must not be null");
        remove(pkg, incomingPackages, incomingPackagesByTile);
        remove(pkg, outgoingPackages, outgoingPackagesByTile);
    }

    private void remove(
            Package pkg,
            Array<PackagePlacement> packages,
            ObjectMap<GridPos, Package> packagesByTile
    ) {
        for (int i = packages.size - 1; i >= 0; i--) {
            var placement = packages.get(i);
            if (placement.pkg().equals(pkg)) {
                packages.removeIndex(i);
                tiles.remove(placement.position());
                packagesByTile.remove(placement.position());
            }
        }
    }

    /**
     * Removes up to {@code maxCount} packages
     * awaiting shipment, for the truck to pick up on a visit.
     *
     * @param maxCount the maximum number of packages to ship
     *
     * @return the number of packages shipped
     */
    public int shipUpTo(int maxCount) {
        int count = Math.min(maxCount, outgoingPackages.size);
        for (int i = 0; i < count; i++) {
            var placement = outgoingPackages.get(i);
            tiles.remove(placement.position());
            outgoingPackagesByTile.remove(placement.position());
        }
        if (count > 0) {
            outgoingPackages.removeRange(0, count - 1);
        }
        return count;
    }

    /**
     * Removes the next package awaiting shipment.
     *
     * @return the removed package, or null if none are awaiting shipment
     */
    public @Nullable Package shipNext() {
        if (outgoingPackages.size == 0) {
            return null;
        }
        var placement = outgoingPackages.removeIndex(0);
        tiles.remove(placement.position());
        outgoingPackagesByTile.remove(placement.position());
        return placement.pkg();
    }

    /**
     * Returns a reusable live
     * view of packages awaiting storage.
     */
    public ArrayView<PackagePlacement> incomingPackagePlacements() {
        return inPkgPlacements;
    }

    /**
     * Returns a reusable live
     * view of packages awaiting shipment.
     */
    public ArrayView<PackagePlacement> outgoingPackagePlacements() {
        return outPkgPlacements;
    }

    /**
     * Returns a reusable live
     * view of inbound packages, keyed by tile.
     */
    public ObjectMapView<GridPos, Package> incomingPackages() {
        return inPkgView;
    }

    /**
     * Returns a reusable live
     * view of outbound packages, keyed by tile.
     */
    public ObjectMapView<GridPos, Package> outgoingPackages() {
        return outPkgView;
    }

    private boolean tryPlace(
            Package pkg,
            Array<PackagePlacement> packages,
            ObjectMap<GridPos, Package> packagesByTile
    ) {
        if (tiles.size >= footprint.tileCount()) {
            return false;
        }
        for (int i = 0; i < footprintTiles.size; i++) {
            var tile = footprintTiles.get(i);
            if (!tiles.containsKey(tile)) {
                var placement = new PackagePlacement(tile, pkg);
                tiles.put(tile, placement);
                packages.add(placement);
                packagesByTile.put(tile, pkg);
                return true;
            }
        }
        return false;
    }

    @Override
    public String toString() {
        return "LoadingBay[free=%d/%d]".formatted(
                freeTiles(),
                totalTiles()
        );
    }
}
