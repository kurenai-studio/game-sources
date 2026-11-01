package com.cal.angelgame.enemy;

import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.cal.angelgame.Assets;
import com.cal.angelgame.Character;
import com.cal.angelgame.OverlapTester;

public abstract class Enemy extends Character {
	/**
	 * Anything the player can attack
	 * 
	 * @param x
	 * @param y
	 * @param width
	 * @param height
	 */
	public static final int ENEMY_STATE_DYING = 0;
	public static final int ENEMY_STATE_MOVING = 1;
	public static final int ENEMY_STATE_ATTACKING = 2;
	public static final float ENEMY_ATTACK_TIME = 0.2f;
	public static final float ENEMY_DIE_TIME = 0.5f;

	public int str;
	public int def;
	public int speed;
	public int health;
	public int healthSteal;
	
	public static final Sound hitSound = Assets.monsterHit;
	public static final Sound attackSound = Assets.monsterAttack;
	
	public Vector2 destination = new Vector2();
	
	public Enemy(float posx, float posy, float width, float height) {
		super(posx, posy, width, height);
		destination.x = posx;
		destination.y = posy;
	}
	
	public Enemy(float x, float y, float width, float height,
			int str, int def, int speed, int health, int healthSteal){
		super(x, y, width, height, str, def, speed, health, healthSteal);
		// TODO Auto-generated constructor stub
		this.str = str;
		this.def = def;
		this.speed = speed;
		this.health = health;
		this.healthSteal = healthSteal;
		destination.x = x;
		destination.y = y;
	}
	
	public void update(float deltaTime) {
		if (!OverlapTester.pointInRectangle(this.bounds, this.destination)) {
			float theta = MathUtils.atan2(this.destination.x - this.position.x, this.destination.y - this.position.y);
			position.add(MathUtils.cos(theta) * speed * deltaTime, MathUtils.sin(theta) * speed/2 * deltaTime); // y moves slower
			bounds.x = position.x - bounds.width / 2;
			bounds.y = position.y - bounds.height / 2;
			curState = ENEMY_STATE_MOVING;
		}
		stateTime += deltaTime;
	}
}
