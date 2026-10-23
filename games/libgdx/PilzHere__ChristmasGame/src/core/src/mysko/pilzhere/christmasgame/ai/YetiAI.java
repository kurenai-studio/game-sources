package mysko.pilzhere.christmasgame.ai;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector3;

import mysko.pilzhere.christmasgame.entities.Player;
import mysko.pilzhere.christmasgame.entities.PlayerTerrain;
import mysko.pilzhere.christmasgame.entities.enemies.Yeti;

public class YetiAI {
	private final Yeti yeti;
	public AIStates state;
	public Player player;

	public YetiAI(Yeti yeti) {
		this.yeti = yeti;
		state = AIStates.IDLE;
	}

	private float distFromPlayer;
	private float distFromTargetPos;
	private final float minDistFromPlayer = 1f;
	private final float detectionDistFromPlayer = 15f;
	private final Vector3 direction = new Vector3();

	private boolean waitTimerSet;
	private long actualTimeToWait;
	private long timeToWait = 1;
	private long currentTime;

	private boolean boredTargetSet;

	private final Vector3 targetPos = new Vector3();

	public void tick(float delta) {
		if (player != null) {
			distFromPlayer = Vector3.dst(yeti.position.x, yeti.position.y, yeti.position.z, player.position.x,
					player.position.y, player.position.z);
		}

		switch (state) {
		case IDLE:
//			System.err.println("IDLE");
			yeti.aggroSfxPlayed = false;

			waitTimerSet = false;

			yeti.movementSpeed = yeti.walkSpeed;

			if (player != null) {
				if (distFromPlayer < detectionDistFromPlayer)
					state = AIStates.CHASING_PLAYER;
				else
					state = AIStates.BORED;
			} else {
				state = AIStates.BORED;
			}
			break;
		case BORED:
//			System.err.println("BORED");

			yeti.movementSpeed = yeti.boredSpeed;

			if (player != null) {
				if (distFromPlayer < detectionDistFromPlayer) {
					boredTargetSet = false;
					state = AIStates.CHASING_PLAYER;
				} else {
					if (!boredTargetSet) {
						targetPos.set(MathUtils.random(-35f, 35f), 0, MathUtils.random(-35f, 35f));
						boredTargetSet = true;
					} else {
						direction.x = (targetPos.x - yeti.position.x);
						direction.y = 0;
						direction.z = (targetPos.z - yeti.position.z);

						direction.nor().scl(yeti.movementSpeed * delta);

						yeti.position.add(direction.cpy());

						distFromTargetPos = Vector3.dst(yeti.position.x, yeti.position.y, yeti.position.z, targetPos.x,
								targetPos.y, targetPos.z);

						if (distFromTargetPos < 1) {
							boredTargetSet = false;
						}
					}
				}
			} else {
				if (!boredTargetSet) {
					targetPos.set(MathUtils.random(-35f, 35f), 0, MathUtils.random(-35f, 35f));
					boredTargetSet = true;
				} else {
					direction.x = (targetPos.x - yeti.position.x);
					direction.y = 0;
					direction.z = (targetPos.z - yeti.position.z);

					direction.nor().scl(yeti.movementSpeed * delta);

					yeti.position.add(direction.cpy());

					distFromTargetPos = Vector3.dst(yeti.position.x, yeti.position.y, yeti.position.z, targetPos.x,
							targetPos.y, targetPos.z);

					if (distFromTargetPos < 1) {
						boredTargetSet = false;
					}
				}
			}
			break;
		case CHASING_PLAYER:
//			System.err.println("CHASING");
			yeti.movementSpeed = yeti.runSpeed;
			
			if (player != null) {
				if (player.action == PlayerTerrain.SWIMMING) {
					state = AIStates.WAIT;
				} else {
					yeti.playAggroSfx();

					direction.x = (player.position.x - yeti.position.x);
					direction.y = 0;
					direction.z = (player.position.z - yeti.position.z);

					direction.nor().scl(yeti.movementSpeed * delta);

					if (distFromPlayer > minDistFromPlayer)
						yeti.position.add(direction.cpy());

					if (distFromPlayer < minDistFromPlayer)
						state = AIStates.ATTACK;

					if (distFromPlayer > detectionDistFromPlayer)
						state = AIStates.IDLE;
				}
			}
			break;
		case ATTACK:
//			System.err.println("ATTACK");
			yeti.attack = true;
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
					yeti.flash = false;
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
