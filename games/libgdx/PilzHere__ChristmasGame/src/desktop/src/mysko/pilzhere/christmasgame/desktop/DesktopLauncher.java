package mysko.pilzhere.christmasgame.desktop;

import com.badlogic.gdx.backends.lwjgl.LwjglApplication;
import com.badlogic.gdx.backends.lwjgl.LwjglApplicationConfiguration;
import com.badlogic.gdx.graphics.Color;

import mysko.pilzhere.christmasgame.ChristmasGame;

public class DesktopLauncher {
	public static void main(String[] arg) {
		LwjglApplicationConfiguration config = new LwjglApplicationConfiguration();

		config.foregroundFPS = 60;
		config.backgroundFPS = 60;
		config.title = "Santa's Crashing Christmas";
		config.fullscreen = false;
		config.resizable = false;
		config.width = 256;
		config.height = 144;
		config.initialBackgroundColor = Color.WHITE;
		config.samples = 0;
		config.vSyncEnabled = false;
//		config.addIcon(path, fileType);

		new LwjglApplication(new ChristmasGame(), config);
	}
}
