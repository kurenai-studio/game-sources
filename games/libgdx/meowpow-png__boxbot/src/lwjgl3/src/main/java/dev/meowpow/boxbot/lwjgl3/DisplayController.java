package dev.meowpow.boxbot.lwjgl3;

import dev.meowpow.boxbot.input.GameAction;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.LogTag;
import dev.meowpow.boxbot.render.screen.ScreenPresets;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Graphics;

/**
 * Owns the game window's display mode.
 */
public final class DisplayController {

    private final WorkArea workArea;
    private final boolean trueFullscreen;

    private boolean fullscreen;

    /**
     * Creates the controller.
     *
     * @param workArea monitor's usable work area
     * @param trueFullscreen whether to use real OS fullscreen mode
     * @param startFullscreen whether the window was opened already in fullscreen mode
     */
    public DisplayController(WorkArea workArea, boolean trueFullscreen, boolean startFullscreen) {
        this.workArea = workArea;
        this.trueFullscreen = trueFullscreen;
        this.fullscreen = startFullscreen;
    }

    /**
     * Applies a display-related game action.
     *
     * @param action the action to apply
     */
    public void handle(GameAction action) {
        if (action == GameAction.TOGGLE_FULLSCREEN) {
            toggleFullscreen();
        }
    }

    private void toggleFullscreen() {
        fullscreen = !fullscreen;

        if (fullscreen) {
            if (trueFullscreen) {
                Gdx.graphics.setFullscreenMode(Gdx.graphics.getDisplayMode());
            }
            else {
                // large borderless window instead of true fullscreen
                Gdx.graphics.setWindowedMode(workArea.width(), workArea.height());
                var graphics = (Lwjgl3Graphics) Gdx.graphics;
                graphics.getWindow().setPosition(workArea.x(), workArea.y());
            }
        }
        else {
            applyWindowed();
        }
        GameLog.infof(LogTag.SYSTEM, "Display switched to %s"
                .formatted(fullscreen ? "fullscreen" : "windowed")
        );
    }

    private void applyWindowed() {
        var preset = ScreenPresets.SMALL;

        Gdx.graphics.setWindowedMode(
                preset.width(),
                preset.height()
        );
        int x = workArea.x() + (workArea.width() - preset.width()) / 2;
        int y = workArea.y() + (workArea.height() - preset.height()) / 2;

        var graphics = (Lwjgl3Graphics) Gdx.graphics;
        graphics.getWindow().setPosition(x, y);
    }
}
