package com.micro1.cookiesort.lwjgl3;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.micro1.cookiesort.CookieSortGame;

/** Desktop (LWJGL3) entry point. Opens a 1600x1200 non-resizable window titled "Cookie Sorting Challenge". */
public class Lwjgl3Launcher {
    public static void main(String[] args) {
        if (StartupHelper.startNewJvmIfRequired()) {
            return; // handled by the relaunched JVM on macOS
        }

        CookieSortGame game = new CookieSortGame();
        // Optional QA capture flags (not used in normal play): --capture <file> [--capture-frame N] [--scenario win|lose]
        for (int i = 0; i < args.length; i++) {
            if ("--capture".equals(args[i]) && i + 1 < args.length) {
                game.captureEnabled = true;
                game.captureFile = args[++i];
            } else if ("--capture-frame".equals(args[i]) && i + 1 < args.length) {
                game.captureFrame = Integer.parseInt(args[++i]);
            } else if ("--scenario".equals(args[i]) && i + 1 < args.length) {
                game.scenario = args[++i];
            }
        }

        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("Cookie Sorting Challenge");
        config.setWindowedMode(1600, 1200);
        config.setResizable(false);
        config.setForegroundFPS(60);
        config.useVsync(true);
        if (game.captureEnabled) {
            config.setInitialVisible(false); // hidden one-frame render for offscreen QA capture
            config.useVsync(false);
        }
        new Lwjgl3Application(game, config);
    }
}
