package dev.meowpow.boxbot.engine.spatial.grid;

/**
 * A coordinate pair on the tile grid.
 * <p>
 * <strong>API Note:</strong>
 * Not guaranteed to lie within grid bounds;
 * {@link Grid} is what enforces that.
 *
 * @param x horizontal grid coordinate
 * @param y vertical grid coordinate
 */
public record GridPos(int x, int y) {}
