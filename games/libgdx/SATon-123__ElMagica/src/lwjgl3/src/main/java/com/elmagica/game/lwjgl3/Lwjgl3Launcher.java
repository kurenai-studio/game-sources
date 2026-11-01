package com.elmagica.game.lwjgl3;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.elmagica.game.ElMagicaGame;
import com.badlogic.gdx.Gdx;

public class Lwjgl3Launcher {
    public static void main(String[] args) {
        if (StartupHelper.startNewJvmIfRequired()) return; // Обходим особенности запуска на macOS и Windows.
        boolean smokeTest = args.length > 0 && args[0].equals("--smoke-test");
        createApplication(smokeTest);
    }

    private static Lwjgl3Application createApplication(boolean smokeTest) {
        ElMagicaGame game = smokeTest ? new ElMagicaGame() {
            int frames;
            @Override public void render() {
                super.render();
                if (++frames == 30) { System.out.println("Packaged game smoke test passed"); Gdx.app.exit(); }
            }
        } : new ElMagicaGame();
        Lwjgl3ApplicationConfiguration config = getDefaultConfiguration();
        if (smokeTest) {
            config.setWindowedMode(1280, 720); config.setInitialVisible(false); config.disableAudio(true);
        }
        return new Lwjgl3Application(game, config);
    }

    private static Lwjgl3ApplicationConfiguration getDefaultConfiguration() {
        Lwjgl3ApplicationConfiguration configuration = new Lwjgl3ApplicationConfiguration();
        configuration.setTitle("ElMagica — Build Beta1.0");
        configuration.useVsync(true);
        // Запасной лимит на случай, если Vsync не сработает.
        configuration.setForegroundFPS(Lwjgl3ApplicationConfiguration.getDisplayMode().refreshRate + 1);

        configuration.setWindowedMode(1920, 1080);
        // Берём разрешение монитора, игровой мир подгонит viewport.
        configuration.setFullscreenMode(Lwjgl3ApplicationConfiguration.getDisplayMode());
        configuration.setWindowIcon("ui/icons/elmagica-128.png", "ui/icons/elmagica-64.png", "ui/icons/elmagica-32.png", "ui/icons/elmagica-16.png");


        return configuration;
    }
}
