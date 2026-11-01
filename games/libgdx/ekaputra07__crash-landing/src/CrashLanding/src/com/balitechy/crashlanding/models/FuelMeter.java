package com.balitechy.crashlanding.models;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.Texture.TextureFilter;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.math.Vector2;

public class FuelMeter extends BaseObject {
	private Texture textureBar, textureSafe, textureCritical;
	private float level; //percentage of fuel level

	public FuelMeter(Vector2 position, float width, float height) {
		super(position, width, height);
		
		textureBar = new Texture(Gdx.files.internal("data/white.png"));
		textureBar.setFilter(TextureFilter.Linear, TextureFilter.Linear);
		
		textureSafe = new Texture(Gdx.files.internal("data/green.png"));
		textureSafe.setFilter(TextureFilter.Linear, TextureFilter.Linear);
		
		textureCritical = new Texture(Gdx.files.internal("data/red.png"));
		textureCritical.setFilter(TextureFilter.Linear, TextureFilter.Linear);
	}
	
	public void setLevel(float level) {
		this.level = level;
	}

	@Override
	public void draw(Batch batch, float parentAlpha) {
		batch.draw(textureBar, position.x, position.y, width, height);
		if(level > 0.5f)
			batch.draw(textureSafe, position.x, position.y, width*level, height);
		else
			batch.draw(textureCritical, position.x, position.y, width*level, height);
	}

	
	@Override
	public void dispose() {
		textureBar.dispose();
		textureSafe.dispose();
		textureCritical.dispose();
	}

}
