package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.gdx.HotPath;

import org.jspecify.annotations.Nullable;

/**
 * Decides the robot's next action
 * autonomously, without player input.
 */
@HotPath
public final class AiRobotController implements RobotController {

    private static final int LOW_BATTERY_THRESHOLD = 20;

    private final int urgentThresholdTicks;

    /**
     * Creates a new AI-driven controller.
     *
     * @param urgentThresholdTicks ticks before an order becomes urgent
     *
     * @throws IllegalArgumentException if {@code urgentThresholdTicks} is negative
     */
    public AiRobotController(int urgentThresholdTicks) {
        if (urgentThresholdTicks < 0) {
            var message = "urgentThresholdTicks must be >= 0, got " + urgentThresholdTicks;
            throw new IllegalArgumentException(message);
        }
        this.urgentThresholdTicks = urgentThresholdTicks;
    }

    @Override
    public ControllerDecision decide(Observation observation) {
        if (isCarryingPackage(observation)) {
            return decideDelivery(observation);
        }
        if (isBatteryLow(observation)) {
            return new ControllerDecision.Charge();
        }
        return decideJob(observation);
    }

    private boolean isCarryingPackage(Observation observation) {
        return observation.robot().carriedPackageId() != null;
    }

    private ControllerDecision decideDelivery(Observation observation) {
        boolean isRetrieval = observation.robot().carriedJobType() == JobType.RETRIEVAL;
        if (!isRetrieval) {
            return decideStorage(observation);
        }
        if (observation.loadingBay().freeTiles() > 0) {
            return new ControllerDecision.GoToBay();
        }
        var shelf = nearestEmptyShelf(observation);
        return shelf == null ? new ControllerDecision.Idle() : new ControllerDecision.StoreAt(shelf.shelfId());
    }

    private ControllerDecision decideStorage(Observation observation) {
        var shelf = chooseShelf(observation);
        return shelf == null ? new ControllerDecision.Idle() : new ControllerDecision.StoreAt(shelf.shelfId());
    }

    /**
     * Falls back to the closest empty shelf when
     * the bay is full, so a retrieved package still
     * gets stored somewhere rather than the robot idling with it.
     */
    static @Nullable ShelfView nearestEmptyShelf(Observation observation) {
        ShelfView closest = null;

        var position = observation.robot().position();
        int closestDistance = Integer.MAX_VALUE;
        var shelves = observation.shelves();
        for (int i = 0; i < shelves.size(); i++) {
            var shelf = shelves.get(i);
            if (shelf.occupied()) {
                continue;
            }
            int distance = distance(position, shelf.position());
            if (distance < closestDistance) {
                closest = shelf;
                closestDistance = distance;
            }
        }
        return closest;
    }

    private boolean isBatteryLow(Observation observation) {
        return observation.robot().battery().isLow(LOW_BATTERY_THRESHOLD);
    }

    private ControllerDecision decideJob(Observation observation) {
        var urgentShelf = chooseUrgentRetrievalShelf(observation);
        if (urgentShelf != null) {
            return new ControllerDecision.Retrieve(urgentShelf.shelfId());
        }
        var jobs = observation.jobs();
        if (!jobs.isEmpty()) {
            return new ControllerDecision.TakeJob(jobs.get(0).jobId());
        }
        var shelf = chooseRetrievalShelf(observation);
        if (shelf != null) {
            return new ControllerDecision.Retrieve(shelf.shelfId());
        }
        return new ControllerDecision.Idle();
    }

    /**
     * Returns the nearest shelf holding a package for the
     * most urgent open order that can currently be fulfilled.
     */
    private @Nullable ShelfView chooseRetrievalShelf(Observation observation) {
        var order = mostUrgentFulfillableOrder(observation);
        return order == null ? null : nearestShelfOfColor(observation, order.color());
    }

    private static int distance(GridPos a, GridPos b) {
        return Math.abs(a.x() - b.x()) + Math.abs(a.y() - b.y());
    }

    /**
     * Returns the nearest shelf holding a package for
     * the most urgent open order, provided that order
     * is within {@code urgentThresholdTicks} of its deadline.
     * <p>
     * Orders are considered in ascending deadline order; an order
     * whose color has no matching shelf is skipped in favor of the
     * next-most-urgent order, per {@link #mostUrgentFulfillableOrder}.
     */
    private @Nullable ShelfView chooseUrgentRetrievalShelf(Observation observation) {
        var order = mostUrgentFulfillableOrder(observation);
        if (order == null || !isUrgent(order, observation.currentTick())) {
            return null;
        }
        return nearestShelfOfColor(observation, order.color());
    }

    private boolean isUrgent(OrderView order, int currentTick) {
        return order.deadlineTick() - currentTick <= urgentThresholdTicks;
    }

    private @Nullable OrderView mostUrgentFulfillableOrder(Observation observation) {
        int fulfillableColors = occupiedShelfColorMask(observation);

        OrderView mostUrgent = null;
        var orders = observation.orders();
        for (int i = 0; i < orders.size(); i++) {
            var order = orders.get(i);
            if ((fulfillableColors & (1 << order.color().ordinal())) == 0) {
                continue;
            }
            if (mostUrgent == null || order.deadlineTick() < mostUrgent.deadlineTick()) {
                mostUrgent = order;
            }
        }
        return mostUrgent;
    }

    private int occupiedShelfColorMask(Observation observation) {
        int mask = 0;
        var shelves = observation.shelves();
        for (int i = 0; i < shelves.size(); i++) {
            var color = shelves.get(i).color();
            if (color != null) {
                mask |= 1 << color.ordinal();
            }
        }
        return mask;
    }

    private @Nullable ShelfView nearestShelfOfColor(Observation observation, PackageColor color) {
        ShelfView closest = null;

        var position = observation.robot().position();
        int closestDistance = Integer.MAX_VALUE;
        var shelves = observation.shelves();
        for (int i = 0; i < shelves.size(); i++) {
            var shelf = shelves.get(i);
            if (shelf.color() != color) {
                continue;
            }
            int distance = distance(position, shelf.position());
            if (distance < closestDistance) {
                closest = shelf;
                closestDistance = distance;
            }
        }
        return closest;
    }

    private @Nullable ShelfView chooseShelf(Observation observation) {
        var shelves = observation.shelves();
        for (int i = 0; i < shelves.size(); i++) {
            var shelf = shelves.get(i);
            if (!shelf.occupied()) {
                return shelf;
            }
        }
        return null;
    }
}
