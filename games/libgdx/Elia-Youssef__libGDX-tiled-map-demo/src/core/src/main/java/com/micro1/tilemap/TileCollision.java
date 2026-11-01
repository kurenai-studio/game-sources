package com.micro1.tilemap;

import com.badlogic.gdx.maps.tiled.TiledMapTileLayer;

/**
 * Collision against the invisible "collision" tile layer. A cell is solid when a tile is present in
 * that layer (loaded from a non-zero gid); an empty cell (null) is walkable. Points outside the map
 * are treated as solid so the player can never leave the level. Pure logic (no GL) so it is
 * unit-testable headlessly.
 */
public class TileCollision {

    private final TiledMapTileLayer layer;
    private final int tileSize;
    private final int width;
    private final int height;

    public TileCollision(TiledMapTileLayer layer, int tileSize) {
        this.layer = layer;
        this.tileSize = tileSize;
        this.width = layer.getWidth();
        this.height = layer.getHeight();
    }

    /** True if the world point (wx,wy) falls in a solid collision cell, or outside the map. */
    public boolean blocked(float wx, float wy) {
        int tx = (int) Math.floor(wx / tileSize);
        int ty = (int) Math.floor(wy / tileSize);
        if (tx < 0 || ty < 0 || tx >= width || ty >= height) {
            return true;
        }
        return layer.getCell(tx, ty) != null;
    }

    /**
     * True if an axis-aligned box centered at (cx,cy) with the given half-extents overlaps any solid
     * cell. The box half-extents are smaller than a tile, so testing the four corners is sufficient
     * (no solid tile can fit strictly between the corners).
     */
    public boolean boxBlocked(float cx, float cy, float halfW, float halfH) {
        return blocked(cx - halfW, cy - halfH)
            || blocked(cx + halfW, cy - halfH)
            || blocked(cx - halfW, cy + halfH)
            || blocked(cx + halfW, cy + halfH);
    }
}
