package com.devcariri.submax.desktop;

import com.badlogic.gdx.backends.lwjgl.LwjglApplication;
import com.badlogic.gdx.backends.lwjgl.LwjglApplicationConfiguration;
import com.devcariri.submax.Globals;
import com.devcariri.submax.SubMaxGame;

public class DesktopLauncher {
	public static void main (String[] arg) {
		//http://mediag.com/news/popular-screen-resolutions-designing-for-all/

		LwjglApplicationConfiguration config = new LwjglApplicationConfiguration();
		config.title = "SubConMax";
		config.useGL30 = true;
		config.width = 320;
		config.height = 500;

		new LwjglApplication(new SubMaxGame(), config);
	}
}
