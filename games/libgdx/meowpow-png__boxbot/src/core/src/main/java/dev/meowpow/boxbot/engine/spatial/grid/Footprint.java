package dev.meowpow.boxbot.engine.spatial.grid;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.IntSet;

import java.util.Objects;

/**
 * The rectangular footprint of a multi-tile entity on the grid.
 *
 * @param anchor the footprint's minimum-coordinate corner
 * @param extent the footprint's size, in tiles
 */
@HotPath
public record Footprint(GridPos anchor, TileExtent extent) {

    /**
     * Constructs a new footprint.
     *
     * @throws NullPointerException if {@code anchor} or {@code extent} is null
     */
    public Footprint {
        Objects.requireNonNull(anchor, "anchor must not be null");
        Objects.requireNonNull(extent, "extent must not be null");
    }

    /**
     * Returns a single-tile footprint anchored at {@code pos}.
     */
    public static Footprint singleTile(GridPos pos) {
        return new Footprint(pos, new TileExtent(1, 1));
    }

    /**
     * Returns the number of tiles covered by this footprint.
     */
    public int tileCount() {
        return extent.widthTiles() * extent.heightTiles();
    }

    /**
     * Adds every tile in this footprint to {@code output}.
     * The caller owns and may reuse the output buffer.
     */
    public void addTiles(Array<GridPos> output) {
        for (int x = anchor.x(); x < anchor.x() + extent.widthTiles(); x++) {
            for (int y = anchor.y(); y < anchor.y() + extent.heightTiles(); y++) {
                output.add(new GridPos(x, y));
            }
        }
    }

    /**
     * Adds the in-bounds tile indices in this footprint to the output.
     */
    public void addTileIndices(Grid grid, IntSet output) {
        for (int x = anchor.x(); x < anchor.x() + extent.widthTiles(); x++) {
            for (int y = anchor.y(); y < anchor.y() + extent.heightTiles(); y++) {
                if (grid.inBounds(x, y)) {
                    output.add(y * grid.width() + x);
                }
            }
        }
    }

    /**
     * Returns the footprint's center X position in pixels.
     *
     * @param tileSize the tile size in pixels
     */
    public float centerX(TileSize tileSize) {
        return (anchor.x() + extent.widthTiles() / 2f) * tileSize.pixels();
    }

    /**
     * Returns the footprint's center Y position in pixels.
     *
     * @param tileSize the tile size in pixels
     */
    public float centerY(TileSize tileSize) {
        return (anchor.y() + extent.heightTiles() / 2f) * tileSize.pixels();
    }

    /**
     * Adds the encoded indices of walkable tiles
     * orthogonally adjacent to this footprint.
     * <p>
     * <strong>API Note:</strong>
     * The caller owns and may reuse the output buffer.
     */
    public void addAdjacentWalkableTileIndices(Grid grid, IntSet output) {
        for (int x = anchor.x(); x < anchor.x() + extent.widthTiles(); x++) {
            for (int y = anchor.y(); y < anchor.y() + extent.heightTiles(); y++) {
                addWalkableIndex(output, grid, x + 1, y);
                addWalkableIndex(output, grid, x - 1, y);
                addWalkableIndex(output, grid, x, y + 1);
                addWalkableIndex(output, grid, x, y - 1);
            }
        }
        removeCoveredIndices(grid, output);
    }

    private void addWalkableIndex(IntSet tiles, Grid grid, int x, int y) {
        if (grid.isWalkable(x, y)) {
            tiles.add(y * grid.width() + x);
        }
    }

    private void removeCoveredIndices(Grid grid, IntSet tiles) {
        for (int x = anchor.x(); x < anchor.x() + extent.widthTiles(); x++) {
            for (int y = anchor.y(); y < anchor.y() + extent.heightTiles(); y++) {
                if (grid.inBounds(x, y)) {
                    tiles.remove(y * grid.width() + x);
                }
            }
        }
    }
}
