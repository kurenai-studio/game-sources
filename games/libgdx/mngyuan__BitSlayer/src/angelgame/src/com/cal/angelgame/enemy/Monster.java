package com.cal.angelgame.enemy;

import com.badlogic.gdx.audio.Sound;
import com.cal.angelgame.Assets;

public class Monster extends Enemy {
	/**
	 * Basic Monster enemy
	 * Wrapper class
	 * 
	 * @param x
	 * @param y
	 * @param width
	 * @param height
	 */

    // these are used in the Renderer, which means they shouldn't be pixels
    // Fix later.
	final static float width = 160;
	final static float height = 160; 
	
	public static final Sound hitSound = Assets.monsterHit;
	public static final Sound attackSound = Assets.monsterAttack;
	
	public Monster(float posx, float posy) {
		super(posx, posy, width, height);
	}

	public Monster(float x, float y, 
			int str, int def, int speed, int health, int healthSteal) {
		super(x, y, width, height, str, def, speed, health, healthSteal);
		// TODO Auto-generated constructor stub
	}

}
