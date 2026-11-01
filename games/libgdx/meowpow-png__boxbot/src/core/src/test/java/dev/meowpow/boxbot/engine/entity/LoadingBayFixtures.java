package dev.meowpow.boxbot.engine.entity;

import dev.meowpow.boxbot.engine.spatial.grid.Footprint;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.engine.spatial.grid.TileExtent;

public final class LoadingBayFixtures {

    private LoadingBayFixtures() {}

    public static LoadingBay loadingBay(int capacity) {
        var footprint = new Footprint(
                new GridPos(0, 0),
                new TileExtent(capacity, 1)
        );
        return new LoadingBay(footprint);
    }
}
