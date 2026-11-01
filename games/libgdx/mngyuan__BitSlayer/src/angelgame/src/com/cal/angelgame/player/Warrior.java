package com.cal.angelgame.player;
import java.util.Timer;

import com.cal.angelgame.enemy.Enemy;

public class Warrior extends PlayerCharacter {
	/**
	 * The basic all-rounded character
	 * 
	 * @param x
	 * @param y
	 * @param width
	 * @param height
	 */
	
	static final float width = 160;
    static final float height= 160;
    int str;
    int def;
    int speed;
    int health;
    int healthSteal;
    
    public Warrior(float posx, float posy) {
		super(posx, posy, width, height);
	}
    
    public Warrior(float x, float y, float width, float height) {
    	super(x, y, width, height);
    }

	public Warrior(float x, float y,
			int str, int def, int speed, int health, int healthSteal){
		super(x, y, width, height, str, def, speed, health, healthSteal, "warrior");
		// TODO Auto-generated constructor stub
		this.str = str;
		this.def = def;
		this.speed = speed;
		this.health = health;
		this.healthSteal = healthSteal;
	}
	
//	public void addSkillTree(){
//		this.SkillTree[0][0] = 
//	}
	
	//Both
	public void InstantKill(Enemy enemy){ // active
		enemy.health = 0;
	}
}
