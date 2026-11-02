package com.bossfight.desktop;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Window;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3WindowAdapter;
import com.badlogic.gdx.utils.Os;
import com.badlogic.gdx.utils.SharedLibraryLoader;
import com.bossfight.MainGame;
import com.bossfight.config.Constants;
import org.lwjgl.system.Configuration;

public final class DesktopLauncher {
    private DesktopLauncher() {
    }

    public static void main(String[] args) {
        if (SharedLibraryLoader.os == Os.MacOsX) {
            Configuration.GLFW_LIBRARY_NAME.set("glfw_async");
        }

        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle(Constants.GAME_TITLE);
        config.setFullscreenMode(Lwjgl3ApplicationConfiguration.getDisplayMode());
        config.setInitialVisible(false);
        config.setForegroundFPS(Constants.TARGET_FPS);
        config.useVsync(true);
        config.setWindowListener(new Lwjgl3WindowAdapter() {
            @Override
            public void created(Lwjgl3Window window) {
                requestInitialFocus(window);
            }
        });

        new Lwjgl3Application(new MainGame(), config);
    }

    private static void requestInitialFocus(Lwjgl3Window window) {
        window.postRunnable(() -> {
            window.setVisible(true);
            window.focusWindow();
        });
    }
}
