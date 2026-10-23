package mysko.pilzhere.christmasgame.gui;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;

import mysko.pilzhere.christmasgame.entities.IEntity;
import mysko.pilzhere.christmasgame.screens.GameScreen;

public class HeartIcon extends GUIEntity implements IEntity {
	private final Texture texHalfLeft;
	private final Texture texHalfRight;
	private final Texture texBg;
	private Sprite spriteLeft;
	private Sprite spriteRight;
	private Sprite spriteBg;
	public boolean drawLeft = true;
	public boolean drawRight = true;

	public int offsetX;
	private float realOffsetX;

	public HeartIcon(GameScreen screen, GUI gui, Vector2 screenPos) {
		super(screen, gui, screenPos);

		shapeColor = Color.GRAY;

		texHalfLeft = screen.assMan.get("heartHalf1.png");
		texHalfRight = screen.assMan.get("heartHalf2.png");
		texBg = screen.assMan.get("heartEmpty.png");

		spriteLeft = new Sprite(texHalfLeft);
		spriteRight = new Sprite(texHalfRight);
		spriteBg = new Sprite(texBg);
		rect = new Rectangle(spriteLeft.getX(), spriteLeft.getY(), spriteLeft.getWidth(), spriteLeft.getHeight());

		System.out.println("HeartIcon added!");
	}

	@Override
	public void tick(float delta) {
		screenPos.x = (Gdx.graphics.getWidth() / 2) - (5 * screen.game.windowScale) /* 95 */ + offsetX;

		setSpriteSize(spriteLeft);
		setSpriteSize(spriteRight);
		setSpriteSize(spriteBg);
		setSpritePosition(spriteLeft);
		setSpritePosition(spriteRight);
		setSpritePosition(spriteBg);
		setRectanglePosition(rect);
		setRectangleSize(rect);
	}

	@Override
	public void onTouch(float delta) {
		System.out.println("HeartIcon touched!");
	}

	@Override
	public void render2D(SpriteBatch batch, float delta) {
		spriteBg.draw(batch);
		if (drawLeft)
			spriteLeft.draw(batch);
		if (drawRight)
			spriteRight.draw(batch);
	}

	@Override
	public void setSpritePosition(Sprite sprite) {
		realOffsetX = offsetX * screen.game.windowScale;

		sprite.setX(screenPos.x + realOffsetX);
		sprite.setY(screenPos.y);
	}

	@Override
	public void setSpriteScale(Sprite sprite) {

	}

	@Override
	public void setRectanglePosition(Rectangle rect) {
		rect.x = spriteLeft.getX() + spriteLeft.getWidth() / 4;
		rect.y = spriteLeft.getY() + spriteLeft.getHeight() / 4;
	}

	@Override
	public void setRectangleSize(Rectangle rect) {
		rect.setWidth(spriteLeft.getWidth() / 2 * spriteLeft.getScaleX());
		rect.setHeight(spriteLeft.getHeight() / 2 * spriteLeft.getScaleY());
	}

	@Override
	public void setSpriteSize(Sprite sprite) {
		sprite.setSize(sprite.getTexture().getWidth() / 4 * screen.game.windowScale,
				sprite.getTexture().getWidth() / 4 * screen.game.getWindowScale());
	}
}