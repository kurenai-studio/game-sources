package com.micro1.mooncourier;

/**
 * The three states of a single mission inside {@link MissionWorld}. These are the internal states of
 * the Gameplay Scene only; the four player-facing screens (Main Menu, Gameplay, Victory, Game Over)
 * are the {@code com.badlogic.gdx.Screen}s hosted by {@link MoonCourierGame}.
 */
public enum GameState {
    /** The mission is running: the ship moves, fuel drains, cargo can be collected and delivered. */
    PLAYING,
    /** The ship reached the delivery pad carrying the cargo before fuel ran out. */
    WON,
    /** Fuel reached zero before the cargo was delivered. */
    LOST
}
