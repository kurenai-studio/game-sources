package com.balitechy.crashlanding.models;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.Texture.TextureFilter;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.InputListener;
import com.badlogic.gdx.scenes.scene2d.Touchable;
import com.balitechy.crashlanding.GameAudio;
import com.balitechy.crashlanding.screens.GameScreen;

public class LandingPad extends BaseObject {
	
	public static final float HEIGHT = 50;

	public LandingPad(Vector2 position, float width, float height) {
		super(position, width, height);
		
		texture = new Texture(Gdx.files.internal("data/landing_area.png"));
		texture.setFilter(TextureFilter.Linear, TextureFilter.Linear);
	}
	

	@Override
	public void draw(Batch batch, float parentAlpha) {
		batch.draw(texture, position.x, position.y, width, height);
	}

	@Override
	public void dispose() {
		texture.dispose();
	}

}
