package com.cal.angelgame.item;

import com.cal.angelgame.GameObject;

public abstract class Item extends GameObject {
	// does this need to extend gameobj?
	/**
	 * Base class for any item the playerCharacter can equip
	 * 
	 * @param x
	 * @param y
	 * @param width
	 * @param height
	 */
	private int strInc = 0;
	private int defInc = 0;
	private int speedInc = 0;
	private int healthRegen = 0;
	private int healthSteal = 0;
	
	
	public Item(float x, float y, float width, float height,
			int strInc, int defInc, int speedInc, int healthRegen, int healthSteal){
		super(x, y, width, height);
		// TODO Auto-generated constructor stub
		
	}

}
