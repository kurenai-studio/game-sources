package mysko.pilzhere.christmasgame.entities;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;

import mysko.pilzhere.christmasgame.Utils;
import mysko.pilzhere.christmasgame.screens.GameScreen;

public class Slade extends Entity implements IEntity {
	private final Texture texSlade;
	private final Texture texSladeBroken;
	private Sprite sprite;

	public final Vector3 targetPos = new Vector3(); // get-set

	public Slade(GameScreen screen, Vector3 position) {
		super(screen, position);

		texSlade = screen.assMan.get("slade.png");
		texSladeBroken = screen.assMan.get("sladeBroken.png");
		sprite = new Sprite(texSlade);
		rect = new Rectangle(sprite.getX(), sprite.getY(), sprite.getWidth(), sprite.getHeight());

		targetPos.set(MathUtils.random(-10, 10), 0, MathUtils.random(-10, 10));

		System.out.println("Slade added!");

		screen.audio.sfxSlade.play(screen.game.volume);
	}

	private final Vector3 projPos = new Vector3();
	private final Vector3 screenPos = new Vector3();
	private float oldScreenX;

	private boolean isBroken;

	private boolean targetPosSet;

	@Override
	public void tick(float delta) {
		if (screen.playerWon) {
			if (!targetPosSet) {
				targetPos.set(MathUtils.random(-100, 100), 100, MathUtils.random(-100, 100));
				position.y = 1;
				isBroken = false;
				screen.audio.sfxSlade.play(screen.game.volume);
				targetPosSet = true;
			}

//			hasCrashed = false;
		}

		if (isBroken) {
			if (sprite.getTexture() != texSladeBroken)
				sprite.setTexture(texSladeBroken);
			sprite.setFlip(false, false);
		} else {
			if (sprite.getTexture() != texSlade)
				sprite.setTexture(texSlade);
		}

		if (position.y > 0.5f) {
			final float destX = targetPos.x - position.x;
			final float destY = targetPos.y - position.y;
			final float destZ = targetPos.z - position.z;

			final float dist = (float) Math.sqrt(destX * destX + destY * destY);

//			final destX = destX / dist; // for slowing down
//			final destY = destY / dist; // for slowing down

			final float travelX = destX * 2.25f * delta;
			final float travelY = destY * 2.25f * delta;
			final float travelZ = destZ * 2.25f * delta;

			final float distTravel = (float) Math.sqrt(travelX * travelX + travelY * travelY);

			if (distTravel > dist) {
				position.x = destX;
				position.y = destY;
				position.z = destZ;
			} else {
				position.x += travelX;
				position.y += travelY;
				position.z += travelZ;
			}
		} else {
			position.y = 0;

			if (!hasCrashed)
				crash();
		}

		screenPos.set(Utils.calculateScreenPosition(position.cpy(), projPos.cpy()));

		if (!isBroken) {
			if (oldScreenX < screenPos.x)
				sprite.setFlip(true, false);
			else
				sprite.setFlip(false, false);
		}

		oldScreenX = screenPos.x;

		setSpriteSize(sprite);
		setSpritePosition(sprite);
		setRectanglePosition(rect);
		setRectangleSize(rect);

		super.tick(delta);
	}

	boolean hasCrashed;

	private void crash() {
		screen.audio.sfxCrash.play(screen.game.volume);
		screen.entities.add(new Player(screen, position.cpy()));
		isBroken = true;
		hasCrashed = true;
	}

	@Override
	public void onTouch(float delta) {
		System.out.println("Slade touched!");
		if (screen.getPlayer().logsAmount >= 100) {
			screen.playerWon = true;
		}
	}

	@Override
	public void render2D(SpriteBatch batch, float delta) {
		sprite.draw(batch);
	}

	@Override
	public void destroy() {
		System.out.println("Slade removed!");
	}

	@Override
	public void setSpritePosition(Sprite sprite) {
		sprite.setX(screenPos.x - sprite.getWidth() / 2);
		sprite.setY(screenPos.y - sprite.getHeight() / 2);
	}

	@Override
	public void setSpriteScale(Sprite sprite) {
		Utils.setSpriteScale(sprite);
	}

	@Override
	public void setRectanglePosition(Rectangle rect) {
		rect.x = sprite.getX();
		rect.y = sprite.getY();
	}

	@Override
	public void setRectangleSize(Rectangle rect) {
		rect.setWidth(sprite.getWidth() * sprite.getScaleX());
		rect.setHeight(sprite.getHeight() * sprite.getScaleY());
	}

	@Override
	public void setSpriteSize(Sprite sprite) {
		sprite.setSize(sprite.getTexture().getWidth() / 4 * screen.game.windowScale,
				sprite.getTexture().getWidth() / 4 * screen.game.getWindowScale());
	}
}