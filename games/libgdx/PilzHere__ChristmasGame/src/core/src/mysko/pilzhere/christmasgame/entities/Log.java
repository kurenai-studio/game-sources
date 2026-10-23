package mysko.pilzhere.christmasgame.entities;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;

import mysko.pilzhere.christmasgame.Utils;
import mysko.pilzhere.christmasgame.screens.GameScreen;

public class Log extends Entity implements IEntity {
	private Texture texture;
	private Sprite sprite;

	public Log(GameScreen screen, Vector3 position) {
		super(screen, position);

		shapeColor = Color.BLUE;

		texture = screen.assMan.get("logs.png");
		sprite = new Sprite(texture);
		rect = new Rectangle(sprite.getX(), sprite.getY(), sprite.getWidth(), sprite.getHeight());

		System.out.println("Logs added!");
	}

	private final Vector3 projPos = new Vector3();
	private final Vector3 screenPos = new Vector3();

	@Override
	public void tick(float delta) {
		screenPos.set(Utils.calculateScreenPosition(position.cpy(), projPos.cpy()));

		setSpriteSize(sprite);
		setSpritePosition(sprite);
		setRectanglePosition(rect);
		setRectangleSize(rect);

		super.tick(delta);
	}

	@Override
	public void onTouch(float delta) {
		System.out.println("Logs taken!");
		screen.audio.sfxPickup.play(screen.game.volume);
		screen.getPlayer().logsAmount++;
		destroy = true;
	}

	@Override
	public void render2D(SpriteBatch batch, float delta) {
		sprite.draw(batch);
	}

	@Override
	public void destroy() {
		System.out.println("Logs taken.");
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
		rect.x = sprite.getX() + sprite.getWidth() / 4;
		rect.y = sprite.getY() + sprite.getHeight() / 4;
	}

	@Override
	public void setRectangleSize(Rectangle rect) {
		rect.setWidth(sprite.getWidth() / 2 * sprite.getScaleX());
		rect.setHeight(sprite.getHeight() / 2 * sprite.getScaleY());
	}

	@Override
	public void setSpriteSize(Sprite sprite) {
		sprite.setSize(sprite.getTexture().getWidth() / 4 * screen.game.windowScale,
				sprite.getTexture().getWidth() / 4 * screen.game.getWindowScale());
	}
}