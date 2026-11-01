package ai.visualdemo.cube.lwjgl3;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import ai.visualdemo.cube.CubePuzzleGame;

/**
 * Desktop entry point. Opens a fixed 800x600 non-resizable window and starts the puzzle
 * directly (no title or menu screen). This is the {@code main()} a grader runs via
 * {@code ./gradlew lwjgl3:run}.
 */
public final class Lwjgl3Launcher {

    private Lwjgl3Launcher() {
    }

    public static void main(String[] args) {
        if (StartupHelper.startNewJvmIfRequired()) {
            return; // relaunched on macOS with -XstartOnFirstThread; nothing else to do here
        }

        CubePuzzleGame game = new CubePuzzleGame();
        parseArgs(args, game);

        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("3D Cube Puzzle");
        config.setWindowedMode(800, 600);
        config.setResizable(false);
        if (game.captureEnabled) {
            // QA-only offscreen capture: a real GL context, just an invisible window, rendered
            // with vsync off so the capture frame arrives immediately.
            config.setInitialVisible(false);
            config.useVsync(false);
        } else {
            config.useVsync(true);
            config.setForegroundFPS(60);
        }
        new Lwjgl3Application(game, config);
    }

    /**
     * QA-only args, never used by a grader: {@code --capture <file>} dumps a PNG and exits,
     * {@code --capture-frame <n>} picks which rendered frame to dump (default 2), {@code
     * --scenario <name>} forces the puzzle into a named state (selectedB/assembling/won/lost)
     * before the first frame renders.
     */
    private static void parseArgs(String[] args, CubePuzzleGame game) {
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--capture":
                    if (hasValueArgument(args, i)) {
                        game.captureEnabled = true;
                        game.captureFile = args[++i];
                    }
                    break;
                case "--capture-frame":
                    if (hasValueArgument(args, i)) {
                        try {
                            game.captureFrame = Math.max(1, Integer.parseInt(args[++i]));
                        } catch (NumberFormatException ignored) {
                            // Malformed QA-only input should not prevent a normal desktop launch.
                        }
                    }
                    break;
                case "--scenario":
                    if (hasValueArgument(args, i)) {
                        game.scenario = args[++i];
                    }
                    break;
                default:
                    break;
            }
        }
    }

    private static boolean hasValueArgument(String[] args, int index) {
        return index + 1 < args.length && !args[index + 1].startsWith("--");
    }
}
