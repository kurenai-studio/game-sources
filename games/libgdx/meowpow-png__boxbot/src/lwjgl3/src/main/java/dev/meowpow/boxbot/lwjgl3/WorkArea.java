package dev.meowpow.boxbot.lwjgl3;

/**
 * A monitor's usable screen space, in pixels.
 *
 * @param x the work area's left edge
 * @param y the work area's top edge
 * @param width the work area's width
 * @param height the work area's height
 */
public record WorkArea(int x, int y, int width, int height) {}
