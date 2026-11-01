package dev.meowpow.boxbot.engine.spatial.grid;

import dev.meowpow.boxbot.gdx.HotPath;

/**
 * The grid's walkable tiles, indexed by coordinate.
 */
@HotPath
public final class Grid {

    private final int width, height;
    private final boolean[] walkable;

    /**
     * Creates a grid of the given size,
     * with every tile initially unwalkable.
     *
     * @param width grid width in tiles
     * @param height grid height in tiles
     *
     * @throws IllegalArgumentException if {@code width} or {@code height} is negative
     */
    public Grid(int width, int height) {
        if (width < 0 || height < 0) {
            var message = "width and height must be >= 0, got (%d, %d)";
            throw new IllegalArgumentException(message.formatted(width, height));
        }
        this.width = width;
        this.height = height;
        this.walkable = new boolean[width * height];
    }

    /**
     * Returns the grid's width in tiles.
     */
    public int width() {
        return width;
    }

    /**
     * Returns the grid's height in tiles.
     */
    public int height() {
        return height;
    }

    /**
     * Returns whether ({@code x}, {@code y}) lies within the grid.
     */
    public boolean inBounds(int x, int y) {
        return x >= 0 && x < width && y >= 0 && y < height;
    }

    /**
     * Returns whether ({@code x}, {@code y}) is a walkable, in-bounds tile.
     */
    public boolean isWalkable(int x, int y) {
        return inBounds(x, y) && walkable[y * width + x];
    }

    /**
     * Returns whether {@code pos} is a walkable, in-bounds tile.
     */
    public boolean isWalkable(GridPos pos) {
        return isWalkable(pos.x(), pos.y());
    }

    /**
     * Sets whether ({@code x}, {@code y}) is walkable.
     *
     * @throws IllegalArgumentException if ({@code x}, {@code y}) is out of bounds
     */
    public void setWalkable(int x, int y, boolean value) {
        if (!inBounds(x, y)) {
            throw new IllegalArgumentException("Out of bounds: (%d, %d)".formatted(x, y));
        }
        walkable[y * width + x] = value;
    }
}
