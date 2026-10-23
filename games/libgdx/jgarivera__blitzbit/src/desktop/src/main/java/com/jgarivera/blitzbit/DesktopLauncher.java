package com.jgarivera.blitzbit;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.badlogic.gdx.tools.texturepacker.TexturePacker;

// Please note that on macOS your application needs to be started with the -XstartOnFirstThread JVM argument
public class DesktopLauncher {

    public static void main(String[] arg) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();

        config.setTitle("Blitzbit");
        config.setForegroundFPS(60);
        config.useVsync(false);
        config.setWindowedMode(1280, 720);
        config.setWindowSizeLimits(1280, 720, 1920, 1080);

        TexturePacker.Settings settings = new TexturePacker.Settings();
        settings.maxWidth = 512;
        settings.maxHeight = 512;

        TexturePacker.process(settings, "assets", "assets", "pack");

        new Lwjgl3Application(new BlitzbitGame(), config);
    }
}
