package dev.meowpow.boxbot.config;

import com.badlogic.gdx.utils.JsonValue;

/**
 * Parses {@link BoxbotConfig} from a parsed JSON tree.
 */
final class ConfigParser {

    private ConfigParser() {}

    static BoxbotConfig parse(JsonValue root) {
        return new BoxbotConfig(
                root.getLong("seed"),
                parseTiming(child(root, "timing")),
                parseWarehouse(child(root, "warehouse")),
                parseDemand(child(root, "demand")),
                parseInput(child(root, "input")),
                parseUi(child(root, "ui"))
        );
    }

    private static TimingConfig parseTiming(JsonValue timing) {
        return new TimingConfig(
                timing.getFloat("robotMovementTickDuration"),
                timing.getFloat("robotActionTickDuration"),
                timing.getFloat("robotChargingTickDuration"),
                timing.getFloat("simulationTickDuration")
        );
    }

    private static WarehouseConfig parseWarehouse(JsonValue warehouse) {
        return new WarehouseConfig(
                warehouse.getInt("batteryMaxCapacity"),
                warehouse.getInt("backlogLimit")
        );
    }

    private static DemandConfig parseDemand(JsonValue demand) {
        return new DemandConfig(
                demand.getDouble("preseedFraction"),
                demand.getInt("baseOrderIntervalTicks"),
                demand.getInt("deliveryTimerTicks"),
                demand.getInt("urgentThresholdTicks"),
                demand.getInt("truckVisitIntervalTicks"),
                demand.getInt("truckOperationDelayTicks"),
                demand.getInt("truckCapacity"),
                parseSupply(child(demand, "supply")),
                parseDemandCycle(child(demand, "demandCycle"))
        );
    }

    private static SupplyConfig parseSupply(JsonValue supply) {
        return new SupplyConfig(
                supply.getInt("cycleLengthTicks"),
                supply.getDouble("minimumFactor"),
                supply.getDouble("floorFraction")
        );
    }

    private static DemandCycleConfig parseDemandCycle(JsonValue demandCycle) {
        return new DemandCycleConfig(
                demandCycle.getInt("cycleLengthTicks"),
                demandCycle.getDouble("minimumRateFactor"),
                demandCycle.getDouble("maximumRateFactor")
        );
    }

    private static InputConfig parseInput(JsonValue input) {
        return new InputConfig(input.getInt("selectionQueueLimit"));
    }

    private static UiConfig parseUi(JsonValue ui) {
        return new UiConfig(
                ui.getDouble("orderWarningThresholdPercent"),
                ui.getDouble("orderCriticalThresholdPercent")
        );
    }

    private static JsonValue child(JsonValue parent, String name) {
        var value = parent.get(name);
        if (value == null) {
            throw new IllegalArgumentException("Missing config section: " + name);
        }
        return value;
    }
}
