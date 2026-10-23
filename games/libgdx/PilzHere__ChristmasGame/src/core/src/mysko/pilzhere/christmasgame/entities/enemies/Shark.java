package mysko.pilzhere.christmasgame.entities.enemies;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;

import mysko.pilzhere.christmasgame.Utils;
import mysko.pilzhere.christmasgame.ai.SharkAI;
import mysko.pilzhere.christmasgame.entities.Entity;
import mysko.pilzhere.christmasgame.entities.IEntity;
import mysko.pilzhere.christmasgame.entities.SpriteDirection;
import mysko.pilzhere.christmasgame.screens.GameScreen;

public class Shark extends Entity implements IEntity {
	private Texture texShark;
	private Sprite sprite;
	public SpriteDirection spriteDir; // get-set

	private final SharkAI ai;

	public Shark(GameScreen screen, Vector3 position) {
		super(screen, position);

		shapeColor = Color.RED;
		
		hp = 5;

		texShark = screen.assMan.get("shark.png");
		spriteDir = SpriteDirection.DOWN;
		sprite = new Sprite(texShark);
		rect = new Rectangle(sprite.getX(), sprite.getY(), sprite.getWidth(), sprite.getHeight());

		ai = new SharkAI(this);
		ai.player = screen.getPlayer();

		System.out.println("Shark added!");
	}

	private final Vector3 projPos = new Vector3();
	private final Vector3 screenPos = new Vector3();
	private float oldScreenPosX;
	private float oldScreenPosY;

	public final float movementSpeed = 16f;

	private float stateTime = 0f;

	float diffScreenPosX = oldScreenPosX - screenPos.x;
	float diffScreenPosY = oldScreenPosY - screenPos.y;

	public boolean attack; // get-set

	public boolean aggroSfxPlayed;

	private long currentTime;
	
	public void playAggroSfx() {
		if (!aggroSfxPlayed) {
			screen.audio.sfxShark.play(screen.game.volume);
			aggroSfxPlayed = true;
		}
	}

	@Override
	public void tick(float delta) {
		ai.player = screen.getPlayer();

		stateTime += delta;

		oldScreenPosX = screenPos.x;
		oldScreenPosY = screenPos.y;
		
		if (!screen.gameIsPaused)
			ai.tick(delta);

		if (attack) {
			screen.getPlayer().attacked();
			attack = false;
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
			sprite.setFlip(false, false);
			break;
		case UP:
			sprite.setFlip(false, false);
			break;
		case LEFT:
			sprite.setFlip(true, false);
			break;
		case RIGHT:
			sprite.setFlip(false, false);
			break;
		}

		setSpriteSize(sprite);
		setSpritePosition(sprite);
		setRectanglePosition(rect);
		setRectangleSize(rect);

		super.tick(delta);
	}
	
	@Override
	public void onChop(float delta) {
		System.out.println("Shark touched!");
	}
	
	@Override
	public void render2D(SpriteBatch batch, float delta) {
			sprite.draw(batch);
	}

	@Override
	public void destroy() {
		screen.shark = null;
		System.out.println("Shark destroyed.");
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
