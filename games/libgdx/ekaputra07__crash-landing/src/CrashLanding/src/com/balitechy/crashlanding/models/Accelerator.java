package com.balitechy.crashlanding.models;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.Texture.TextureFilter;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.math.Vector2;

public class Accelerator extends BaseObject {
	
	public static final float WIDTH = 64;
	public static final float HEIGHT = 64;

	public Accelerator(Vector2 position, float width, float height) {
		super(position, width, height);
		texture = new Texture(Gdx.files.internal("data/accelerator.png"));
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
