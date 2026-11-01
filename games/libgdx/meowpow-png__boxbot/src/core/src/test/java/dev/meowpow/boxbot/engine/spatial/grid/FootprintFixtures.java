package dev.meowpow.boxbot.engine.spatial.grid;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.IntSet;

public final class FootprintFixtures {

    private FootprintFixtures() {}

    public static Array<GridPos> tilesOf(Footprint footprint) {
        var tiles = new Array<GridPos>();
        footprint.addTiles(tiles);
        return tiles;
    }

    public static IntSet tileIndicesOf(Footprint footprint, Grid grid) {
        var indices = new IntSet();
        footprint.addTileIndices(grid, indices);
        return indices;
    }

    public static IntSet adjacentTileIndicesOf(Footprint footprint, Grid grid) {
        var indices = new IntSet();
        footprint.addAdjacentWalkableTileIndices(grid, indices);
        return indices;
    }
}
