package dev.meowpow.boxbot.logging;

/**
 * Logging categories for game
 * subsystems and simulation domains.
 */
public enum LogTag {

    SYSTEM("System"),
    ASSETS("Assets"),
    WORLD("World"),
    MAP("Map"),
    DEMAND("Demand"),
    ROBOT("Robot"),
    JOB("Job"),
    ROUTE("Route"),
    INPUT("Input"),
    RENDER("Render");

    final String label;

    LogTag(String label) {
        this.label = label;
    }
}
