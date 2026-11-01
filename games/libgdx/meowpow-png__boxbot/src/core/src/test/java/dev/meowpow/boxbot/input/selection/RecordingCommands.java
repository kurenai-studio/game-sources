package dev.meowpow.boxbot.input.selection;

import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.robot.PlayerCommands;
import dev.meowpow.boxbot.engine.robot.RelocationDestination;

import org.jspecify.annotations.NullMarked;

import java.util.ArrayList;
import java.util.List;

@NullMarked
final class RecordingCommands implements PlayerCommands {

    final List<RelocationDestination> destinations = new ArrayList<>();

    boolean idle;
    boolean relocating;
    int retrievals;

    RecordingCommands(boolean idle) {
        this.idle = idle;
    }

    @Override
    public void commitRetrieveFromShelf(ShelfId sourceShelfId) {
        retrievals++;
        idle = false;
        relocating = true;
    }

    @Override
    public void commitRelocateFromBay(PackageId packageId, ShelfId destination) {
        relocating = true;
    }

    @Override
    public void commitCharge() {}

    @Override
    public void setDestination(RelocationDestination destination) {
        destinations.add(destination);
    }

    @Override
    public void cancelDestination() {}

    @Override
    public void cancelPickup() {}

    @Override
    public boolean isRelocating() {
        return relocating;
    }

    @Override
    public boolean isIdle() {
        return idle;
    }
}
