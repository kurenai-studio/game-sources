package com.micro1.mooncourier;

/**
 * QA-only offscreen-capture settings, populated by the launcher from {@code --capture} args. When
 * {@link #enabled} is false (the normal desktop launch) the game runs interactively and none of this
 * has any effect. Kept in the core module so {@link MoonCourierGame} can read it without depending on
 * the launcher.
 */
public final class CaptureConfig {
    /** True only when a {@code --capture <file>} arg was supplied; a grader never sets this. */
    public boolean enabled = false;
    /** Destination PNG path for the captured frame. */
    public String file = null;
    /** Which screen to show for the capture: menu / play / playCargo / victory / gameover. */
    public String scenario = "menu";
    /** Which rendered frame to dump (lets the layout settle first). */
    public int frame = 3;
}
