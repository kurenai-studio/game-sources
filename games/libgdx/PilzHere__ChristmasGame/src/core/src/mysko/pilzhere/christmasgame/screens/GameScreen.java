package mysko.pilzhere.christmasgame.screens;

import java.util.Comparator;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.Application.ApplicationType;
import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g3d.ModelBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType;
import com.badlogic.gdx.math.Intersector;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.math.collision.Ray;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.Viewport;

import mysko.pilzhere.christmasgame.ChristmasGame;
import mysko.pilzhere.christmasgame.Utils;
import mysko.pilzhere.christmasgame.audio.Audio;
import mysko.pilzhere.christmasgame.entities.Entity;
import mysko.pilzhere.christmasgame.entities.Island;
import mysko.pilzhere.christmasgame.entities.Player;
import mysko.pilzhere.christmasgame.entities.PlayerTerrain;
import mysko.pilzhere.christmasgame.entities.Seawave;
import mysko.pilzhere.christmasgame.entities.Slade;
import mysko.pilzhere.christmasgame.entities.Tree;
import mysko.pilzhere.christmasgame.entities.enemies.Shark;
import mysko.pilzhere.christmasgame.entities.enemies.Yeti;
import mysko.pilzhere.christmasgame.entities.items.Candycane;
import mysko.pilzhere.christmasgame.gui.GUI;
import mysko.pilzhere.christmasgame.gui.GUIEntity;

public class GameScreen implements Screen {
	public final ChristmasGame game;

	private boolean debugRenderShapes;

	public final AssetManager assMan;
	private final SpriteBatch batch;
	private final ModelBatch mdlBatch;
	public final Audio audio;

	private ShapeRenderer shapeRenderer;

	public OrthographicCamera cam;
	public Viewport viewport;

	private final GUI gui;

	public Array<Entity> entities = new Array<Entity>();
	private Island island;

	private Player player;

	public Shark shark; // getset

	public boolean gameIsPaused;

	public void setPlayer(Player player) {
		this.player = player;
	}

	public Player getPlayer() {
		return player;
	}

	public boolean playerWon; // get-set

	private final Vector3 nw = new Vector3(-75, 0, 75);
	private final Vector3 n = new Vector3(0, 0, 75);
	private final Vector3 ne = new Vector3(75, 0, 75);
	private final Vector3 e = new Vector3(75, 0, 0);
	private final Vector3 se = new Vector3(75, 0, -75);
	private final Vector3 s = new Vector3(0, 0, -75);
	private final Vector3 sw = new Vector3(-75, 0, -75);
	private final Vector3 w = new Vector3(-75, 0, 0);

	Array<Vector3> sharkSpawnPositions = new Array<Vector3>();

	public Vector3 getClosestSharkSpawnPoint() {
		sharkSpawnPositions.add(nw);
		sharkSpawnPositions.add(n);
		sharkSpawnPositions.add(ne);
		sharkSpawnPositions.add(e);
		sharkSpawnPositions.add(se);
		sharkSpawnPositions.add(s);
		sharkSpawnPositions.add(sw);
		sharkSpawnPositions.add(w);

		float closestDist = 100;
		Vector3 closestPos = new Vector3();
		for (Vector3 vector3 : sharkSpawnPositions) {
			float currentDist = Vector3.dst(player.position.x, player.position.y, player.position.z, vector3.x,
					vector3.y, vector3.z);
			if (currentDist < closestDist) {
				closestDist = currentDist;
				closestPos.set(vector3.cpy());
			}
		}

		sharkSpawnPositions.clear();

		return closestPos.cpy();
	}

	public GameScreen(ChristmasGame game) {
		this.game = game;
		this.assMan = game.getAssMan();
		this.batch = game.getBatch();
		this.mdlBatch = game.getMdlBatch();
		this.audio = game.getAudio();

		cam = new OrthographicCamera(Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
		cam.near = 0.01f;
		cam.far = 300f;
		cam.position.set(0, 100, 175);
		cam.lookAt(Vector3.Zero);
		if (Gdx.app.getType() == ApplicationType.WebGL)
			cam.zoom = 0.125f;
		else
			cam.zoom = 0.5f;
		cam.update();

		viewport = new FitViewport(Gdx.graphics.getWidth() / game.getWindowScale(),
				Gdx.graphics.getHeight() / game.getWindowScale(), cam);

		Utils.setViewport(viewport); // Never forget...

		game.setWindowScale(4);
		resizeWindow();

		island = new Island(this, Vector3.Zero);

		this.gui = new GUI(this);

		entities.clear();

		final Vector3 randomPosVector = new Vector3();

		for (int i = 0; i < 100; i++) {
			entities.add(new Tree(this, new Vector3(MathUtils.random(-35, 35), 0, MathUtils.random(-35, 35))));

			float randomDist = 0f;
			while (randomDist < 60) {
				randomPosVector.set(getRandom(), 0, getRandom());
				randomDist = randomPosVector.dst(Vector3.Zero);
			}

			entities.add(new Seawave(this, new Vector3(randomPosVector.x, 0, randomPosVector.z)));
		}

		final int randYetiAmount = MathUtils.random(5, 10);
		for (int i = 0; i < randYetiAmount; i++) {
			Vector3 yetiSpawn = new Vector3(MathUtils.random(-35, 35), 0, MathUtils.random(-35, 35));
			entities.add(new Yeti(this, yetiSpawn.cpy()));
		}
	}

	public void newGame() {
		entities.clear();
		player = null;

		playerWon = false;
		gameIsPaused = false;
		gui.showMenu = false;

		shark = null;

		final Vector3 randomPosVector = new Vector3();

		for (int i = 0; i < 100; i++) {
			entities.add(new Tree(this, new Vector3(MathUtils.random(-35, 35), 0, MathUtils.random(-35, 35))));

			float randomDist = 0f;
			while (randomDist < 60) {
				randomPosVector.set(getRandom(), 0, getRandom());
				randomDist = randomPosVector.dst(Vector3.Zero);
			}

			entities.add(new Seawave(this, new Vector3(randomPosVector.x, 0, randomPosVector.z)));
		}

		Slade slade;
		entities.add(
				slade = new Slade(this, new Vector3(MathUtils.random(-100, 100), 50, MathUtils.random(-100, 100))));

		final int randYetiAmount = MathUtils.random(7, 14);
		for (int i = 0; i < randYetiAmount; i++) {
			Vector3 yetiSpawn = new Vector3(MathUtils.random(-35, 35), 0, MathUtils.random(-35, 35));

			float distFromPlayer;
			distFromPlayer = Vector3.dst(yetiSpawn.x, 0, yetiSpawn.z, slade.targetPos.x, 0, slade.targetPos.z);

			while (distFromPlayer < 15.1f) {
				yetiSpawn.set(MathUtils.random(-35, 35), 0, MathUtils.random(-35, 35));
				distFromPlayer = Vector3.dst(yetiSpawn.x, 0, yetiSpawn.z, slade.targetPos.x, 0, slade.targetPos.z);
			}

			entities.add(new Yeti(this, yetiSpawn.cpy()));
		}

		for (int i = 0; i < randYetiAmount / 2; i++) {
			entities.add(new Candycane(this, new Vector3(MathUtils.random(-40, 40), 0, MathUtils.random(-40, 40))));
		}
	}

	private float getRandom() {
		final float random = MathUtils.random(-80, 80);
		return random;
	}

	public Island getIsland() {
		return island;
	}

	@Override
	public void show() {

	}

	private boolean lmbPressed;
	private boolean rmbPressed;
	private Rectangle touchRect = new Rectangle(0, 0, 5, 5);
	private Ray ray;

	private final Vector3 mousePos3D = new Vector3();
	private final Vector3 mousePos3DUnprojected = new Vector3();
	private final Vector2 mousePos2D = new Vector2();

	private void input(float delta) {
		mousePos3D.x = Gdx.input.getX();
		mousePos3D.y = Gdx.input.getY();
		mousePos3D.z = 0;
		mousePos3DUnprojected.set(mousePos3D.cpy());
		cam.unproject(mousePos3D.cpy());
		mousePos2D.x = mousePos3D.x;
		mousePos2D.y = mousePos3D.y;

		if (Gdx.input.isKeyJustPressed(Input.Keys.PLUS)) {
			game.setWindowScale(game.getWindowScale() + game.stdWindowScaleIncrement);
			resizeWindow();
//			cam.zoom += 0.125f; // TEST
		}

		if (Gdx.input.isKeyJustPressed(Input.Keys.MINUS)) {
			game.setWindowScale(game.getWindowScale() - game.stdWindowScaleIncrement);
			resizeWindow();
//			cam.zoom -= 0.125f; // TEST
		}

		if (Gdx.input.isKeyJustPressed(Input.Keys.F1)) {
			debugRenderShapes = !debugRenderShapes;
		}

		if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
			if (gui.showMenu)
				Gdx.app.exit();
			else
				gameIsPaused = true;
			gui.showMenu = true;
		}

//		if (Gdx.input.isKeyJustPressed(Input.Keys.R)) {
//			camSpin = !camSpin;
//		}

		if (!gui.showMenu && player != null && !gameIsPaused) {
			// TODO: If player is too far from middle = moves out while moving.
			// Temporary solution is slower island rotation speed.
			if (Gdx.input.isKeyPressed(Input.Keys.A)) {
				player.moveLeft(delta);
			}

			if (Gdx.input.isKeyPressed(Input.Keys.D)) {
				player.moveRight(delta);
			}

			if (Gdx.input.isKeyPressed(Input.Keys.W)) {
				player.moveUp(delta);
			}

			if (Gdx.input.isKeyPressed(Input.Keys.S)) {
				player.moveDown(delta);
			}

			if (Gdx.input.isKeyJustPressed(Input.Keys.E)) {
				if (!player.isChopping && player.action != PlayerTerrain.SWIMMING) {
					player.chop(delta);

					switch (player.spriteDir) {
					case UP:						
						touchRect.setWidth(8f / 2 * player.sprite.getScaleX());
						touchRect.setHeight(48f / 2 * player.sprite.getScaleY());
						
						touchRect.setX(player.sprite.getX() + player.sprite.getWidth() / 2);
						touchRect.setY(player.sprite.getY() + player.sprite.getHeight() * 0.75f);
						break;
					case DOWN:						
						touchRect.setWidth(8f / 2 * player.sprite.getScaleX());
						touchRect.setHeight(48f / 2 * player.sprite.getScaleY());
						
						touchRect.setX(player.sprite.getX() + player.sprite.getWidth() / 2);
						touchRect.setY(player.sprite.getY() - player.sprite.getHeight() * 0.25f);
						
						break;
					case LEFT:						
						touchRect.setWidth(48f / 2 * player.sprite.getScaleX());
						touchRect.setHeight(8f / 2 * player.sprite.getScaleY());
						
						touchRect.setX(player.sprite.getX() - player.sprite.getWidth() / 3);
						touchRect.setY(player.sprite.getY() + player.sprite.getHeight() / 2);
						break;
					case RIGHT:						
						touchRect.setWidth(48f / 2 * player.sprite.getScaleX());
						touchRect.setHeight(8f / 2 * player.sprite.getScaleY());
						
						touchRect.setX(player.sprite.getX() + player.sprite.getWidth());
						touchRect.setY(player.sprite.getY() + player.sprite.getHeight() / 2);
						break;
					}

					for (Entity ent : entities) {
						if (ent.choppable) {
							if (ent.rect != null) {
								if (touchRect.overlaps(ent.rect)) {
									ent.onChop(delta);
									break; // Can only touch one object at a time.
								}
							}
						}
					}
				}
			}
		} else {
			if (Gdx.input.isKeyJustPressed(Input.Keys.ENTER)) {
				System.err.println("WAT1");
				gui.showMenu = false;
				if (!gameIsPaused) {
					System.err.println("WAT2");
					newGame();
				} else {
					System.err.println("WAT3");
					if (playerWon) {
						System.err.println("WAT4");
						newGame();
					} else {
						System.err.println("WAT5");
						gameIsPaused = !gameIsPaused;
					}
				}
			}

			leftMouseButton(delta);
			rightMouseButton(delta);
		}
	}

	public void gameOver() {
		setPlayer(null);
		gui.showMenu = true;
	}

	private void leftMouseButton(float delta) {
		if (!Gdx.input.isButtonPressed(Input.Buttons.LEFT)) {
			lmbPressed = false;
		}

		if (Gdx.input.isButtonPressed(Input.Buttons.LEFT)) {
			if (!lmbPressed) {
				if (Gdx.input.justTouched()) {
					touchRect.setWidth(5);
					touchRect.setHeight(5);
					touchRect.setPosition(mousePos2D.x - touchRect.getWidth() / 2,
							(Gdx.graphics.getHeight() - mousePos3DUnprojected.y) - (touchRect.getHeight() / 2));

					boolean contin = true;
					if (contin) {
						for (GUIEntity guiEnt : gui.guiEnts) {
							if (guiEnt.rect != null) {
								if (touchRect.overlaps(guiEnt.rect)) {
									guiEnt.onTouch(delta);
									contin = false;
									break; // Can only touch one object at a time.
								}
							}
						}
					}

					if (contin) {
						for (Entity ent : entities) {
							if (ent.rect != null) {
								if (touchRect.overlaps(ent.rect)) {
									ent.onTouch(delta);
									contin = false;
									break; // Can only touch one object at a time.
								}
							}
						}
					}

					lmbPressed = true;
				}
			}
		}
	}

	private void rightMouseButton(float delta) {
		if (!Gdx.input.isButtonPressed(Input.Buttons.RIGHT)) {
			rmbPressed = false;
		}

		if (Gdx.input.isButtonPressed(Input.Buttons.RIGHT)) {
			if (!rmbPressed) {
				if (Gdx.input.justTouched()) {
					ray = cam.getPickRay(mousePos2D.x, mousePos2D.y);

					placeEntityOnCursor();

					rmbPressed = true;
				}
			}
		}
	}

	private final Vector3 placePos = new Vector3();

	private void placeEntityOnCursor() {
		if (Intersector.intersectRayBoundsFast(ray, island.bb)) {
			float distance = -ray.origin.y / ray.direction.y;

			placePos.set(ray.direction).scl(distance).add(ray.origin);

//			entities.add(new Candycane(this, placePos.cpy()));
		}
	}

	private final int camRotSpeed = 3; // 25

	private void tick(float delta) {
		if (playerWon) {
			gui.showMenu = true;
			gameIsPaused = true;
		}

		rotateCamAroundIsland(cam, camRotSpeed * delta);
		cam.lookAt(Vector3.Zero);
		cam.update();

		island.tick(delta);

		if (player != null)
			player.checkForOverlaps(delta);

		for (Entity ent : entities) {
			if (ent.destroy) {
				ent.destroy();
				entities.removeValue(ent, true);
			}
		}

		for (Entity ent : entities) {
			ent.tick(delta);
		}

		entities.sort(comparatorRenderOrder);

		gui.tick(delta);
	}

	private boolean camSpin = true;

	private void rotateCamAroundIsland(OrthographicCamera cam, float speed) {
		if (camSpin)
			cam.rotateAround(Vector3.Zero, Vector3.Y, speed);
	}

//	Sorts render order!
	Comparator<Entity> comparatorRenderOrder = new Comparator<Entity>() {
		@Override
		public int compare(Entity ent1, Entity ent2) {
			if (ent1.distFromCam > ent2.distFromCam) {
				return -1;
			} else if (ent1.distFromCam < ent2.distFromCam) {
				return 1;
			} else {
				return 0;
			}
		}
	};

	private void resizeWindow() {
		Gdx.graphics.setWindowedMode((int) (game.stdWindowWidth * game.getWindowScale()),
				(int) (game.stdWindowHeight * game.getWindowScale()));
	}

	@Override
	public void render(float delta) {
		input(delta);
		tick(delta);

		mdlBatch.begin(cam);
		island.render3D(mdlBatch, delta);
		mdlBatch.end();

		batch.setProjectionMatrix(cam.projection.setToOrtho2D(0, 0, Gdx.graphics.getWidth(), Gdx.graphics.getHeight()));

		batch.begin();
		for (Entity ent : entities) {
			ent.render2D(batch, delta);
		}

		if (debugRenderShapes) {
			if (shapeRenderer == null)
				shapeRenderer = new ShapeRenderer();

			shapeRenderer.setProjectionMatrix(batch.getProjectionMatrix());

			shapeRenderer.setColor(Color.BLACK);
			shapeRenderer.begin(ShapeType.Filled);
			shapeRenderer.rect(touchRect.x, touchRect.y, touchRect.getWidth(), touchRect.getHeight());

			for (Entity ent : entities) {
				if (ent.rect != null) {
					if (ent.shapeColor != null)
						shapeRenderer.setColor(ent.shapeColor);
					shapeRenderer.rect(ent.rect.getX(), ent.rect.getY(), ent.rect.getWidth(), ent.rect.getHeight());
				}
			}

		}

		gui.render2D(delta);

		if (debugRenderShapes) {
			for (GUIEntity guiEnt : gui.guiEnts) {
				if (guiEnt.rect != null) {
					if (guiEnt.shapeColor != null)
						shapeRenderer.setColor(guiEnt.shapeColor);
					shapeRenderer.rect(guiEnt.rect.getX(), guiEnt.rect.getY(), guiEnt.rect.getWidth(),
							guiEnt.rect.getHeight());
				}
			}
			shapeRenderer.setColor(Color.WHITE);
			shapeRenderer.end();
		}

		batch.end();
	}

	@Override
	public void resize(int width, int height) {
		viewport.update(Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
		cam.update();
	}

	@Override
	public void pause() {

	}

	@Override
	public void resume() {

	}

	@Override
	public void hide() {

	}

	@Override
	public void dispose() {
		entities.clear();
		gui.destroy();

		island.dispose();
	}
}
