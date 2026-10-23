package mysko.pilzhere.christmasgame.entities;

import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.math.Rectangle;

public interface IEntity {
	void setSpritePosition(Sprite sprite);
	
	/**
	 * Dont use this method!
	 * @param sprite
	 */
	void setSpriteScale(Sprite sprite);
	void setRectanglePosition(Rectangle rect);
	void setRectangleSize(Rectangle rect);
	void setSpriteSize(Sprite sprite);
}
