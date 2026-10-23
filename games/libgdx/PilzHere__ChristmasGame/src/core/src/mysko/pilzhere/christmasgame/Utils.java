package mysko.pilzhere.christmasgame;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.viewport.Viewport;

public class Utils {
	private static Viewport viewport;

	public static void setViewport(Viewport viewport) {
		Utils.viewport = viewport;
	}

	private static Vector3 tempScreenPosition = new Vector3();

	public static Vector3 calculateScreenPosition(Vector3 position, Vector3 projPos) {
		projPos.set(viewport.project(position.cpy()));
		tempScreenPosition.set(projPos.x, projPos.y, 0);

		return tempScreenPosition.cpy();

//		Old projPos and ScreenPos for trees and candycanes etc...
//		projPos.set(screen.viewport.project(position.cpy()));
//		screenPos.set(projPos.x, projPos.y, 0);
	}

	/**
	 * Don't use this method!
	 * 
	 * @param sprite
	 */
	public static void setSpriteScale(Sprite sprite) {
		sprite.setScale(Gdx.graphics.getWidth() / 1280f, Gdx.graphics.getHeight() / 720f);
	}

}
