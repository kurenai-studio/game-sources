package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.config.SupplyConfig;
import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.gdx.HotPath;

import java.util.Arrays;
import java.util.Objects;

/**
 * Decides what the warehouse
 * should receive on its next truck visit.
 */
@HotPath
public final class SupplyPlanner {

    private static final PackageColor[] COLORS = PackageColor.values();

    private final StorageQuota storageQuota;
    private final SupplyConfig config;

    private final int[] deficits = new int[COLORS.length];
    private final int[] allocations = new int[COLORS.length];
    private final int[] fullCapacityAllocations = new int[COLORS.length];
    private final boolean[] floorProtected = new boolean[COLORS.length];
    private final double[] remainders = new double[COLORS.length];

    /**
     * Creates a supply planner.
     *
     * @param colorDemand demand that determines the warehouse's intended stock mix
     * @param config rules that shape inbound supply over time
     *
     * @throws NullPointerException if {@code demandModel} or {@code config} is null
     */
    public SupplyPlanner(ColorDemand colorDemand, SupplyConfig config) {
        Objects.requireNonNull(colorDemand, "demandModel must not be null");
        Objects.requireNonNull(config, "config must not be null");

        this.storageQuota = new StorageQuota(colorDemand);
        this.config = config;
    }

    /**
     * Decides the color mix for the next truck delivery.
     *
     * @param world warehouse whose stock is being supplied
     * @param truckCapacity most packages the truck can bring
     *
     * @return the planned delivery
     * @throws IllegalArgumentException if {@code truckCapacity} is not positive
     * @throws NullPointerException if {@code world} is null
     */
    public SupplyPlan plan(World world, int truckCapacity) {
        Objects.requireNonNull(world, "world must not be null");
        if (truckCapacity <= 0) {
            var message = "truckCapacity must be > 0, got " + truckCapacity;
            throw new IllegalArgumentException(message);
        }
        resetBuffers();

        var liveCounts = world.liveCounts();
        var targetQuotas = storageQuota.targets(world);
        double floorFraction = config.floorFraction();

        int totalDeficit = 0;
        int floorProtectedCount = 0;

        for (var color : COLORS) {
            if (color == PackageColor.NONE) {
                continue;
            }
            int target = targetQuotas.get(color, 0);
            int liveCount = liveCounts.get(color, 0);
            int deficit = target - liveCount;
            if (deficit <= 0) {
                continue;
            }
            int index = color.ordinal();
            int floorLiveCount = (int) Math.ceil(floorFraction * target);

            deficits[index] = deficit;
            totalDeficit += deficit;
            floorProtected[index] = liveCount < floorLiveCount;
        }
        int tick = world.currentTick();
        int effectiveCapacity = effectiveDropoffCapacity(tick, truckCapacity);

        allocate(deficits, totalDeficit, truckCapacity, fullCapacityAllocations);

        int nonProtectedDeficit = 0;
        for (var color : COLORS) {
            int index = color.ordinal();
            if (!floorProtected[index]) {
                nonProtectedDeficit += deficits[index];
                continue;
            }
            int protectedAllocation = fullCapacityAllocations[index];

            allocations[index] = protectedAllocation;
            floorProtectedCount += protectedAllocation;
            deficits[index] = 0;
        }
        int capacityForOtherColors = Math.max(0, effectiveCapacity - floorProtectedCount);
        allocate(deficits, nonProtectedDeficit, capacityForOtherColors, fullCapacityAllocations);
        for (int i = 0; i < allocations.length; i++) {
            allocations[i] += fullCapacityAllocations[i];
        }
        return new SupplyPlan(effectiveCapacity, allocations);
    }

    private int effectiveDropoffCapacity(int tick, int truckCapacity) {
        int cycleLength = config.cycleLengthTicks();
        int halfCycle = cycleLength / 2;
        int phase = Math.floorMod(tick, cycleLength);

        double minimumFactor = config.minimumFactor();
        double factorRange = 1.0 - minimumFactor;
        double factor;

        if (phase < halfCycle) {
            double progress = (double) phase / halfCycle;
            factor = 1.0 - factorRange * progress;
        }
        else {
            double progress = (double) (phase - halfCycle) / halfCycle;
            factor = minimumFactor + factorRange * progress;
        }
        return (int) Math.round(truckCapacity * factor);
    }

    private void resetBuffers() {
        Arrays.fill(deficits, 0);
        Arrays.fill(allocations, 0);
        Arrays.fill(fullCapacityAllocations, 0);
        Arrays.fill(floorProtected, false);
    }

    private void allocate(
            int[] sourceDeficits,
            int totalDeficit,
            int capacity,
            int[] output
    ) {
        Arrays.fill(output, 0);
        if (totalDeficit == 0 || capacity == 0) {
            return;
        }
        if (totalDeficit <= capacity) {
            System.arraycopy(sourceDeficits, 0, output, 0, sourceDeficits.length);
            return;
        }
        int allocated = 0;
        for (int i = 0; i < sourceDeficits.length; i++) {
            double exact = (double) sourceDeficits[i] * capacity / totalDeficit;
            int floor = (int) Math.floor(exact);
            output[i] = floor;
            remainders[i] = exact - floor;
            allocated += floor;
        }
        for (int remaining = capacity - allocated; remaining > 0; remaining--) {
            int bestIndex = 0;
            for (int i = 1; i < remainders.length; i++) {
                if (remainders[i] > remainders[bestIndex]) {
                    bestIndex = i;
                }
            }
            output[bestIndex]++;
            remainders[bestIndex] = -1;
        }
    }
}
