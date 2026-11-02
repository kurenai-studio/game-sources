package com.micro1.territory.lwjgl3;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.micro1.territory.TerritoryGame;

/**
 * Desktop entry point. Opens a fixed 1100x900 window with resizing disabled (prompt) and starts
 * the game. This is the main() a grader runs via ./gradlew lwjgl3:run or
 * `java -jar TerritoryChallenge.jar`.
 */
public final class Lwjgl3Launcher {

    private Lwjgl3Launcher() {
    }

    public static void main(String[] args) {
        if (StartupHelper.startNewJvmIfRequired()) {
            return; // relaunched on macOS with -XstartOnFirstThread; nothing else to do here
        }

        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("Territory Challenge");
        config.setWindowedMode(1100, 900);
        config.setResizable(false);
        config.useVsync(true);
        config.setForegroundFPS(60);
        new Lwjgl3Application(new TerritoryGame(), config);
    }
}
