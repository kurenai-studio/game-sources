package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.GdxCollections;

/**
 * Builds an {@link Observation} for tests,
 * defaulting everything but the robot to empty/neutral values.
 */
final class ObservationBuilder {

    private static final Failures NO_FAILURES = new Failures(0, 1);
    private static final int TOTAL_BAY_TILES = 1;

    private final RobotView robot;

    private ArrayView<ShelfView> shelves = GdxCollections.emptyView();
    private ArrayView<JobView> jobs = GdxCollections.emptyView();
    private ArrayView<OrderView> orders = GdxCollections.emptyView();

    private int currentTick;
    private int freeBayTiles = 1;

    ObservationBuilder(RobotView robot) {
        this.robot = robot;
    }

    ObservationBuilder shelves(ArrayView<ShelfView> shelves) {
        this.shelves = shelves;
        return this;
    }

    ObservationBuilder jobs(ArrayView<JobView> jobs) {
        this.jobs = jobs;
        return this;
    }

    ObservationBuilder orders(ArrayView<OrderView> orders) {
        this.orders = orders;
        return this;
    }

    ObservationBuilder currentTick(int currentTick) {
        this.currentTick = currentTick;
        return this;
    }

    ObservationBuilder freeBayTiles(int freeBayTiles) {
        this.freeBayTiles = freeBayTiles;
        return this;
    }

    Observation build() {
        var loadingBay = new LoadingBayView(freeBayTiles, TOTAL_BAY_TILES);
        return new Observation(
                robot,
                shelves,
                jobs,
                orders,
                currentTick,
                NO_FAILURES,
                loadingBay
        );
    }
}
