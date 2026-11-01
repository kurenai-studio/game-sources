package dev.meowpow.boxbot.input;

/**
 * A player click, in screen coordinates.
 *
 * @param screenX click's x position, in screen pixels
 * @param screenY click's y position, in screen pixels
 */
public record WorldClick(int screenX, int screenY) {}
