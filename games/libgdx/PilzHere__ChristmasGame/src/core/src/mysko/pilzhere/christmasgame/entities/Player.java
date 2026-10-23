package mysko.pilzhere.christmasgame.entities;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;

import mysko.pilzhere.christmasgame.Utils;
import mysko.pilzhere.christmasgame.entities.enemies.Shark;
import mysko.pilzhere.christmasgame.entities.items.Candy;
import mysko.pilzhere.christmasgame.screens.GameScreen;

public class Player extends Entity implements IEntity {
	private Texture currentFrame;

	private final Texture texIdleDown, texIdleUp, texIdleLeft, texIdleRight;

	private Animation<Texture> currentanAnimation;

	private final Texture texWalkDown1, texWalkDown3;
	private Animation<Texture> animWalkDown;
	private Texture[] walkDownFrames;

	private final Texture texChopDown1, texChopDown2;
	private Animation<Texture> animChopDown;
	private Texture[] chopDownFrames;

	private final Texture texChopUp1, texChopUp2;
	private Animation<Texture> animChopUp;
	private Texture[] chopUpFrames;

	private final Texture texChopRight1, texChopRight2;
	private Animation<Texture> animChopRight;
	private Texture[] chopRightFrames;

	private final Texture texWalkUp1, texWalkUp3;
	private Animation<Texture> animWalkUp;
	private Texture[] walkUpFrames;

	private final Texture texWalkRight1, texWalkRight2, texWalkRight3, texWalkRight4, texWalkRight5, texWalkRight6,
			texWalkRight7, texWalkRight8;
	private Animation<Texture> animWalkRight;
	private Texture[] walkRightFrames;

	private final Texture texWaterRight, texWaterUp, texWaterDown;

	public final Sprite sprite; // get

	public SpriteDirection spriteDir; // get-set

	public int logsAmount; // get-set
	public int candyAmount; // get-set

	public PlayerTerrain action = PlayerTerrain.NORMAL; // get-set

	public int hp; // get-set?

	public Player(GameScreen screen, Vector3 position) {
		super(screen, position);

		hp = 5;

		shapeColor = Color.ORANGE;

		texIdleDown = screen.assMan.get("santaStandingDown.png");
		texIdleUp = screen.assMan.get("santaStandingUp.png");
		texIdleLeft = screen.assMan.get("santaStandingLeft.png");
		texIdleRight = screen.assMan.get("santaStandingRight.png");

		texWaterRight = screen.assMan.get("santaWaterRight.png");
		texWaterUp = screen.assMan.get("santaWaterUp.png");
		texWaterDown = screen.assMan.get("santaWaterDown.png");

		texWalkDown1 = screen.assMan.get("santaWalkingDown1.png");
		texWalkDown3 = screen.assMan.get("santaWalkingDown3.png");

		walkDownFrames = new Texture[4];
		walkDownFrames[0] = texWalkDown1;
		walkDownFrames[1] = texIdleDown;
		walkDownFrames[2] = texWalkDown3;
		walkDownFrames[3] = texIdleDown;

		animWalkDown = new Animation<Texture>(0.1f, walkDownFrames);

		texChopDown1 = screen.assMan.get("santaChoppingDown1.png");
		texChopDown2 = screen.assMan.get("santaChoppingDown2.png");

		chopDownFrames = new Texture[2];
		chopDownFrames[0] = texChopDown1;
		chopDownFrames[1] = texChopDown2;

		animChopDown = new Animation<Texture>(0.1f, chopDownFrames);

		texChopUp1 = screen.assMan.get("santaChoppingUp1.png");
		texChopUp2 = screen.assMan.get("santaChoppingUp2.png");

		chopUpFrames = new Texture[2];
		chopUpFrames[0] = texChopUp1;
		chopUpFrames[1] = texChopUp2;

		animChopUp = new Animation<Texture>(0.1f, chopUpFrames);

		texChopRight1 = screen.assMan.get("santaChoppingRight1.png");
		texChopRight2 = screen.assMan.get("santaChoppingRight2.png");

		chopRightFrames = new Texture[2];
		chopRightFrames[0] = texChopRight1;
		chopRightFrames[1] = texChopRight2;

		animChopRight = new Animation<Texture>(0.1f, chopRightFrames);

		texWalkUp1 = screen.assMan.get("santaWalkingUp1.png");
		texWalkUp3 = screen.assMan.get("santaWalkingUp3.png");

		walkUpFrames = new Texture[4];
		walkUpFrames[0] = texWalkUp1;
		walkUpFrames[1] = texIdleUp;
		walkUpFrames[2] = texWalkUp3;
		walkUpFrames[3] = texIdleUp;

		animWalkUp = new Animation<Texture>(0.1f, walkUpFrames);

		texWalkRight1 = screen.assMan.get("santaWalkingRight1.png");
		texWalkRight2 = screen.assMan.get("santaWalkingRight2.png");
		texWalkRight3 = screen.assMan.get("santaWalkingRight3.png");
		texWalkRight4 = screen.assMan.get("santaWalkingRight4.png");
		texWalkRight5 = screen.assMan.get("santaWalkingRight5.png");
		texWalkRight6 = screen.assMan.get("santaWalkingRight6.png");
		texWalkRight7 = screen.assMan.get("santaWalkingRight7.png");
		texWalkRight8 = screen.assMan.get("santaWalkingRight8.png");

		walkRightFrames = new Texture[8];
		walkRightFrames[0] = texWalkRight1;
		walkRightFrames[1] = texWalkRight2;
		walkRightFrames[2] = texWalkRight3;
		walkRightFrames[3] = texWalkRight4;
		walkRightFrames[4] = texWalkRight5;
		walkRightFrames[5] = texWalkRight6;
		walkRightFrames[6] = texWalkRight7;
		walkRightFrames[7] = texWalkRight8;

		animWalkRight = new Animation<Texture>(0.1f, walkRightFrames);

		spriteDir = SpriteDirection.DOWN;
		currentanAnimation = animWalkDown;
		currentFrame = texIdleDown;
		sprite = new Sprite(texIdleDown);
		rect = new Rectangle(sprite.getX(), sprite.getY(), sprite.getWidth(), sprite.getHeight());

		screen.setPlayer(this);

		System.out.println("Santa added!");
	}

	private final Vector3 projPos = new Vector3();
	public final Vector3 screenPos = new Vector3(); // get-set

	public float movementSpeed;
	private final float walkSpeed = 12f;
	private final float swimSpeed = 8f;

	private final int deepWater = 811631359;
	private final int shallowWater = 1533993471;
	private int currentColor;

	private float stateTime = 0f;

	private boolean sharkSpawnTimerSet;
	private final long sharkSpawnTimer = 4L;
	private long sharkSpawnTime;

	@Override
	public void tick(float delta) {
		if (hp == 0) {
			screen.gameOver();
			destroy = true;
		}

		stateTime += delta;

		if (attackedTimerSet) {
			currentTime = System.currentTimeMillis();
			if (currentTime >= actualTimeToWait) {
				flash = false;
				attackedTimerSet = false;
			}
		}

		if (position.x < -50) {
			position.x = -50;
		} else if (position.x > 50) {
			position.x = 50;
		}

		if (position.z < -50) {
			position.z = -50;
		} else if (position.z > 50) {
			position.z = 50;
		}

		screenPos.set(Utils.calculateScreenPosition(position.cpy(), projPos.cpy()));
		currentColor = screen.getIsland().readPixels(position.cpy());

		if (currentColor == shallowWater || currentColor == deepWater || currentColor == 0) {
			action = PlayerTerrain.SWIMMING;

			if (screen.shark == null) {
				if (!sharkSpawnTimerSet) {
					sharkSpawnTime = System.currentTimeMillis() + sharkSpawnTimer * 1000L;
					sharkSpawnTimerSet = true;
				} else {
					if (System.currentTimeMillis() >= sharkSpawnTime) {
						if (screen.shark == null)
							screen.shark = new Shark(screen, screen.getClosestSharkSpawnPoint());
						screen.entities.add(screen.shark);
						sharkSpawnTimerSet = false;
					}
				}
			}

		} else {
			action = PlayerTerrain.NORMAL;
			sharkSpawnTimerSet = false;
		}

		if (action == PlayerTerrain.NORMAL) {
			if (controlledMovement && !isChopping) {
				movementSpeed = walkSpeed;

				switch (spriteDir) {
				case DOWN:
					currentanAnimation = animWalkDown;
					sprite.setFlip(false, false);
					break;
				case UP:
					currentanAnimation = animWalkUp;
					sprite.setFlip(false, false);
					break;
				case LEFT:
					currentanAnimation = animWalkRight;
					sprite.setFlip(true, false);
					break;
				case RIGHT:
					currentanAnimation = animWalkRight;
					sprite.setFlip(false, false);
					break;
				}

				sprite.setTexture(currentFrame = currentanAnimation.getKeyFrame(stateTime, true));

			} else {
				if (spriteDir == SpriteDirection.UP) {
					currentFrame = texIdleUp;

					sprite.setFlip(false, false);
				} else if (spriteDir == SpriteDirection.DOWN) {
					currentFrame = texIdleDown;
					sprite.setFlip(false, false);
				} else if (spriteDir == SpriteDirection.LEFT) {
					currentFrame = texIdleLeft;
					sprite.setFlip(false, false);
				} else if (spriteDir == SpriteDirection.RIGHT) {
					currentFrame = texIdleRight;
					sprite.setFlip(false, false);
				}

				sprite.setTexture(currentFrame);
			}
		}

		if (isChopping) {
			if (currentanAnimation.isAnimationFinished(stateTime)) {
				action = PlayerTerrain.NORMAL;
				isChopping = false;
			}

			switch (spriteDir) {
			case DOWN:
				currentanAnimation = animChopDown;
				sprite.setTexture(currentFrame = currentanAnimation.getKeyFrame(stateTime, true));
				sprite.setFlip(false, false);
				break;
			case UP:
				currentanAnimation = animChopUp;
				sprite.setTexture(currentFrame = currentanAnimation.getKeyFrame(stateTime, true));
				sprite.setFlip(false, false);
				break;
			case LEFT:
				currentanAnimation = animChopRight;
				sprite.setTexture(currentFrame = currentanAnimation.getKeyFrame(stateTime, true));
				sprite.setFlip(true, false);
				break;
			case RIGHT:
				currentanAnimation = animChopRight;
				sprite.setTexture(currentFrame = currentanAnimation.getKeyFrame(stateTime, true));
				sprite.setFlip(false, false);
				break;
			}
		}

		if (action == PlayerTerrain.SWIMMING) {
			movementSpeed = swimSpeed;

			switch (spriteDir) {
			case DOWN:
				if (sprite.getTexture() != texWaterDown) {
					sprite.setTexture(texWaterDown);
					sprite.setFlip(false, false);
				}

				break;
			case UP:
				if (sprite.getTexture() != texWaterUp) {
					sprite.setTexture(texWaterUp);
					sprite.setFlip(false, false);
				}

				break;
			case LEFT:
				if (sprite.getTexture() != texWaterRight) {
					sprite.setTexture(texWaterRight);
					sprite.setFlip(true, false);
				}
				break;
			case RIGHT:
				if (sprite.getTexture() != texWaterRight) {
					sprite.setTexture(texWaterRight);
					sprite.setFlip(false, false);
				}
				break;
			}
		}

		setSpriteSize(sprite);
		setSpritePosition(sprite);
		setRectanglePosition(rect);
		setRectangleSize(rect);

		super.tick(delta);

		controlledMovement = false;
	}

	public void checkForOverlaps(float delta) {
		for (Entity ent : screen.entities) {
			if (ent.rect != null) {
				if (rect.overlaps(ent.rect)) {
					if (ent instanceof Candy) {
						((Candy) ent).onTouch(delta);
					} else if (ent instanceof Log) {
						((Log) ent).onTouch(delta);
					} else if (ent instanceof Slade) {
						((Slade) ent).onTouch(delta);
					}
				}
			}
		}
	}

	private boolean attackedTimerSet;
	private long actualTimeToWait;
	private long timeToWait = 1L;
	private long currentTime;

	private boolean flash;

	public void attacked() {
		if (!attackedTimerSet) {
			screen.audio.sfxPlayerHurt.play(screen.game.volume);
			actualTimeToWait = System.currentTimeMillis() + (timeToWait * 1000L);
			hp--;
			flash = true;
			attackedTimerSet = true;
		}
	}

	private boolean controlledMovement;

	public void moveLeft(float delta) {
		spriteDir = SpriteDirection.LEFT;
		position.add(screen.cam.direction.cpy().crs(screen.cam.up).nor().scl(-movementSpeed * delta));
		controlledMovement = true;
	}

	public void moveRight(float delta) {
		spriteDir = SpriteDirection.RIGHT;
		position.add(screen.cam.direction.cpy().crs(screen.cam.up).nor().scl(movementSpeed * delta));
		controlledMovement = true;
	}

	public void moveUp(float delta) {
		spriteDir = SpriteDirection.UP;
		position.add(screen.cam.direction.cpy().sub(0, screen.cam.direction.y, 0).nor().scl(movementSpeed * delta));
		controlledMovement = true;
	}

	public void moveDown(float delta) {
		spriteDir = SpriteDirection.DOWN;
		position.add(screen.cam.direction.cpy().sub(0, screen.cam.direction.y, 0).nor().scl(-movementSpeed * delta));
		controlledMovement = true;
	}

	public boolean isChopping; // get-set

	public void chop(float delta) {
		isChopping = true;
		stateTime = 0;
	}

	@Override
	public void onTouch(float delta) {
		System.out.println("Santa touched!");
	}

	private boolean flashTimerSet;
	private long actualFlashTimeToWait;
	private boolean drawSprite = true;

	@Override
	public void render2D(SpriteBatch batch, float delta) {
		flash();

		if (drawSprite)
			if (!screen.playerWon)
				sprite.draw(batch);
	}

	private void flash() {
		if (flash) {
			if (!flashTimerSet) {
				actualFlashTimeToWait = currentTime + 33L;
				flashTimerSet = true;
			} else {
				if (currentTime >= actualFlashTimeToWait) {
					drawSprite = !drawSprite;
					flashTimerSet = false;
				}
			}
		} else {
			drawSprite = true;
		}
	}

	@Override
	public void destroy() {

	}

	@Override
	public void setSpritePosition(Sprite sprite) {
		sprite.setX(screenPos.x - sprite.getWidth() / 2);
		sprite.setY(screenPos.y - sprite.getHeight() / 2);
	}

	@Override
	public void setRectanglePosition(Rectangle rect) {
		rect.setX(sprite.getX() + sprite.getWidth() / 4);
		rect.setY(sprite.getY() + sprite.getHeight() / 4);
	}

	@Override
	public void setSpriteScale(Sprite sprite) {
		Utils.setSpriteScale(sprite);
	}

	@Override
	public void setSpriteSize(Sprite sprite) {
		sprite.setSize(sprite.getTexture().getWidth() / 4 * screen.game.windowScale,
				sprite.getTexture().getWidth() / 4 * screen.game.getWindowScale());
	}

	@Override
	public void setRectangleSize(Rectangle rect) {
		rect.setWidth(sprite.getWidth() / 2 * sprite.getScaleX());
		rect.setHeight(sprite.getHeight() / 2 * sprite.getScaleY());
	}
}