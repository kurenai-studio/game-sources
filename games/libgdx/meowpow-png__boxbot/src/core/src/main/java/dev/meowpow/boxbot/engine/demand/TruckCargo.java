package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.engine.entity.Package;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.GdxCollections;
import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.utils.Array;

import java.util.Objects;

/**
 * Represents a container
 * for packages a truck is carrying.
 */
@HotPath
public final class TruckCargo {

    private final int capacity;

    private final Array<Package> outbound;
    private final ArrayView<Package> outboundView;

    private final Array<Package> inbound = new Array<>();
    private final ArrayView<Package> inboundView = GdxCollections.viewOf(inbound);

    private final Array<Package> current;
    private final ArrayView<Package> currentView;

    private int nextIndex;

    /**
     * Creates cargo carrying the
     * given outbound packages, in delivery order.
     *
     * @param capacity most packages this cargo can hold at once
     * @param outboundPackages the packages to deliver
     *
     * @throws IllegalArgumentException if {@code capacity} is not positive,
     * or if {@code outboundPackages} holds more than {@code capacity} packages
     * @throws NullPointerException if {@code outboundPackages} is null
     */
    public TruckCargo(int capacity, Array<Package> outboundPackages) {
        Objects.requireNonNull(outboundPackages, "outboundPackages must not be null");
        if (capacity <= 0) {
            throw new IllegalArgumentException("capacity must be > 0, got " + capacity);
        }
        if (outboundPackages.size > capacity) {
            var message = "outboundPackages must not exceed capacity %d, got %d";
            throw new IllegalArgumentException(message.formatted(capacity, outboundPackages.size));
        }
        this.capacity = capacity;
        this.outbound = new Array<>(outboundPackages);
        this.outboundView = GdxCollections.viewOf(this.outbound);
        this.current = new Array<>(outboundPackages);
        this.currentView = GdxCollections.viewOf(this.current);
    }

    /**
     * Returns a live, read-only view of every
     * outbound package in this cargo, in delivery order.
     */
    public ArrayView<Package> outbound() {
        return outboundView;
    }

    /**
     * Returns a live, read-only view
     * of every package picked up so far.
     */
    public ArrayView<Package> inbound() {
        return inboundView;
    }

    /**
     * Returns a live, read-only view of
     * every package this cargo currently holds.
     */
    public ArrayView<Package> current() {
        return currentView;
    }

    /**
     * Returns true if every outbound
     * package in this cargo has been delivered.
     */
    public boolean outboundEmpty() {
        return nextIndex >= outbound.size;
    }

    /**
     * Returns the next undelivered package.
     * <p>
     * Calling this method does not
     * remove the package from this cargo.
     *
     * @throws IllegalStateException if there is no outbound package left
     */
    public Package peekNext() {
        if (outboundEmpty()) {
            throw new IllegalStateException("Outbound cargo is empty");
        }
        return outbound.get(nextIndex);
    }

    /**
     * Marks the package returned by
     * {@link #peekNext()} as delivered.
     *
     * @throws IllegalStateException if there is no outbound package left
     */
    public void markDelivered() {
        if (outboundEmpty()) {
            throw new IllegalStateException("Outbound cargo is empty");
        }
        nextIndex++;
        current.removeIndex(0);
    }

    /**
     * Returns true if this cargo has
     * room for at least one more picked-up package.
     */
    public boolean hasRoom() {
        return outboundRemaining() + inbound.size < capacity;
    }

    /**
     * Adds a package to the packages picked up so far.
     *
     * @param pkg the package picked up
     *
     * @throws IllegalStateException if this cargo has no room
     * @throws NullPointerException if {@code pkg} is null
     */
    public void pickUp(Package pkg) {
        Objects.requireNonNull(pkg, "pkg must not be null");
        if (!hasRoom()) {
            throw new IllegalStateException("Cargo is full");
        }
        inbound.add(pkg);
        current.add(pkg);
    }

    /**
     * Returns how many outbound
     * packages have not yet been delivered.
     */
    public int outboundRemaining() {
        return outbound.size - nextIndex;
    }

    /**
     * Returns this cargo's total outbound package count.
     */
    public int outboundTotal() {
        return outbound.size;
    }

    /**
     * Returns how many packages have been picked up so far.
     */
    public int inboundCount() {
        return inbound.size;
    }

    /**
     * Returns the most packages this cargo can hold at once.
     */
    public int capacity() {
        return capacity;
    }
}
