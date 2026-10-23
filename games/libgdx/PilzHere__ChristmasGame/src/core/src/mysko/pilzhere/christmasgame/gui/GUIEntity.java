package mysko.pilzhere.christmasgame.gui;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;

import mysko.pilzhere.christmasgame.screens.GameScreen;

public class GUIEntity {
	protected final GameScreen screen;
//	public boolean destroy;
	
	protected final GUI gui;
	
	public final Vector2 screenPos;
	public Rectangle rect;
	public Color shapeColor;
	
	public GUIEntity(GameScreen screen, GUI gui, Vector2 screenPos) {
		this.screen = screen;
		this.gui = gui;
		this.screenPos = screenPos;
	}
	
	public void tick(float delta) {
		
	}
	
	public void render2D(SpriteBatch batch, float delta) {
		
	}
	
	public void onTouch(float delta) {
		
	}
	
//	public void destroy() {
//		
//	}
}
