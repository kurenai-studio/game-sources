package dev.meowpow.boxbot.engine;

import dev.meowpow.boxbot.engine.entity.*;
import dev.meowpow.boxbot.engine.entity.Package;
import dev.meowpow.boxbot.engine.robot.JobType;
import dev.meowpow.boxbot.engine.robot.Robot;
import dev.meowpow.boxbot.engine.robot.RobotJob;
import dev.meowpow.boxbot.engine.spatial.grid.Grid;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.GdxCollections;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.LogTag;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ObjectIntMap;
import com.badlogic.gdx.utils.ObjectSet;

import java.util.Objects;

/**
 * The simulation's mutable runtime state.
 * <p>
 * Built once and then advanced one tick at a time.
 */
@HotPath
public final class World {

    private final Robot robot;
    private final Shelves shelves;
    private final LoadingBay loadingBay;
    private final ChargingStation chargingStation;
    private final Grid grid;
    private final SimulationClock clock;

    private final PendingJobs jobs = new PendingJobs();
    private final ObjectSet<ShelfId> reservedShelfIds = new ObjectSet<>();
    private final Array<OutboundOrder> outboundOrders = new Array<>();
    private final ArrayView<OutboundOrder> outboundOrderView = GdxCollections.viewOf(outboundOrders);

    private @Nullable JobType carriedJobType;

    private int nextPackageId;
    private int shipmentFailures;
    private int score;

    /**
     * Creates a world from already-assembled entities.
     *
     * @param robot the simulation's robot
     * @param shelves the warehouse's shelves
     * @param loadingBay the warehouse's loading bay
     * @param chargingStation the warehouse's charging station
     * @param grid the walkable grid backing pathfinding
     * @param clock the simulation clock
     *
     * @throws NullPointerException if any argument is null
     */
    public World(
            Robot robot,
            ArrayView<Shelf> shelves,
            LoadingBay loadingBay,
            ChargingStation chargingStation,
            Grid grid,
            SimulationClock clock
    ) {
        Objects.requireNonNull(robot, "robot must not be null");
        Objects.requireNonNull(shelves, "shelves must not be null");
        Objects.requireNonNull(loadingBay, "loadingBay must not be null");
        Objects.requireNonNull(chargingStation, "chargingStation must not be null");
        Objects.requireNonNull(grid, "grid must not be null");
        Objects.requireNonNull(clock, "clock must not be null");

        this.robot = robot;
        this.shelves = new Shelves(shelves);
        this.loadingBay = loadingBay;
        this.chargingStation = chargingStation;
        this.grid = grid;
        this.clock = clock;
    }

    /**
     * Returns the simulation's robot.
     */
    public Robot robot() {
        return robot;
    }

    /**
     * Returns the warehouse's shelves.
     */
    public ArrayView<Shelf> shelves() {
        return shelves.view();
    }

    /**
     * Returns the shelf with the given ID.
     *
     * @throws IllegalStateException if no shelf has that ID
     */
    public Shelf shelfById(ShelfId shelfId) {
        return shelves.byId(shelfId);
    }

    /**
     * Updates the package occupying
     * shelf ID and invalidates shelf views.
     */
    public void setShelfPackage(ShelfId shelfId, @Nullable Package pkg) {
        shelves.setOccupyingPackage(shelfId, pkg);
    }

    /**
     * Returns whether shelf occupancy has changed
     * since the last caller consumed the change.
     */
    public boolean consumeShelfChanges() {
        return shelves.consumeOccupancyChanges();
    }

    /**
     * Returns the warehouse's loading bay.
     */
    public LoadingBay loadingBay() {
        return loadingBay;
    }

    /**
     * Returns the warehouse's charging station.
     */
    public ChargingStation chargingStation() {
        return chargingStation;
    }

    /**
     * Returns the walkable grid backing pathfinding.
     */
    public Grid grid() {
        return grid;
    }

    /**
     * Returns a snapshot of the pending jobs.
     */
    public ArrayView<RobotJob> jobs() {
        return jobs.view();
    }

    /**
     * Adds a pending job.
     */
    public void addJob(RobotJob job) {
        jobs.add(job);
    }

    /**
     * Removes a pending job.
     */
    public void removeJob(RobotJob job) {
        jobs.remove(job);
    }

    /**
     * Returns whether pending jobs have changed
     * since the last caller consumed the change.
     */
    public boolean consumeJobChanges() {
        return jobs.consumeDirty();
    }

    /**
     * Returns whether {@code shelfId}
     * is reserved for an in-progress job.
     */
    public boolean isShelfReserved(ShelfId shelfId) {
        return reservedShelfIds.contains(shelfId);
    }

    /**
     * Marks a shelf as reserved.
     */
    public void reserveShelf(ShelfId shelfId) {
        reservedShelfIds.add(shelfId);
    }

    /**
     * Clears a shelf's reservation.
     */
    public void releaseShelf(ShelfId shelfId) {
        reservedShelfIds.remove(shelfId);
    }

    /**
     * Returns the type of job the robot is
     * carrying a package for, or null if empty-handed.
     */
    @Nullable
    public JobType carriedJobType() {
        return carriedJobType;
    }

    /**
     * Sets the type of job the robot is carrying
     * a package for; pass null when empty-handed.
     */
    public void setCarriedJobType(@Nullable JobType type) {
        this.carriedJobType = type;
    }

    /**
     * Returns a fresh package identifier, advancing the counter.
     */
    public PackageId nextPackageId() {
        return new PackageId(nextPackageId++);
    }

    /**
     * Returns how many packages of {@code color} are
     * currently anywhere in the warehouse: on a shelf,
     * waiting in the loading bay, or carried by the robot.
     *
     * @throws NullPointerException if {@code color} is null
     */
    public int liveCount(PackageColor color) {
        Objects.requireNonNull(color, "color must not be null");
        return liveCounts().get(color, 0);
    }

    /**
     * Returns how many packages of each color
     * are currently anywhere in the warehouse.
     */
    public ObjectIntMap<PackageColor> liveCounts() {
        var counts = new ObjectIntMap<PackageColor>();
        var shelfView = shelves.view();

        for (int i = 0; i < shelfView.size(); i++) {
            var pkg = shelfView.get(i).occupyingPackage();
            if (pkg != null) {
                var color = pkg.color();
                counts.getAndIncrement(color, 0, 1);
            }
        }
        tally(loadingBay.incomingPackagePlacements(), counts);
        tally(loadingBay.outgoingPackagePlacements(), counts);

        var carriedPackage = robot.carriedPackage();
        if (carriedPackage != null) {
            var color = carriedPackage.color();
            counts.getAndIncrement(color, 0, 1);
        }
        return counts;
    }

    private static void tally(
            ArrayView<LoadingBay.PackagePlacement> placements,
            ObjectIntMap<PackageColor> counts
    ) {
        for (int i = 0; i < placements.size(); i++) {
            var color = placements.get(i).pkg().color();
            counts.getAndIncrement(color, 0, 1);
        }
    }

    /**
     * Returns the current simulation tick.
     */
    public int currentTick() {
        return clock.currentTick();
    }

    /**
     * Returns the elapsed real playtime, in seconds.
     */
    public float elapsedSeconds() {
        return clock.elapsedSeconds();
    }

    /**
     * Starts tracking a package's delivery timer.
     */
    public void startOutboundOrder(OutboundOrder order) {
        outboundOrders.add(order);
    }

    /**
     * Returns a snapshot of the currently open outbound orders.
     */
    public ArrayView<OutboundOrder> outboundOrders() {
        return outboundOrderView;
    }

    /**
     * Marks the earliest-arrived open order requesting color
     * as successfully shipped, stopping its delivery timer.
     * <p>
     * No-op if no open order currently wants color.
     * Its order may already have expired while the package was in transit.
     */
    public void completeOutboundOrder(PackageColor color) {
        for (int i = 0; i < outboundOrders.size; i++) {
            if (outboundOrders.get(i).color() == color) {
                outboundOrders.removeIndex(i);
                return;
            }
        }
    }

    /**
     * Returns the number of shipment failures so far.
     */
    public int shipmentFailures() {
        return shipmentFailures;
    }

    /**
     * Returns whether shipment failures have reached {@code failureLimit}.
     */
    public boolean hasFailed(int failureLimit) {
        return shipmentFailures >= failureLimit;
    }

    /**
     * Returns the number of completed orders so far.
     */
    public int score() {
        return score;
    }

    /**
     * Records {@code count} additional
     * completed shipments toward the score.
     */
    public void recordShipment(int count) {
        score += count;
    }

    /**
     * Fails an outbound order.
     * <p>
     * The order will no longer be tracked. Any packages
     * already in flight to fulfill it are unaffected
     *
     * @throws IllegalArgumentException if {@code order} is not currently tracked
     */
    public void expireOutboundOrder(OutboundOrder order) {
        if (!outboundOrders.removeValue(order, false)) {
            var message = "Order " + order.id() + " is not currently tracked";
            throw new IllegalArgumentException(message);
        }
        GameLog.infof(LogTag.DEMAND,
                "Order %s for %s expired unfulfilled",
                order.id(),
                order.color()
        );
        shipmentFailures++;
    }

    /**
     * Advances the simulation by one tick.
     * <p>
     * Any outbound orders whose delivery
     * timer has run out will be marked expired.
     */
    public void tick() {
        clock.advance();
        for (int i = 0; i < outboundOrders.size; ) {
            var order = outboundOrders.get(i);
            if (currentTick() >= order.deadlineTick()) {
                expireOutboundOrder(order);
            }
            else {
                i++;
            }
        }
    }
}
