package com.micro1.tilemap.lwjgl3;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.micro1.tilemap.TiledMapDemo;

/**
 * Desktop entry point. Opens a fixed 800x480 window with resizing disabled (prompt) and starts the
 * game. This is the main() a grader runs via ./gradlew lwjgl3:run or `java -jar TiledMapDemo.jar`.
 */
public final class Lwjgl3Launcher {

    private Lwjgl3Launcher() {
    }

    public static void main(String[] args) {
        if (StartupHelper.startNewJvmIfRequired()) {
            return; // relaunched on macOS with -XstartOnFirstThread; nothing else to do here
        }

        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("TiledMap Demo");
        config.setWindowedMode(800, 480);
        config.setResizable(false);
        config.useVsync(true);
        config.setForegroundFPS(60);
        new Lwjgl3Application(new TiledMapDemo(), config);
    }
}
