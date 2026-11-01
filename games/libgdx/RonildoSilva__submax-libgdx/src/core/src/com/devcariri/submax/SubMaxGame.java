package com.devcariri.submax;

import com.badlogic.gdx.ApplicationListener;
import com.badlogic.gdx.Gdx;
import com.devcariri.submax.screens.BackGroundScreen;
import com.devcariri.submax.screens.ScreenManager;
import com.devcariri.submax.screens.SplashScreen;

public class SubMaxGame implements ApplicationListener {

	public static ScreenManager screenManager;
	public static ScoreHandler scoreHandler;

	public void create() {
		Assets.loadAssets(); // Carrega minhas texturas e fontes
		screenManager = new ScreenManager();
		screenManager.addScreen(new BackGroundScreen());
		screenManager.addScreen(new SplashScreen());
		scoreHandler = new ScoreHandler();
	}

	public void dispose() {
		screenManager.dispose();
	}

	public void render() {
		Timer.DeltaTime = Gdx.graphics.getDeltaTime();
		screenManager.update();
		screenManager.render();
	}

	public void resize(int width, int height) {
	}

	public void pause() {

	}

	public void resume() {
	}
}
