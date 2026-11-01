package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.Package;
import dev.meowpow.boxbot.engine.robot.JobId;
import dev.meowpow.boxbot.engine.robot.JobType;
import dev.meowpow.boxbot.engine.robot.RobotJob;
import dev.meowpow.boxbot.engine.time.IntervalTimer;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.LogTag;

import com.badlogic.gdx.utils.Array;

import java.util.Objects;
import java.util.Random;

/**
 * Periodic loading-bay visitor that
 * ships outbound packages and delivers its cargo.
 */
@HotPath
public final class Truck {

    private final Random random;
    private final SupplyPlanner supplyPlanner;

    private final IntervalTimer visitTimer;
    private final int operationDelayTicks;
    private final int capacity;

    private TruckCargo cargo;
    private boolean visiting;
    private boolean pickupTurn;
    private int cooldownTicksRemaining;
    private boolean waiting;

    private int nextJobNumber;
    private int previousSupplyCapacity = -1;

    /**
     * Creates a truck that visits the loading bay on a fixed interval.
     *
     * @param seed seed for shelf suggestion randomness
     * @param supplyPlanner decides what the truck should bring on each visit
     * @param world world used to mint ids for the truck's initial cargo
     * @param visitIntervalTicks ticks between visits
     * @param operationDelayTicks ticks paused between each pickup and drop-off
     * @param capacity the truck's shared cargo capacity
     *
     * @throws IllegalArgumentException if {@code visitIntervalTicks} is not positive
     * @throws NullPointerException if {@code world} or {@code supplyPlanner} is null
     */
    public Truck(
            long seed,
            SupplyPlanner supplyPlanner,
            World world,
            int visitIntervalTicks,
            int operationDelayTicks,
            int capacity
    ) {
        Objects.requireNonNull(supplyPlanner, "supplyPlanner must not be null");
        Objects.requireNonNull(world, "world must not be null");

        this.random = new Random(seed);
        this.supplyPlanner = supplyPlanner;
        this.visitTimer = new IntervalTimer(visitIntervalTicks);
        this.operationDelayTicks = operationDelayTicks;
        this.capacity = capacity;
        this.cargo = buildCargo(world);
    }

    /**
     * Advances the truck by one tick.
     */
    public void tick(World world) {
        if (!visiting) {
            if (!visitTimer.advance()) {
                return;
            }
            beginVisit();
        }
        service(world);
    }

    /**
     * Returns the truck's current cargo.
     */
    public TruckCargo cargo() {
        return cargo;
    }

    /**
     * Returns whether the truck is currently at the loading bay.
     */
    public boolean isVisiting() {
        return visiting;
    }

    /**
     * Returns how many ticks remain
     * until the truck's next visit begins.
     * <p>
     * <strong>API Note:</strong>
     * While {@link #isVisiting()} is true, the visit timer is
     * paused and this returns a stale value from before the
     * visit began, not a countdown to when it will end.
     */
    public int ticksUntilNextVisit() {
        return visitTimer.ticksRemaining();
    }

    /**
     * Returns whether the truck
     * can be forced to depart right now.
     */
    public boolean canForceDepart() {
        return visiting && cargo.outboundEmpty();
    }

    /**
     * Ends the current visit right away.
     */
    public void forceDepart(World world) {
        if (!canForceDepart()) {
            return;
        }
        depart(world);
    }

    private void beginVisit() {
        visiting = true;
        pickupTurn = true;
        cooldownTicksRemaining = 0;
        waiting = false;
        GameLog.info(LogTag.DEMAND, "Truck arrived at the loading bay");
    }

    private void service(World world) {
        if (isVisitComplete()) {
            depart(world);
            return;
        }
        if (cooldownTicksRemaining > 0) {
            cooldownTicksRemaining--;
            return;
        }
        if (attemptTurn(world)) {
            cooldownTicksRemaining = operationDelayTicks;
            waiting = false;
        }
        else if (!waiting) {
            waiting = true;
            GameLog.debug(LogTag.DEMAND, pickupTurn
                    ? "Truck is waiting to pick up a package"
                    : "Truck is waiting for bay space to drop off package"
            );
        }
    }

    private boolean isVisitComplete() {
        return cargo.outboundEmpty() && cargo.inboundCount() >= capacity;
    }

    private void depart(World world) {
        var deliveredCount = cargo.outboundTotal();
        var pickedUpCount = cargo.inboundCount();

        var shipped = cargo.inbound();
        for (int i = 0; i < shipped.size(); i++) {
            world.completeOutboundOrder(shipped.get(i).color());
        }
        cargo = buildCargo(world);
        visiting = false;
        GameLog.infof(
                LogTag.DEMAND,
                "Truck left loading bay (picked up: %d, dropped off: %d)",
                pickedUpCount,
                deliveredCount
        );
    }

    /**
     * Attempts the operation whose turn it currently is,
     * falling back to the other operation when possible.
     */
    private boolean attemptTurn(World world) {
        boolean pickupExhausted = cargo.inboundCount() >= capacity;
        boolean dropoffExhausted = cargo.outboundEmpty();

        if (pickupTurn) {
            if (!pickupExhausted && attemptPickup(world)) {
                return true;
            }
            return !dropoffExhausted && attemptDropoff(world);
        }
        if (!dropoffExhausted && attemptDropoff(world)) {
            return true;
        }
        return !pickupExhausted && attemptPickup(world);
    }

    private boolean attemptPickup(World world) {
        if (!cargo.hasRoom()) {
            return false;
        }
        var pkg = world.loadingBay().shipNext();
        if (pkg == null) {
            return false;
        }
        world.recordShipment(1);
        cargo.pickUp(pkg);
        pickupTurn = false;
        GameLog.debugf(
                LogTag.DEMAND,
                "Truck picked up package (%d/%d this visit)",
                cargo.inboundCount(),
                capacity
        );
        return true;
    }

    private boolean attemptDropoff(World world) {
        var pkg = cargo.peekNext();
        if (!world.loadingBay().tryPlaceIncoming(pkg)) {
            return false;
        }
        cargo.markDelivered();

        var shelves = world.shelves();
        var suggestedShelf = shelves.get(random.nextInt(shelves.size()));
        world.addJob(new RobotJob(
                nextJobId(),
                JobType.PUTAWAY,
                suggestedShelf.id(),
                pkg,
                world.currentTick()
        ));
        pickupTurn = true;
        GameLog.debugf(
                LogTag.DEMAND,
                "Truck dropped off %s package (%d/%d this visit)",
                pkg.color(),
                cargo.outboundTotal() - cargo.outboundRemaining(),
                cargo.outboundTotal()
        );
        return true;
    }

    private TruckCargo buildCargo(World world) {
        var supplyPlan = supplyPlanner.plan(world, capacity);
        var dropoffCapacity = supplyPlan.effectiveDropoffCapacity();

        logSupplyCapacity(dropoffCapacity, world.currentTick());
        var packages = new Array<Package>(supplyPlan.packageCount());
        var colors = PackageColor.colored();

        for (int i = 0; i < colors.size; i++) {
            var color = colors.get(i);
            int allocated = supplyPlan.allocation(color);
            for (int n = 0; n < allocated; n++) {
                packages.add(new Package(world.nextPackageId(), color));
            }
        }
        if (packages.size < dropoffCapacity) {
            GameLog.infof(
                    LogTag.DEMAND,
                    "Next cargo holds %d/%d packages",
                    packages.size,
                    supplyPlan.effectiveDropoffCapacity()
            );
        }
        return new TruckCargo(capacity, packages);
    }

    private void logSupplyCapacity(int effectiveCapacity, int tick) {
        if (previousSupplyCapacity < 0) {
            GameLog.debugf(LogTag.DEMAND,
                    "Supply capacity set: %d (tick %d)",
                    effectiveCapacity,
                    tick
            );
        }
        else if (effectiveCapacity != previousSupplyCapacity) {
            GameLog.debugf(
                    LogTag.DEMAND,
                    "Supply capacity changed: %d -> %d (tick %d)",
                    previousSupplyCapacity,
                    effectiveCapacity,
                    tick
            );
        }
        previousSupplyCapacity = effectiveCapacity;
    }

    private JobId nextJobId() {
        return new JobId("putaway-" + (++nextJobNumber));
    }
}
