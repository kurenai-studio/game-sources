package mysko.pilzhere.christmasgame.entities;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g3d.ModelBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;

import mysko.pilzhere.christmasgame.screens.GameScreen;

public class Entity {
	protected final GameScreen screen;
	public boolean destroy;

	public final Vector3 position;
	public float distFromCam;
	public Rectangle rect;
	public int hp;
	public Color shapeColor;

	public boolean choppable = false; // get-set

	public Entity(GameScreen screen, Vector3 position) {
		this.screen = screen;
		this.position = position;
	}

	public void tick(float delta) {
		distFromCam = Vector3.dst(screen.cam.position.x, screen.cam.position.y, screen.cam.position.z, position.x,
				position.y, position.z);
	}

	public void render2D(SpriteBatch batch, float delta) {
	}

	public void render3D(ModelBatch batch, float delta) {
	}

	public void onTouch(float delta) {
	}

	public void onChop(float delta) {
	}

	public void destroy() {
	}
}
