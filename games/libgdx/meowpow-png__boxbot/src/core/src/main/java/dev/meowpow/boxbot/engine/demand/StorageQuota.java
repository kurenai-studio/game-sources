package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ObjectIntMap;

/**
 * Each color's target share of shelf
 * capacity, sized from the demand model.
 */
@HotPath
public final class StorageQuota {

    private final ColorDemand colorDemand;

    /**
     * Creates a storage quota sized
     * from {@code demandModel}'s color shares.
     *
     * @param colorDemand color demand distribution targets are drawn from
     */
    public StorageQuota(ColorDemand colorDemand) {
        this.colorDemand = colorDemand;
    }

    /**
     * Returns how many shelves the warehouse
     * targets holding of each color, sized from
     * its demand share against total shelf capacity.
     * <p>
     * <strong>Implementation Note:</strong>
     * Allocated via the largest-remainder method, so targets
     * always sum to {@code world.shelves().size()} even when
     * demand shares don't divide shelf capacity evenly.
     * <p>
     * Any color still left at zero is then topped up to one,
     * borrowing a shelf from whichever color holds the most,
     * so a low-demand color never becomes permanently unstockable.
     */
    public ObjectIntMap<PackageColor> targets(World world) {
        var colors = PackageColor.colored();
        int shelfCount = world.shelves().size();

        var targets = new ObjectIntMap<PackageColor>();
        var remainders = new double[colors.size];
        int allocated = 0;

        for (int i = 0; i < colors.size; i++) {
            var color = colors.get(i);
            double exact = colorDemand.share(color) * shelfCount;
            int floor = (int) Math.floor(exact);
            targets.put(color, floor);
            remainders[i] = exact - floor;
            allocated += floor;
        }
        int leftover = shelfCount - allocated;
        for (int n = 0; n < leftover; n++) {
            int bestIndex = 0;
            for (int i = 1; i < colors.size; i++) {
                if (remainders[i] > remainders[bestIndex]) {
                    bestIndex = i;
                }
            }
            var color = colors.get(bestIndex);
            targets.put(color, targets.get(color, 0) + 1);
            remainders[bestIndex] = -1;
        }

        if (shelfCount >= colors.size) {
            ensureColorsHeadroom(targets, colors);
        }
        return targets;
    }

    private void ensureColorsHeadroom(ObjectIntMap<PackageColor> targets, Array<PackageColor> colors) {
        for (int i = 0; i < colors.size; i++) {
            var color = colors.get(i);
            if (targets.get(color, 0) > 0) {
                continue;
            }
            var donor = colors.get(0);
            for (int j = 1; j < colors.size; j++) {
                var candidate = colors.get(j);
                if (targets.get(candidate, 0) > targets.get(donor, 0)) {
                    donor = candidate;
                }
            }
            targets.put(donor, targets.get(donor, 0) - 1);
            targets.put(color, 1);
        }
    }
}
