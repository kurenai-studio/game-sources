package dev.meowpow.boxbot.engine;

import dev.meowpow.boxbot.engine.demand.OutboundOrderGenerator;
import dev.meowpow.boxbot.engine.demand.Truck;
import dev.meowpow.boxbot.engine.robot.RobotDirector;
import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.engine.time.Alpha;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.engine.time.TickAccumulator;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.input.selection.SelectionController;
import dev.meowpow.boxbot.render.hud.HudState;

import org.jspecify.annotations.Nullable;

import java.util.Objects;

/**
 * Represents a game simulation run.
 */
@HotPath
public final class Simulation {

    private final World world;
    private final TileSize tileSize;
    private final SimulationClock clock;
    private final int failureLimit;

    private final @Nullable SelectionController selectionController;
    private final RobotDirector robotDirector;
    private final OutboundOrderGenerator orderGenerator;

    private final Truck truck;
    private final HudState hudState;

    private final TickAccumulator movementTickAccumulator;
    private final TickAccumulator actionTickAccumulator;
    private final TickAccumulator chargingTickAccumulator;
    private final TickAccumulator simulationTickAccumulator;

    /**
     * @throws NullPointerException if any required argument is null
     * @throws IllegalArgumentException if {@code failureLimit} is negative
     */
    public Simulation(
            World world,
            TileSize tileSize,
            SimulationClock clock,
            int failureLimit,
            @Nullable SelectionController selectionController,
            RobotDirector robotDirector,
            OutboundOrderGenerator orderGenerator,
            Truck truck,
            HudState hudState,
            TickAccumulator movementTickAccumulator,
            TickAccumulator actionTickAccumulator,
            TickAccumulator chargingTickAccumulator,
            TickAccumulator simulationTickAccumulator
    ) {
        Objects.requireNonNull(world, "world must not be null");
        Objects.requireNonNull(tileSize, "tileSize must not be null");
        Objects.requireNonNull(clock, "clock must not be null");
        Objects.requireNonNull(robotDirector, "robotDirector must not be null");
        Objects.requireNonNull(orderGenerator, "retrievalDemandProcess must not be null");
        Objects.requireNonNull(truck, "truck must not be null");
        Objects.requireNonNull(hudState, "hudState must not be null");
        Objects.requireNonNull(movementTickAccumulator, "movementTickAccumulator must not be null");
        Objects.requireNonNull(actionTickAccumulator, "actionTickAccumulator must not be null");
        Objects.requireNonNull(chargingTickAccumulator, "chargingTickAccumulator must not be null");
        Objects.requireNonNull(simulationTickAccumulator, "simulationTickAccumulator must not be null");

        this.world = world;
        this.tileSize = tileSize;
        this.clock = clock;
        if (failureLimit < 0) {
            throw new IllegalArgumentException("failureLimit must be >= 0, got " + failureLimit);
        }
        this.failureLimit = failureLimit;

        this.selectionController = selectionController;
        this.robotDirector = robotDirector;
        this.orderGenerator = orderGenerator;

        this.truck = truck;
        this.hudState = hudState;

        this.movementTickAccumulator = movementTickAccumulator;
        this.actionTickAccumulator = actionTickAccumulator;
        this.chargingTickAccumulator = chargingTickAccumulator;
        this.simulationTickAccumulator = simulationTickAccumulator;
    }

    /**
     * Advances the simulation by {@code delta} seconds.
     *
     * @param delta elapsed time since the last call, in seconds
     */
    public void step(float delta) {
        clock.advanceRealTime(delta);

        int movementTicks = movementTickAccumulator.update(delta);
        for (int i = 0; i < movementTicks; i++) {
            robotDirector.tickMovement();
        }
        int actionTicks = actionTickAccumulator.update(delta);
        for (int i = 0; i < actionTicks; i++) {
            robotDirector.tickAction();
        }
        int chargingTicks = chargingTickAccumulator.update(delta);
        for (int i = 0; i < chargingTicks; i++) {
            robotDirector.tickCharging();
        }
        int simulationTicks = simulationTickAccumulator.update(delta);
        for (int i = 0; i < simulationTicks; i++) {
            world.tick();
            orderGenerator.tick(world);
            truck.tick(world);
        }
    }

    /**
     * Prunes stale selection state and resumes
     * idle selections against the current world.
     * <p>
     * No-op if player input is disabled.
     */
    public void updateSelection() {
        if (selectionController != null) {
            selectionController.pruneStale(world);
            selectionController.resumeIfIdle(world);
        }
        robotDirector.wakeIfIdle();
    }

    /**
     * Returns whether this run has been marked as failed.
     */
    public boolean hasFailed() {
        return world.hasFailed(failureLimit);
    }

    /**
     * Returns the simulation's runtime state.
     */
    public World world() {
        return world;
    }

    /**
     * Returns the pixel size of one grid tile.
     */
    public TileSize tileSize() {
        return tileSize;
    }

    /**
     * Returns the selection controller,
     * or null if player input is disabled.
     */
    public @Nullable SelectionController selectionController() {
        return selectionController;
    }

    /**
     * Returns the loading bay's periodic truck visitor.
     */
    public Truck truck() {
        return truck;
    }

    /**
     * Returns the state HUD panels read from each frame.
     */
    public HudState hudState() {
        return hudState;
    }

    /**
     * Returns current movement tick progress.
     */
    public Alpha movementAlpha() {
        return movementTickAccumulator.alpha();
    }

    /**
     * Returns the shipment-failure backlog limit.
     */
    public int failureLimit() {
        return failureLimit;
    }
}
