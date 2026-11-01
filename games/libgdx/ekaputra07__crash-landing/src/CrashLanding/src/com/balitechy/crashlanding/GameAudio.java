package com.balitechy.crashlanding;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;

public class GameAudio {

	public static com.badlogic.gdx.audio.Music music;
	public static com.badlogic.gdx.audio.Sound jet;
	public static com.badlogic.gdx.audio.Sound landed;
	public static com.badlogic.gdx.audio.Sound explode;

	public static void load () {
		music = loadMusic("data/determination.mp3");
		music.setLooping(true);
		jet = load("data/jet.mp3");
		landed = load("data/landed.mp3");
		explode = load("data/explode.mp3");
	}

	private static com.badlogic.gdx.audio.Sound load (String name) {
		return Gdx.audio.newSound(Gdx.files.internal(name));
	}
	
	private static com.badlogic.gdx.audio.Music loadMusic (String name) {
		return Gdx.audio.newMusic(Gdx.files.internal(name));
	}
	
	public static void dispose(){
		music.dispose();
		jet.dispose();
		landed.dispose();
		explode.dispose();
	}
}
