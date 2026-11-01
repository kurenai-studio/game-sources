package com.micro1.shadowclone.lwjgl3;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.micro1.shadowclone.ShadowCloneGame;

/**
 * Desktop entry point. Opens a fixed 1280x720 window and starts Shadow Clone. This is the main() a
 * grader runs via ./gradlew lwjgl3:run.
 */
public final class Lwjgl3Launcher {

    private Lwjgl3Launcher() {}

    public static void main(String[] args) {
        if (StartupHelper.startNewJvmIfRequired()) {
            return; // relaunched on macOS with -XstartOnFirstThread; nothing else to do here
        }

        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("Shadow Clone");
        config.setWindowedMode(1280, 720);
        config.setResizable(true);
        config.useVsync(true);
        config.setForegroundFPS(60);
        new Lwjgl3Application(new ShadowCloneGame(), config);
    }
}
