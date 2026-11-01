package com.micro1.projectileaiming.lwjgl3;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.micro1.projectileaiming.ProjectileAimingApp;

/**
 * Desktop entry point. Opens the window and starts the app. This is the main() a grader
 * runs via ./gradlew lwjgl3:run.
 */
public final class Lwjgl3Launcher {

    private Lwjgl3Launcher() {}

    public static void main(String[] args) {
        if (StartupHelper.startNewJvmIfRequired()) {
            return; // relaunched on macOS with -XstartOnFirstThread; nothing else to do here
        }

        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("Projectile Aiming");
        config.setWindowedMode(800, 600);
        config.setResizable(false);
        config.useVsync(true);
        config.setForegroundFPS(60);
        new Lwjgl3Application(new ProjectileAimingApp(), config);
    }
}
