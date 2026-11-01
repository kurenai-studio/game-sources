package dev.meowpow.boxbot;

import dev.meowpow.boxbot.config.BoxbotConfig;
import dev.meowpow.boxbot.engine.Simulation;
import dev.meowpow.boxbot.engine.WorldFactory;
import dev.meowpow.boxbot.engine.demand.*;
import dev.meowpow.boxbot.engine.robot.PlayerCommands;
import dev.meowpow.boxbot.engine.robot.RobotController;
import dev.meowpow.boxbot.engine.robot.RobotControllerFactory;
import dev.meowpow.boxbot.engine.robot.RobotDirector;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.engine.time.TickAccumulator;
import dev.meowpow.boxbot.input.selection.SelectionController;
import dev.meowpow.boxbot.map.GridParser;
import dev.meowpow.boxbot.map.ObjectLayerParser;
import dev.meowpow.boxbot.map.TileSizeParser;
import dev.meowpow.boxbot.render.hud.HudState;

import org.jspecify.annotations.NullMarked;

import com.badlogic.gdx.maps.tiled.TiledMap;

import java.util.Random;

/**
 * Assembles game simulation runs.
 */
@NullMarked
final class SimulationFactory {

    private SimulationFactory() {}

    /**
     * Builds a new simulation run.
     *
     * @param config the config to build the run from
     * @param map the loaded tiled map
     * @param controllerFactory creates the robot controller for the run
     * @param playerInputEnabled whether the run accepts player selection input
     * @param clock the simulation clock
     *
     * @return the assembled simulation
     */
    static Simulation build(
            BoxbotConfig config,
            TiledMap map,
            RobotControllerFactory controllerFactory,
            boolean playerInputEnabled,
            SimulationClock clock
    ) {
        var timing = config.timing();
        var warehouse = config.warehouse();
        var demand = config.demand();
        var input = config.input();

        int failureLimit = warehouse.backlogLimit();

        clock.reset();

        var tileSize = TileSizeParser.parse(map);
        var world = WorldFactory.fromLayout(
                ObjectLayerParser.parse(map, tileSize),
                GridParser.parseWalkableGrid(map, "base"),
                warehouse.batteryMaxCapacity(),
                clock
        );
        var robotController = controllerFactory.create(demand.urgentThresholdTicks());

        SelectionController selectionController = null;
        if (playerInputEnabled) {
            selectionController = new SelectionController(
                    playerCommands(robotController),
                    input.selectionQueueLimit()
            );
        }

        var levelRandom = new Random(config.seed());
        var truckSeed = levelRandom.nextLong();
        var preseedSeed = levelRandom.nextLong();
        var demandSeed = levelRandom.nextLong();
        var colorDemand = new ColorDemand(demandSeed);

        new ShelfPreseeder(preseedSeed, colorDemand, demand.preseedFraction()).preseed(world);

        var movementTickAccumulator = new TickAccumulator(timing.robotMovementTickDuration());
        var actionTickAccumulator = new TickAccumulator(timing.robotActionTickDuration());
        var chargingTickAccumulator = new TickAccumulator(timing.robotChargingTickDuration());
        var simulationTickAccumulator = new TickAccumulator(timing.simulationTickDuration());

        var robotDirector = new RobotDirector(world, robotController, failureLimit);
        var demandPlanner = new DemandPlanner(
                demand.baseOrderIntervalTicks(),
                demand.demandCycle()
        );
        var orderGenerator = new OutboundOrderGenerator(
                colorDemand,
                demandPlanner,
                demand.deliveryTimerTicks()
        );
        var supplyPlanner = new SupplyPlanner(colorDemand, demand.supply());
        var truck = new Truck(
                truckSeed,
                supplyPlanner,
                world,
                demand.truckVisitIntervalTicks(),
                demand.truckOperationDelayTicks(),
                demand.truckCapacity()
        );
        var hudState = new HudState(world, truck, simulationTickAccumulator.alpha());

        return new Simulation(
                world,
                tileSize,
                clock,
                failureLimit,
                selectionController,
                robotDirector,
                orderGenerator,
                truck,
                hudState,
                movementTickAccumulator,
                actionTickAccumulator,
                chargingTickAccumulator,
                simulationTickAccumulator
        );
    }

    private static PlayerCommands playerCommands(RobotController controller) {
        if (controller instanceof PlayerCommands commands) {
            return commands;
        }
        var message = "Player-input simulation requires PlayerCommands controller";
        throw new IllegalArgumentException(message);
    }
}
