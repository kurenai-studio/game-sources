package com.cal.angelgame.player;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.math.Vector3;
import com.cal.angelgame.Assets;
import com.cal.angelgame.Character;
import com.cal.angelgame.OverlapTester;
import com.cal.angelgame.enemy.Enemy;
import com.cal.angelgame.skill.Skill;
import com.cal.angelgame.skill.SkillTree;

public abstract class PlayerCharacter extends Character {
	/**
	 * Player controlled character
	 * 
	 * @param x
	 * @param y
	 * @param width
	 * @param height
	 */
	// animation states, also for logic
	public static final int PLAYER_STATE_IDLE = 0;
	public static final int PLAYER_STATE_MOVING = 1;
	public static final int PLAYER_STATE_ATTACKING = 2;
	public static final int PLAYER_STATE_DYING = 3;
	
	public static float PLAYER_WIDTH = 0f;
	public static float PLAYER_HEIGHT = 0f;
	
	public static final float PLAYER_ATTACK_TIME = 0.2f;
	public static final float PLAYER_DIE_TIME = 1.0f;
	
	public Vector2 destination;
	public Enemy trackedEnemy;
	public boolean trackingEnemy = false;
	
	int currLevel = 0;
	int xp = 0;
	int levelUpXp = 100;
	int levels = 10;
	Skill unlockedSkill[] = new Skill[levels];
	SkillTree skillTree[][];
	boolean dead = false;
	public String characterType;
	
	public PlayerCharacter(float posx, float posy, float width, float height) {
		super(posx, posy, PLAYER_WIDTH, PLAYER_HEIGHT);
		destination = new Vector2(posx, posy);
		curState = PLAYER_STATE_IDLE;
	}
	
	public PlayerCharacter(float x, float y, float width, float height,
			int str, int def, int speed, int health, int healthSteal, String characterType){
		super(x, y, width, height, str, def, speed, health, healthSteal);
		this.characterType = characterType;
		destination = new Vector2(x, y);
		curState = PLAYER_STATE_IDLE;
	}

	public void levelUp(Skill skillPicked){
		this.str += 10;
		this.def += 10;
		this.speed += 5;
		this.health += 10;
		this.healthSteal += 3;
		levelUpXp *= 10;
		unlockedSkill[currLevel] = skillPicked;
		currLevel += 1;
	}
	
	// Game logic
	public void update(float deltaTime) {
		System.out.println("update");
		// should this go here? why not.
		if (trackingEnemy)
			destination.set(trackedEnemy.position);
		if (!OverlapTester.pointInRectangle(this.bounds, this.destination)) { // this check is not working
			System.out.println("not in destination");
//			float theta = MathUtils.atan2(this.destination.x - this.position.x, this.destination.y - this.position.y);
//			position.add(MathUtils.cos(theta) * speed * deltaTime, MathUtils.sin(theta) * speed/2 * deltaTime); // y moves slower
			// fuckin dumb cuz trig is hard
			if (position.x < destination.x)
				position.x += speed * deltaTime;
			if (position.y < destination.y)
				position.y += speed * deltaTime;
			if (position.x > destination.x)
				position.x -= speed * deltaTime;
			if (position.y > destination.y)
				position.y -= speed * deltaTime;
			curState = PLAYER_STATE_MOVING;
		} else {
			System.out.println("else");
			curState = PLAYER_STATE_IDLE;
		}
		System.out.println("POS " + position + " BOUND " + bounds + " DEST " + destination);
		bounds.x = position.x - bounds.width / 2;
		bounds.y = position.y - bounds.height / 2;
		stateTime += deltaTime;
	}
	
}
