package mysko.pilzhere.christmasgame.entities.items;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;

import mysko.pilzhere.christmasgame.Utils;
import mysko.pilzhere.christmasgame.entities.Entity;
import mysko.pilzhere.christmasgame.entities.IEntity;
import mysko.pilzhere.christmasgame.screens.GameScreen;

public class Candycane extends Entity implements IEntity {
	private Texture texture;
	private Sprite sprite;

	public Candycane(GameScreen screen, Vector3 position) {
		super(screen, position);
		shapeColor = Color.GREEN;

		choppable = true;

		hp = 4;

		texture = screen.assMan.get("candyCane.png");
		sprite = new Sprite(texture);
		rect = new Rectangle(sprite.getX(), sprite.getY(), sprite.getWidth(), sprite.getHeight());

		System.out.println("Candycane added!");
	}

	private final Vector3 projPos = new Vector3();
	private final Vector3 screenPos = new Vector3();

	@Override
	public void tick(float delta) {
		if (hp <= 0) {
			destroy = true;
		}

		screenPos.set(Utils.calculateScreenPosition(position.cpy(), projPos.cpy()));

		setSpriteSize(sprite);
		setSpritePosition(sprite);
		setRectanglePosition(rect);
		setRectangleSize(rect);

		super.tick(delta);
	}

	@Override
	public void onChop(float delta) {
		System.out.println("Candycane touched!");
		screen.audio.sfxChoose.play(screen.game.volume);
		hp--;
	}

	@Override
	public void render2D(SpriteBatch batch, float delta) {
		sprite.draw(batch);
	}

	@Override
	public void destroy() {
		System.out.println("Candycone destroyed!");
		screen.audio.sfxTreeDisapear.play(screen.game.volume);
		screen.entities.add(new Candy(screen, position.cpy()));
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