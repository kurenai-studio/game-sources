package com.micro1.monstercafe.lwjgl3;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.micro1.monstercafe.MonsterCafeGame;

/** Desktop (LWJGL3) entry point. Opens a fixed 1280x720 non-resizable window titled "Monster Café Madness". */
public class Lwjgl3Launcher {
    public static void main(String[] args) {
        if (StartupHelper.startNewJvmIfRequired()) {
            return; // handled by the relaunched JVM on macOS
        }

        MonsterCafeGame game = new MonsterCafeGame();
        // Optional QA capture flags (not used in normal play): --capture <file> [--scenario menu|play|victory|gameover]
        for (int i = 0; i < args.length; i++) {
            if ("--capture".equals(args[i]) && i + 1 < args.length) {
                game.captureEnabled = true;
                game.captureFile = args[++i];
            } else if ("--scenario".equals(args[i]) && i + 1 < args.length) {
                game.captureScenario = args[++i];
            }
        }

        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle(MonsterCafeGame.TITLE);
        config.setWindowedMode((int) MonsterCafeGame.WORLD_WIDTH, (int) MonsterCafeGame.WORLD_HEIGHT);
        config.setResizable(false);
        config.setForegroundFPS(60);
        config.useVsync(true);
        if (game.captureEnabled) {
            config.setInitialVisible(false); // hidden render for offscreen QA capture
            config.useVsync(false);
        }
        new Lwjgl3Application(game, config);
    }
}
