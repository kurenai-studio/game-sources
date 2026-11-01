package com.dev.cariri.hitball;

import com.badlogic.gdx.ApplicationListener;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.dev.cariri.hitball.screens.GameScreenManager;
import com.dev.cariri.hitball.screens.GameplayScreen;
import com.dev.cariri.hitball.utils.Timer;

public class MyGdxGame implements ApplicationListener {

	GameScreenManager gameScreenManager;
	GameplayScreen gameplayScreen;

	private Timer endTimer;
	private float tempoDeJogo;

	@Override
	public void create () {

		gameplayScreen = new GameplayScreen();

		gameScreenManager = new GameScreenManager();
		gameScreenManager.addScreen(gameplayScreen);
	}

	@Override
	public void resize(int width, int height) {

	}

	@Override
	public void render () {
		//Timer.DeltaTime = Gdx.graphics.getDeltaTime();
		Gdx.gl.glClearColor( 0, 0, 0, 1 );
		Gdx.gl.glClear( GL20.GL_COLOR_BUFFER_BIT | GL20.GL_DEPTH_BUFFER_BIT );

		gameScreenManager.update();
		gameScreenManager.render();
	}

	@Override
	public void pause() {

	}

	@Override
	public void resume() {

	}

	@Override
	public void dispose () {
		gameScreenManager.dispose();
	}
}
