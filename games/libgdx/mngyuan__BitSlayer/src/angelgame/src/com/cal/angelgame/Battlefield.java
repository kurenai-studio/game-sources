package com.cal.angelgame;

import com.cal.angelgame.enemy.Enemy;
import com.cal.angelgame.enemy.Monster;
import com.cal.angelgame.player.PlayerCharacter;
import com.cal.angelgame.player.Warrior;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class Battlefield {
	/**
	 * Handles main game loop logic between game instances,
	 * like player and enemies.
	 */
	public interface BattlefieldEventHandler {
		public void playerHit();

		public void playerAttack();

		public void playerDie();

		public void enemyHit(Enemy enemy);

		public void enemyAttack(Enemy enemy);
	}
	 
	public static final float BF_WIDTH = 16; // sidescroll ?!?!?!
	public static final float BF_HEIGHT = 9;
	public static final int BF_STATE_RUNNING = 0;
	public static final int BF_STATE_NEXT_LEVEL = 1;
	public static final int BF_STATE_GAME_OVER = 2;
	public static final int BF_MAX_ENEMIES = 20;
	
	public final PlayerCharacter pchar;
	public final List<Enemy> enemies;
	public final BattlefieldEventHandler handler;
	public final Random rand;
	
	public int curState;
	
	public long lastEnemySpawn = System.nanoTime();
	public int spawnedEnemies = 0;
    public static final float spawnRate = 5.0f; // seconds to next enemy spawn
    public static final float spawnRateMax = 10.0f;
	
	public Battlefield(BattlefieldEventHandler handler) {
		this.pchar = new Warrior(2f, 4.5f);
		this.enemies = new ArrayList<Enemy>();
		this.handler = handler;
		rand = new Random();
		
		generateLevel();
		
		this.curState = BF_STATE_RUNNING;
	}
	
	private void generateLevel() {
		Enemy spawnedEnemy = new Monster(BF_WIDTH, rand.nextFloat() * BF_HEIGHT);
		lastEnemySpawn = System.nanoTime();
	}
	
	public void update(float deltaTime) {
		updatePlayerAndEnemies(deltaTime);
		spawnEnemies();
	}

	
	private void updatePlayerAndEnemies(float deltaTime) {
		int len = enemies.size();
		if (len == 0 && spawnedEnemies >= BF_MAX_ENEMIES)
			curState = BF_STATE_NEXT_LEVEL;
		
		// handle dying first because we dont want to die before
		// player gets to see what kills them
		if (pchar.curState == PlayerCharacter.PLAYER_STATE_DYING &&
				pchar.stateTime > PlayerCharacter.PLAYER_DIE_TIME)
			curState = BF_STATE_GAME_OVER;
		
		for (int i = 0; i < len; i++) {
			// System.out.println("enemy");
			Enemy e = enemies.get(i);
			if (e.curState == Enemy.ENEMY_STATE_DYING && 
					e.stateTime > Enemy.ENEMY_DIE_TIME) {
				enemies.remove(e);
				len = enemies.size();
			}
			if (OverlapTester.overlapRectangles(pchar.bounds, e.bounds)) {
				// handle player attacking enemy
				pchar.destination = pchar.position;
				if (pchar.curState == PlayerCharacter.PLAYER_STATE_ATTACKING &&
						pchar.stateTime > PlayerCharacter.PLAYER_ATTACK_TIME) {
					// only deal damage after animation has played
					e.health -= pchar.str;
					pchar.health += pchar.healthSteal * pchar.str;
					if (e.health <= 0) {
						e.curState = Enemy.ENEMY_STATE_DYING;
						pchar.trackingEnemy = false;
					}
					if (pchar.health > pchar.basehealth) {
						pchar.health = pchar.basehealth;
					}
					
					pchar.curState = PlayerCharacter.PLAYER_STATE_IDLE;
				}
				pchar.curState = PlayerCharacter.PLAYER_STATE_ATTACKING;
				
				
				// handle enemy attacking player
				e.destination = e.position;
				if (e.curState == Enemy.ENEMY_STATE_ATTACKING &&
						e.stateTime > Enemy.ENEMY_ATTACK_TIME) {
					pchar.health -= e.str;
					e.health += e.healthSteal * e.str;
					if (pchar.health <= 0) {
						pchar.curState = PlayerCharacter.PLAYER_STATE_DYING;
					}
					if (e.health > e.basehealth) {
						e.health = e.basehealth;
					}
				}
				e.curState = Enemy.ENEMY_STATE_ATTACKING;
			} else {
				e.destination = pchar.position;
			}
			e.update(deltaTime);
		}
		pchar.update(deltaTime);
	}
	
	private void spawnEnemies() {
		// spawn a new enemy every 5 to 10 seconds
		if (lastEnemySpawn + spawnRate*AngelGame.NANO + spawnRateMax*AngelGame.NANO*rand.nextFloat() < System.nanoTime()) {
			Monster newEnemy = new Monster(0, BF_HEIGHT);
			if (rand.nextFloat() < 0.5) {
				newEnemy.position.x = BF_WIDTH;
			}
			newEnemy.position.y *= rand.nextFloat();
			enemies.add(newEnemy);
			spawnedEnemies++;

            lastEnemySpawn = System.nanoTime();
		}
	}
}
