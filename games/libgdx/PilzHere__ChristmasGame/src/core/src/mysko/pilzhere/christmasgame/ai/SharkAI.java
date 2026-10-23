package mysko.pilzhere.christmasgame.ai;

import com.badlogic.gdx.math.Vector3;

import mysko.pilzhere.christmasgame.entities.Player;
import mysko.pilzhere.christmasgame.entities.PlayerTerrain;
import mysko.pilzhere.christmasgame.entities.enemies.Shark;

public class SharkAI {
	private final Shark shark;
	public AIStates state;
	public Player player;

	public SharkAI(Shark shark) {
		this.shark = shark;
		
		spawnPos.set(shark.position);
		
		state = AIStates.IDLE;
	}

	private float distFromPlayer;
	private float distFromTargetPos;
	private final float minDistFromPlayer = 1f;
	private final Vector3 direction = new Vector3();

	private boolean waitTimerSet;
	private long actualTimeToWait;
	private long timeToWait = 1;
	private long currentTime;

	private final Vector3 spawnPos = new Vector3();

	public void tick(float delta) {
		if (player != null) {
			distFromPlayer = Vector3.dst(shark.position.x, shark.position.y, shark.position.z, player.position.x,
					player.position.y, player.position.z);
		}

		switch (state) {
		case IDLE:
//			System.err.println("IDLE");
			shark.aggroSfxPlayed = false;

			waitTimerSet = false;

			if (player != null) {
				if (player.action == PlayerTerrain.SWIMMING) {
					state = AIStates.CHASING_PLAYER;
				} else {
					shark.destroy = true;
				}
			}
			break;
		case BORED:
//			System.err.println("BORED");
			state = AIStates.IDLE;
			break;
		case CHASING_PLAYER:
//			System.err.println("CHASING");

			if (player != null) {
				if (player.action == PlayerTerrain.SWIMMING) {

					shark.playAggroSfx();

					direction.x = (player.position.x - shark.position.x);
					direction.y = 0;
					direction.z = (player.position.z - shark.position.z);

					direction.nor().scl(shark.movementSpeed * delta);

					if (distFromPlayer > minDistFromPlayer)
						shark.position.add(direction.cpy());

					if (distFromPlayer < minDistFromPlayer)
						state = AIStates.ATTACK;						
				} else {
					state = AIStates.IDLE;
				}
			}
			break;
		case ATTACK:
//			System.err.println("ATTACK");
			shark.attack = true;
			state = AIStates.WAIT;
			break;
		case WAIT:
//			System.err.println("WAIT");
			if (!waitTimerSet) {
				actualTimeToWait = System.currentTimeMillis() + (timeToWait * 1500L); // 1000
				waitTimerSet = true;
			} else {
				currentTime = System.currentTimeMillis();
				if (currentTime >= actualTimeToWait) {
					state = AIStates.IDLE;
				}
			}

			break;
		case DEAD:
//			System.err.println("DEAD");
			state = AIStates.IDLE;
			break;
		}
	}
}