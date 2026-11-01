package dev.luchoc.littlespaceship.web;

import com.github.xpenatan.gdx.teavm.backends.web.WebApplication;
import com.github.xpenatan.gdx.teavm.backends.web.WebApplicationConfiguration;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;

/**
 * TeaVM launcher. Same {@link LittleSpaceshipGame} as desktop, unchanged: if this class ever needed
 * a platform-specific branch into the core or into {@code game}, that would already be a sign
 * against sharing the two targets.
 */
public final class WebLauncher {

    private WebLauncher() {
    }

    public static void main(String[] args) {
        WebApplicationConfiguration config = new WebApplicationConfiguration();
        // Explicit, non-zero canvas size: with width = height = 0 the backend inherits the
        // container's size, which is 0x0 at the moment the preloader runs, and it ends up with no
        // stage at all — documented in docs/planning/11-technical-prototype-results.md. Fixed at an
        // integer multiple of the logical resolution, same reasoning as DesktopLauncher's windowed
        // mode: browser window resizing is then handled inside the game itself, by
        // PixelPerfectViewport's own integer-scale letterbox (see BaseUiScreen/PlayScreen#resize),
        // not by growing the canvas — the canvas' internal resolution never needs to change for the
        // image to stay pixel-perfect.
        config.width = LittleSpaceshipGame.LOGICAL_WIDTH * 2;
        config.height = LittleSpaceshipGame.LOGICAL_HEIGHT * 2;
        config.showDownloadLogs = true;
        new WebApplication(new LittleSpaceshipGame(), config);
    }
}
