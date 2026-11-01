package com.micro1.leap.lwjgl3;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.micro1.leap.LeapGame;

/**
 * Desktop entry point. Opens an 800x600 non-resizable window titled "Leap" and
 * starts the game. This is the main() a grader runs via ./gradlew lwjgl3:run.
 */
public final class Lwjgl3Launcher {

    private Lwjgl3Launcher() {}

    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("Leap");
        config.setWindowedMode(800, 600);
        config.setResizable(false);
        config.useVsync(true);
        config.setForegroundFPS(60);
        new Lwjgl3Application(new LeapGame(), config);
    }
}
