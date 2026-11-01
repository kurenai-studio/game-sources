package com.balitechy.crashlanding.models;

import com.badlogic.gdx.math.Vector2;

public abstract class MovableObject extends BaseObject{
	protected float speed;
	protected Vector2 velocity;
	
	public MovableObject(Vector2 position, float width, float height, Vector2 velocity, float speed) {
		super(position, width, height);
		this.velocity = velocity;
		this.speed = speed;
	}

	public Vector2 getVelocity() {
		return velocity;
	}

	public float getSpeed() {
		return speed;
	}

	public void setSpeed(float speed) {
		this.speed = speed;
	}
}
