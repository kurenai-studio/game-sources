package com.cal.angelgame;

public abstract class Character extends GameObject {
	
	/**
	 * Anything that the player(s) interacts with: includes the player(s)
	 * implements health bar
	 * 
	 * @param x
	 * @param y
	 * @param width
	 * @param height
	 */
	public int curState;
	// how long we've been in the current state
	public float stateTime;
	
	public int basestr = 50;
	public int basedef = 50;
	public int basespeed = 50;
	public int basehealth = 100;
	public int basehealthSteal = 5;
	
	public int str = 50;
	public int def = 50;
	public int speed = 50;
	public int health = 100;
	public float healthSteal = 0.0f;
	
	public Character(float posx, float posy, float width, float height) {
		super(posx, posy, width, height);
	}

	public Character(float x, float y, float width, float height,
			int str, int def, int speed, int health, int healthSteal){
		super(x, y, width, height);
		this.str = str;
		this.def = def;
		this.speed = speed;
		this.health = health;
		this.healthSteal = healthSteal;
	}

}
