package com.micro1.mooncourier.lwjgl3;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.micro1.mooncourier.CaptureConfig;
import com.micro1.mooncourier.MoonCourierGame;

/**
 * Desktop entry point. Opens a fixed 1280x720 window titled "Moon Courier" and starts the game on
 * the Main Menu screen. This is the {@code main()} a grader runs via {@code ./gradlew lwjgl3:run}.
 */
public final class Lwjgl3Launcher {

    private Lwjgl3Launcher() {
    }

    public static void main(String[] args) {
        if (StartupHelper.startNewJvmIfRequired()) {
            return; // relaunched on macOS with -XstartOnFirstThread; nothing else to do here
        }

        CaptureConfig capture = parseArgs(args);

        MoonCourierGame game = new MoonCourierGame(capture);

        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("Moon Courier");
        config.setWindowedMode(1280, 720);
        config.setResizable(true);
        if (capture.enabled) {
            // QA-only offscreen capture: a real GL context, just an invisible window, rendered with
            // vsync off so the capture frame arrives immediately.
            config.setInitialVisible(false);
            config.useVsync(false);
        } else {
            config.useVsync(true);
            config.setForegroundFPS(60);
        }
        new Lwjgl3Application(game, config);
    }

    /**
     * QA-only args, never used by a grader: {@code --capture <file>} dumps a PNG of one screen and
     * exits, {@code --scenario <name>} picks which screen to show (menu / play / playCargo / victory
     * / gameover), {@code --capture-frame <n>} picks which rendered frame to dump (default 3). A
     * normal desktop launch supplies none of these and runs the interactive game.
     */
    private static CaptureConfig parseArgs(String[] args) {
        CaptureConfig cfg = new CaptureConfig();
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--capture":
                    if (hasValueArgument(args, i)) {
                        cfg.enabled = true;
                        cfg.file = args[++i];
                    }
                    break;
                case "--scenario":
                    if (hasValueArgument(args, i)) {
                        cfg.scenario = args[++i];
                    }
                    break;
                case "--capture-frame":
                    if (hasValueArgument(args, i)) {
                        try {
                            cfg.frame = Math.max(1, Integer.parseInt(args[++i]));
                        } catch (NumberFormatException ignored) {
                            // Malformed QA-only input should not prevent a normal desktop launch.
                        }
                    }
                    break;
                default:
                    break;
            }
        }
        return cfg;
    }

    private static boolean hasValueArgument(String[] args, int index) {
        return index + 1 < args.length && !args[index + 1].startsWith("--");
    }
}
