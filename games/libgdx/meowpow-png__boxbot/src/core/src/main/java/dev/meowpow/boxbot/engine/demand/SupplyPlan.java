package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.engine.PackageColor;

import java.util.Objects;

/**
 * The color mix committed for one incoming truck visit.
 */
public final class SupplyPlan {

    private final int effectiveDropoffCapacity;
    private final int[] allocations;
    private final int packageCount;

    SupplyPlan(int effectiveDropoffCapacity, int[] allocations) {
        this.effectiveDropoffCapacity = effectiveDropoffCapacity;
        this.allocations = allocations.clone();

        int count = 0;
        for (int allocation : allocations) {
            count += allocation;
        }
        this.packageCount = count;
    }

    /**
     * Returns the supply limit set by
     * the current cycle before floor protection.
     */
    public int effectiveDropoffCapacity() {
        return effectiveDropoffCapacity;
    }

    /**
     * Returns how many packages of
     * {@code color} the truck will bring.
     *
     * @param color package color
     *
     * @throws NullPointerException if {@code color} is null
     */
    public int allocation(PackageColor color) {
        Objects.requireNonNull(color, "color must not be null");
        return allocations[color.ordinal()];
    }

    /**
     * Returns the total packages the truck will bring.
     */
    public int packageCount() {
        return packageCount;
    }
}
