package mysko.pilzhere.christmasgame.gui;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;

import mysko.pilzhere.christmasgame.entities.IEntity;
import mysko.pilzhere.christmasgame.screens.GameScreen;

public class CandyIcon extends GUIEntity implements IEntity {
	private final Texture tex;
	private Sprite sprite;

	private int amount;

	public CandyIcon(GameScreen screen, GUI gui, Vector2 screenPos) {
		super(screen, gui, screenPos);

		shapeColor = Color.GRAY;

		tex = screen.assMan.get("candy.png");
		sprite = new Sprite(tex);
		rect = new Rectangle(sprite.getX(), sprite.getY(), sprite.getWidth(), sprite.getHeight());

		System.out.println("CandyIcon added!");
	}

	@Override
	public void tick(float delta) {
		if (screen.getPlayer() != null) {
			amount = screen.getPlayer().candyAmount;
		}

		setSpriteSize(sprite);
		setSpritePosition(sprite);
		setRectanglePosition(rect);
		setRectangleSize(rect);
	}

	@Override
	public void onTouch(float delta) {
		System.out.println("CandyIcon touched!");
	}

	@Override
	public void render2D(SpriteBatch batch, float delta) {
		sprite.draw(batch);
		gui.currentFont.draw(batch, amount + "x", rect.getX() + rect.getWidth() + (2 * screen.game.windowScale),
				rect.getY() + rect.getHeight());
	}

	@Override
	public void setSpritePosition(Sprite sprite) {
		sprite.setX(screenPos.x);
		sprite.setY(screenPos.y);
	}

	@Override
	public void setSpriteScale(Sprite sprite) {

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
