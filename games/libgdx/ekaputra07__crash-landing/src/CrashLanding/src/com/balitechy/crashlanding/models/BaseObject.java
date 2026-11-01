package com.balitechy.crashlanding.models;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.scenes.scene2d.Actor;

public abstract class BaseObject extends Actor{
	protected float width;
	protected float height;
	protected Vector2 position;
	protected Texture texture;
	protected Rectangle bounds = new Rectangle();
	
	public BaseObject(Vector2 position, float width, float height){
		this.position = position;
		this.width = width;
		this.height = height;
	
		setBounds(position.x, position.y, width, height);
	}

	public Rectangle getBounds() {
		return bounds;
	}

	public Vector2 getPosition() {
		return position;
	}

	public float getWidth() {
		return width;
	}
	
	public void setWidth(float width) {
		this.width = width;
	}
	
	public float getHeight() {
		return height;
	}
	
	public void setHeight(float height) {
		this.height = height;
	}
	
	public Texture getTexture() {
		return texture;
	}
	
	@Override
	public void setBounds(float x, float y, float width, float height) {
		super.setBounds(x, y, width, height);
		bounds.x = position.x;
		bounds.y = position.y;
		bounds.width = width;
		bounds.height = height;
	}

	@Override
	public void act(float delta){
		setBounds(position.x, position.y, width, height);
	}
	
	// If subclass have texture, texture must disposed from this function.	
	public abstract void dispose();
}
