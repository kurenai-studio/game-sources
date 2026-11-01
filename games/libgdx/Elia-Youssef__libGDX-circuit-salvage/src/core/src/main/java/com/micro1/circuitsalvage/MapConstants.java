package com.micro1.circuitsalvage;

/** The fixed 8x8 salvage grid: window size, tile size, map rectangle, and tile-center math. */
public final class MapConstants {

    public static final int WINDOW_WIDTH = 640;
    public static final int WINDOW_HEIGHT = 480;

    public static final int TILE_SIZE = 48;
    public static final int COLS = 8;
    public static final int ROWS = 8;

    public static final int MAP_LEFT = 128;
    public static final int MAP_BOTTOM = 48;
    public static final int MAP_RIGHT = MAP_LEFT + COLS * TILE_SIZE;
    public static final int MAP_TOP = MAP_BOTTOM + ROWS * TILE_SIZE;

    private MapConstants() {
    }

    public static float tileCenterX(int column) {
        return MAP_LEFT + column * TILE_SIZE + TILE_SIZE / 2f;
    }

    public static float tileCenterY(int row) {
        return MAP_BOTTOM + row * TILE_SIZE + TILE_SIZE / 2f;
    }
}
