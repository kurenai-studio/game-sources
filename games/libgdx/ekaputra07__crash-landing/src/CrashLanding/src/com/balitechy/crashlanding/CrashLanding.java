package com.balitechy.crashlanding;

import com.badlogic.gdx.Game;
import com.balitechy.crashlanding.screens.HomeScreen;

public class CrashLanding extends Game {
	
	public static final boolean DEBUG = false;

	@Override
	public void create() {
		GameAudio.load();
		GameAudio.music.play();
		setScreen(new HomeScreen(this));
	}

	@Override
	public void dispose() {
		// TODO Auto-generated method stub
		GameAudio.dispose();
		super.dispose();
	}

	@Override
	public void pause() {
		// TODO Auto-generated method stub
		super.pause();
	}

	@Override
	public void resume() {
		// TODO Auto-generated method stub
		super.resume();
	}

	@Override
	public void render() {
		// TODO Auto-generated method stub
		super.render();
	}

	@Override
	public void resize(int width, int height) {
		// TODO Auto-generated method stub
		super.resize(width, height);
	}
	
	
}
