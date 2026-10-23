package mysko.pilzhere.christmasgame.entities.enemies;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;

import mysko.pilzhere.christmasgame.Utils;
import mysko.pilzhere.christmasgame.ai.AIStates;
import mysko.pilzhere.christmasgame.ai.YetiAI;
import mysko.pilzhere.christmasgame.entities.Entity;
import mysko.pilzhere.christmasgame.entities.IEntity;
import mysko.pilzhere.christmasgame.entities.SpriteDirection;
import mysko.pilzhere.christmasgame.screens.GameScreen;

public class Yeti extends Entity implements IEntity {
	private Texture currentFrame;

	private Texture texIdleDown, texIdleUp, texIdleLeft, texIdleRight;

	private Animation<Texture> currentanAnimation;

	private final Texture texWalkDown1, texWalkDown3;
	private Animation<Texture> animWalkDown;
	private Texture[] walkDownFrames;

	private final Texture texWalkUp1, texWalkUp3;
	private Animation<Texture> animWalkUp;
	private Texture[] walkUpFrames;

	private final Texture texWalkRight1, texWalkRight2, texWalkRight3, texWalkRight4, texWalkRight5, texWalkRight6,
			texWalkRight7, texWalkRight8;
	private Animation<Texture> animWalkRight;
	private Texture[] walkRightFrames;

	private Sprite sprite;
	public SpriteDirection spriteDir; // get-set

	private final YetiAI ai;

	public Yeti(GameScreen screen, Vector3 position) {
		super(screen, position);

		shapeColor = Color.RED;

		choppable = true;
		hp = 5;

		texIdleDown = screen.assMan.get("yetiStandingDown.png");
		texIdleUp = screen.assMan.get("yetiStandingUp.png");
		texIdleLeft = screen.assMan.get("yetiStandingLeft.png");
		texIdleRight = screen.assMan.get("yetiStandingRight.png");

		texWalkDown1 = screen.assMan.get("yetiWalkingDown1.png");
		texWalkDown3 = screen.assMan.get("yetiWalkingDown3.png");

		walkDownFrames = new Texture[4];
		walkDownFrames[0] = texWalkDown1;
		walkDownFrames[1] = texIdleDown;
		walkDownFrames[2] = texWalkDown3;
		walkDownFrames[3] = texIdleDown;

		animWalkDown = new Animation<Texture>(0.1f, walkDownFrames);

		texWalkUp1 = screen.assMan.get("yetiWalkingUp1.png");
		texWalkUp3 = screen.assMan.get("yetiWalkingUp3.png");

		walkUpFrames = new Texture[4];
		walkUpFrames[0] = texWalkUp1;
		walkUpFrames[1] = texIdleUp;
		walkUpFrames[2] = texWalkUp3;
		walkUpFrames[3] = texIdleUp;

		animWalkUp = new Animation<Texture>(0.1f, walkUpFrames);

		texWalkRight1 = screen.assMan.get("yetiWalkingRight1.png");
		texWalkRight2 = screen.assMan.get("yetiWalkingRight2.png");
		texWalkRight3 = screen.assMan.get("yetiWalkingRight3.png");
		texWalkRight4 = screen.assMan.get("yetiWalkingRight4.png");
		texWalkRight5 = screen.assMan.get("yetiWalkingRight5.png");
		texWalkRight6 = screen.assMan.get("yetiWalkingRight6.png");
		texWalkRight7 = screen.assMan.get("yetiWalkingRight7.png");
		texWalkRight8 = screen.assMan.get("yetiWalkingRight8.png");

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

		ai = new YetiAI(this);
		ai.player = screen.getPlayer();

		System.out.println("Yeti added!");
	}

	private final Vector3 projPos = new Vector3();
	private final Vector3 screenPos = new Vector3();
	private float oldScreenPosX;
	private float oldScreenPosY;

	public float movementSpeed; // get-set
	public final float walkSpeed = 12f;
	public final float runSpeed = 16f;
	public final float swimSpeed = 6f;
	public final float boredSpeed = 2f;

	private float stateTime = 0f;

	float diffScreenPosX = oldScreenPosX - screenPos.x;
	float diffScreenPosY = oldScreenPosY - screenPos.y;

	public boolean attack; // get-set

	public boolean aggroSfxPlayed;

	private long currentTime;
	
	public void playAggroSfx() {
		if (!aggroSfxPlayed) {
			screen.audio.sfxAggro.play(screen.game.volume);
			aggroSfxPlayed = true;
		}
	}

	@Override
	public void tick(float delta) {
		ai.player = screen.getPlayer();
		
		if (hp <= 0) {
			destroy = true;
		}

		stateTime += delta;

		oldScreenPosX = screenPos.x;
		oldScreenPosY = screenPos.y;
		
		if (!screen.gameIsPaused)
			ai.tick(delta);

		if (attack) {
			screen.getPlayer().attacked();
			attack = false;
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

		diffScreenPosX = oldScreenPosX - screenPos.x;
		diffScreenPosY = oldScreenPosY - screenPos.y;

		if (Math.abs(diffScreenPosX) > 0.1f && Math.abs(diffScreenPosY) > 0.1f) {
			if (Math.abs(diffScreenPosX) > Math.abs(diffScreenPosY)) {
				if (diffScreenPosX < 0) {
					spriteDir = SpriteDirection.RIGHT;
				} else if (diffScreenPosX > 0) {
					spriteDir = SpriteDirection.LEFT;
				}
			} else {
				if (diffScreenPosY < 0) {
					spriteDir = SpriteDirection.UP;
				} else if (diffScreenPosY > 0) {
					spriteDir = SpriteDirection.DOWN;
				}
			}
		}

		switch (spriteDir) {
		case DOWN:
			currentanAnimation = animWalkDown;
			sprite.setTexture(currentFrame = currentanAnimation.getKeyFrame(stateTime, true));
			sprite.setFlip(false, false);
			break;
		case UP:
			currentanAnimation = animWalkUp;
			sprite.setTexture(currentFrame = currentanAnimation.getKeyFrame(stateTime, true));
			sprite.setFlip(false, false);
			break;
		case LEFT:
			currentanAnimation = animWalkRight;
			sprite.setTexture(currentFrame = currentanAnimation.getKeyFrame(stateTime, true));
			sprite.setFlip(true, false);
			break;
		case RIGHT:
			currentanAnimation = animWalkRight;
			sprite.setTexture(currentFrame = currentanAnimation.getKeyFrame(stateTime, true));
			sprite.setFlip(false, false);
			break;
		}

		setSpriteSize(sprite);
		setSpritePosition(sprite);
		setRectanglePosition(rect);
		setRectangleSize(rect);

		super.tick(delta);
	}

	private boolean drawSprite = true;
	public boolean flash; //getset
	
	@Override
	public void onChop(float delta) {
		System.out.println("Yeti touched!");
		if (!flash) {
			screen.audio.sfxYetiHurt.play(screen.game.volume);
			hp--;
			ai.state = AIStates.WAIT;
			flash = true;	
		}
	}
	
	private boolean flashTimerSet;
	private long actualFlashTimeToWait;
	
	private void flash() {		
		if (flash) {
			currentTime = System.currentTimeMillis();
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
	public void render2D(SpriteBatch batch, float delta) {
		flash();
		
		switch (hp) {
		case 4:
			sprite.setColor(new Color(1, 0.75f, 0.75f, 1));
			break;
		case 3:
			sprite.setColor(new Color(1, 0.50f, 0.50f, 1));
			break;
		case 2:
			sprite.setColor(new Color(1, 0.25f, 0.25f, 1));
			break;
		case 1:
			sprite.setColor(new Color(1, 0.10f, 0.10f, 1));
			break;
		}

		if (drawSprite)
			sprite.draw(batch);
	}

	@Override
	public void destroy() {
		System.out.println("Yeti destroyed.");
	}

	@Override
	public void setSpritePosition(Sprite sprite) {
		sprite.setX(screenPos.x - sprite.getWidth() / 2);
		sprite.setY(screenPos.y - sprite.getHeight() / 2);
	}

	@Override
	public void setRectanglePosition(Rectangle rect) {
		rect.setX(sprite.getX() + sprite.getWidth() / 4);
		rect.setY(sprite.getY() + sprite.getHeight() / 8);
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
		rect.setHeight(sprite.getHeight() * sprite.getScaleY());
	}
}