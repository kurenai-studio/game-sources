package dev.luchoc.littlespaceship.desktop;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;

/**
 * LWJGL3 launcher. Desktop comes before web even though web is the shipping target: it is the
 * shortest path to something playable, and {@link LittleSpaceshipGame} is identical either way.
 */
public final class DesktopLauncher {

    private DesktopLauncher() {
    }

    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("little-spaceship");
        // An integer multiple of the logical resolution, per CLAUDE.md: integer scaling only, so
        // the window never starts on a fractional factor.
        config.setWindowedMode(
            LittleSpaceshipGame.LOGICAL_WIDTH * 3, LittleSpaceshipGame.LOGICAL_HEIGHT * 3);
        config.useVsync(true);
        config.setForegroundFPS(60);
        new Lwjgl3Application(new LittleSpaceshipGame(), config);
    }
}
