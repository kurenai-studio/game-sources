package com.cal.angelgame;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.graphics.FPSLogger;

public class AngelGame extends Game {
	/**
	 * Contains first run start function, which
	 * loads settings, loads assets, and passes
	 * control to the menus and other Screens.
	 */
	// 16:9. we'll think about different platforms later.
	public static final int SCREEN_WIDTH = 1024;
	public static final int SCREEN_HEIGHT = 576;

    public static final float NANO = 1000000000f;
	
	boolean firstTimeCreate = true;
	FPSLogger fps;
	
	@Override
	public void create() {
		Settings.load();
		Assets.load();
		setScreen(new MainMenuScreen(this));
		fps = new FPSLogger();
	}
	
	@Override
	public void render() {
		super.render();
		fps.log();
	}
	
	@Override
	public void dispose() {
		super.dispose();
		
		getScreen().dispose();
	}

}
