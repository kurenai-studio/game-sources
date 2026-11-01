package com.cal.angelgame;

import com.badlogic.gdx.backends.lwjgl.LwjglApplication;
import com.badlogic.gdx.backends.lwjgl.LwjglApplicationConfiguration;

public class Main {
	public static void main(String[] args) {
		LwjglApplicationConfiguration cfg = new LwjglApplicationConfiguration();
		cfg.title = "::BITSLAYER::";
		cfg.useGL20 = false;
		cfg.width = 1136;
		cfg.height = 640;
		
		new LwjglApplication(new AngelGame(), cfg);
	}
}
