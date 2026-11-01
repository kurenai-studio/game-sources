package dev.meowpow.boxbot.engine;

import dev.meowpow.boxbot.engine.entity.ChargingStation;
import dev.meowpow.boxbot.engine.entity.LoadingBay;
import dev.meowpow.boxbot.engine.entity.Shelf;
import dev.meowpow.boxbot.engine.layout.ShelfSlot;
import dev.meowpow.boxbot.engine.layout.WarehouseLayout;
import dev.meowpow.boxbot.engine.robot.Robot;
import dev.meowpow.boxbot.engine.spatial.grid.Footprint;
import dev.meowpow.boxbot.engine.spatial.grid.Grid;
import dev.meowpow.boxbot.engine.spatial.grid.Zone;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.gdx.GdxCollections;

import com.badlogic.gdx.utils.Array;

/**
 * Assembles a simulation world.
 */
public final class WorldFactory {

    private WorldFactory() {}

    /**
     * Builds a world from a parsed layout, grouping shelves
     * into enclosing zones and assigning each a zone-prefixed label.
     *
     * @return the assembled world, with the robot starting at the loading bay
     */
    public static World fromLayout(
            WarehouseLayout layout,
            Grid grid,
            int robotMaxBattery,
            SimulationClock clock
    ) {
        var shelves = shelves(layout);
        var loadingBay = new LoadingBay(new Footprint(
                layout.loadingBay(),
                layout.loadingBayExtent()
        )
        );
        var chargingStation = new ChargingStation(new Footprint(
                layout.chargingStation(),
                layout.chargingStationExtent()
        ));
        var robot = new Robot(layout.loadingBay(), robotMaxBattery);
        var shelvesView = GdxCollections.viewOf(shelves);

        return new World(robot, shelvesView, loadingBay, chargingStation, grid, clock);
    }

    @SuppressWarnings("ForLoopReplaceableByForEach")
    private static Array<Shelf> shelves(WarehouseLayout layout) {
        var zones = layout.zones();
        var shelves = new Array<Shelf>();
        for (int zoneIndex = 0; zoneIndex < zones.size(); zoneIndex++) {
            var zone = zones.get(zoneIndex);
            var slots = new Array<ShelfSlot>();
            var layoutSlots = layout.shelves();

            for (int slotIndex = 0; slotIndex < layoutSlots.size(); slotIndex++) {
                var slot = layoutSlots.get(slotIndex);
                if (zoneFor(slot, layout) == zone) {
                    slots.add(slot);
                }
            }
            sortByPosition(slots);
            for (int slotIndex = 0; slotIndex < slots.size; slotIndex++) {
                var slot = slots.get(slotIndex);
                shelves.add(new Shelf(slot.id(), slot.pos(), zone.name() + (slotIndex + 1)));
            }
        }
        return shelves;
    }

    @SuppressWarnings("ForLoopReplaceableByForEach")
    private static Zone zoneFor(ShelfSlot slot, WarehouseLayout layout) {
        Zone matchingZone = null;
        var zones = layout.zones();
        for (int i = 0; i < zones.size(); i++) {
            var zone = zones.get(i);
            if (!zone.contains(slot.pos())) {
                continue;
            }
            if (matchingZone != null) {
                var message = "Shelf %d at %s is inside multiple zones";
                throw new IllegalStateException(message.formatted(slot.id().value(), slot.pos()));
            }
            matchingZone = zone;
        }
        if (matchingZone == null) {
            var message = "Shelf %d at %s is not inside any zone";
            throw new IllegalStateException(message.formatted(slot.id().value(), slot.pos()));
        }
        return matchingZone;
    }

    private static void sortByPosition(Array<ShelfSlot> slots) {
        for (int i = 1; i < slots.size; i++) {
            var slot = slots.get(i);
            int j = i - 1;
            while (j >= 0 && isAfter(slots.get(j), slot)) {
                slots.set(j + 1, slots.get(j));
                j--;
            }
            slots.set(j + 1, slot);
        }
    }

    private static boolean isAfter(ShelfSlot first, ShelfSlot second) {
        int firstY = first.pos().y();
        int secondY = second.pos().y();
        return firstY > secondY || firstY == secondY && first.pos().x() > second.pos().x();
    }
}
