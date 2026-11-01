package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.gdx.ArrayView;

import java.util.Objects;

/**
 * A reusable view of the warehouse
 * supplied to a controller decision.
 * <p>
 * <strong>API Note:</strong>
 * The observation and its views are reused after
 * the decision returns. Controllers must inspect
 * them synchronously and not retain them.
 */
public final class Observation {

    private RobotView robot;
    private ArrayView<ShelfView> shelves;
    private ArrayView<JobView> jobs;
    private ArrayView<OrderView> orders;
    private int currentTick;
    private Failures failures;
    private LoadingBayView loadingBay;

    /**
     * Creates an observation with the supplied warehouse state.
     *
     * @param robot the robot's current state
     * @param shelves occupancy of every shelf
     * @param jobs pending putaway jobs
     * @param orders open outbound orders, each with its own deadline
     * @param currentTick the simulation tick this observation was taken at
     * @param failures current shipment failures
     * @param loadingBay the loading bay's current capacity
     *
     * @throws NullPointerException if any argument except {@code currentTick} is null
     */
    public Observation(
            RobotView robot,
            ArrayView<ShelfView> shelves,
            ArrayView<JobView> jobs,
            ArrayView<OrderView> orders,
            int currentTick,
            Failures failures,
            LoadingBayView loadingBay
    ) {
        update(robot, shelves, jobs, orders, currentTick, failures, loadingBay);
    }

    void update(
            RobotView robot,
            ArrayView<ShelfView> shelves,
            ArrayView<JobView> jobs,
            ArrayView<OrderView> orders,
            int currentTick,
            Failures failures,
            LoadingBayView loadingBay
    ) {
        this.robot = Objects.requireNonNull(robot, "robot must not be null");
        this.shelves = Objects.requireNonNull(shelves, "shelves must not be null");
        this.jobs = Objects.requireNonNull(jobs, "jobs must not be null");
        this.orders = Objects.requireNonNull(orders, "orders must not be null");
        this.currentTick = currentTick;
        this.failures = Objects.requireNonNull(failures, "failures must not be null");
        this.loadingBay = Objects.requireNonNull(loadingBay, "loadingBay must not be null");
    }

    /**
     * Returns the robot's current state.
     */
    public RobotView robot() {
        return robot;
    }

    /**
     * Returns the shelves' current state.
     */
    public ArrayView<ShelfView> shelves() {
        return shelves;
    }

    /**
     * Returns the pending putaway jobs.
     */
    public ArrayView<JobView> jobs() {
        return jobs;
    }

    /**
     * Returns the open outbound orders.
     */
    public ArrayView<OrderView> orders() {
        return orders;
    }

    /**
     * Returns the simulation tick for this observation.
     */
    public int currentTick() {
        return currentTick;
    }

    /**
     * Returns the current shipment failures.
     */
    public Failures failures() {
        return failures;
    }

    /**
     * Returns the loading bay's current capacity.
     */
    public LoadingBayView loadingBay() {
        return loadingBay;
    }
}
