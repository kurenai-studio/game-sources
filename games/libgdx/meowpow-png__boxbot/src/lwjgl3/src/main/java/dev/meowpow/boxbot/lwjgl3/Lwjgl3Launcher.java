package dev.meowpow.boxbot.lwjgl3;

import dev.meowpow.boxbot.BoxbotGame;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.input.GameActionDispatcher;
import dev.meowpow.boxbot.input.WorldClickDispatcher;
import dev.meowpow.boxbot.input.WorldHoverDispatcher;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.Slf4jGameLogger;
import dev.meowpow.boxbot.render.screen.ScreenPresets;

import com.badlogic.gdx.InputMultiplexer;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;

import org.lwjgl.glfw.GLFW;

public class Lwjgl3Launcher {

    public static void main(String[] args) {
        var clock = new SimulationClock();
        var config = new Lwjgl3ApplicationConfiguration();

        config.setTitle("Boxbot");
        config.setResizable(false);

        GameLog.init(new Slf4jGameLogger(), clock::currentTick);

        var workArea = primaryMonitorWorkArea();
        var devMode = Boolean.getBoolean("boxbot.dev");

        if (devMode) {
            var x = workArea.x() + (workArea.width() - ScreenPresets.SMALL.width()) / 2;
            var y = workArea.y() + (workArea.height() - ScreenPresets.SMALL.height()) / 2;

            config.setWindowedMode(ScreenPresets.SMALL.width(), ScreenPresets.SMALL.height());
            config.setWindowPosition(x, y);
        }
        else {
            config.setWindowedMode(workArea.width(), workArea.height());
            config.setWindowPosition(workArea.x(), workArea.y());
        }
        var actionDispatcher = new GameActionDispatcher();
        var clickDispatcher = new WorldClickDispatcher();
        var hoverDispatcher = new WorldHoverDispatcher();
        var keyBindings = new KeyBindings(actionDispatcher);
        var mouseBindings = new MouseBindings(actionDispatcher, clickDispatcher, hoverDispatcher);
        var inputProcessor = new InputMultiplexer(keyBindings, mouseBindings);

        var largeScreenPreset = ScreenPresets.compute(workArea.width(), workArea.height());
        var game = new BoxbotGame(
                inputProcessor,
                largeScreenPreset,
                actionDispatcher,
                clickDispatcher,
                hoverDispatcher,
                clock,
                devMode
        );
        var trueFullscreen = Boolean.getBoolean("boxbot.trueFullscreen");
        var displayController = new DisplayController(workArea, trueFullscreen, !devMode);

        actionDispatcher.addListener(displayController::handle);
        new Lwjgl3Application(game, config);
    }

    /**
     * Returns the primary monitor's usable work area, in pixels.
     */
    private static WorkArea primaryMonitorWorkArea() {
        GLFW.glfwInit();

        long monitor = GLFW.glfwGetPrimaryMonitor();
        int[] x = new int[1];
        int[] y = new int[1];
        int[] width = new int[1];
        int[] height = new int[1];

        GLFW.glfwGetMonitorWorkarea(monitor, x, y, width, height);

        return new WorkArea(x[0], y[0], width[0], height[0]);
    }
}
