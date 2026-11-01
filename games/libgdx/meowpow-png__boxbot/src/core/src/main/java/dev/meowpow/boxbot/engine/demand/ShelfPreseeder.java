package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.Package;
import dev.meowpow.boxbot.engine.entity.Shelf;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Random;

/**
 * One-time seeder that stocks a random fraction of
 * shelves with packages before the simulation begins.
 */
public final class ShelfPreseeder {

    private final Random random;
    private final ColorDemand colorDemand;
    private final double fraction;

    /**
     * Creates a preseeder that stocks the given fraction of shelves.
     *
     * @param seed seed for shelf selection randomness
     * @param colorDemand color demand distribution sampled for each stocked package
     * @param fraction fraction of shelves to stock, between 0 and 1
     *
     * @throws IllegalArgumentException if {@code fraction} is not between 0 and 1
     */
    public ShelfPreseeder(long seed, ColorDemand colorDemand, double fraction) {
        if (fraction < 0 || fraction > 1) {
            var message = "fraction must be between 0 and 1, got " + fraction;
            throw new IllegalArgumentException(message);
        }
        this.random = new Random(seed);
        this.colorDemand = colorDemand;
        this.fraction = fraction;
    }

    /**
     * Stocks a random selection of shelves,
     * each with a package sampled from the demand model.
     */
    public void preseed(World world) {
        var shelfView = world.shelves();
        var shelves = new ArrayList<Shelf>(shelfView.size());
        for (int i = 0; i < shelfView.size(); i++) {
            shelves.add(shelfView.get(i));
        }
        Collections.shuffle(shelves, random);

        int count = (int) Math.round(shelves.size() * fraction);
        for (int i = 0; i < count; i++) {
            var pkg = new Package(world.nextPackageId(), colorDemand.sample());
            world.setShelfPackage(shelves.get(i).id(), pkg);
        }
    }
}
