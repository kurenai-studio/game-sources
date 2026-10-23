package com.mygdx.fourcats;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.utils.viewport.*;
import com.mygdx.fourcats.events.EventBroker;
import com.mygdx.fourcats.managers.CatManager;
import com.mygdx.fourcats.managers.CorpseManager;
import com.mygdx.fourcats.managers.SimpleMouseManager;
import com.mygdx.fourcats.managers.movement.MovementHandler;
import com.mygdx.fourcats.renderers.CatRenderer;
import com.mygdx.fourcats.renderers.CorpseRenderer;
import com.mygdx.fourcats.renderers.MouseRenderer;
import com.mygdx.fourcats.renderers.specialeffects.ISpecialEffectRenderer;
import com.mygdx.fourcats.renderers.specialeffects.SpecialEffectFactory;
import com.mygdx.fourcats.spawner.MouseSpawner;
import com.mygdx.fourcats.trackers.CaughtMiceTracker;
import com.mygdx.fourcats.trackers.CountdownTracker;

public class GameScreen implements Screen {

	FourCatsGame game;

	CatName selectedCat;
	MouseRenderer MouseRenderer;

	CatRenderer CatRenderer;

	ISpecialEffectRenderer specialEffectRenderer;

	MovementHandler movementHandler;

	CatManager catManager;

	SimpleMouseManager mouseManager;
	MouseSpawner mouseSpawner;

	CorpseManager corpseManager;

	MouseCaughtChecker caughtChecker;
	FitViewport gameViewport;
	ScreenViewport statsViewport;
	CaughtMiceTracker tracker;
	CharSequence str = "Score: ";

	Rectangle statsBackground;

	Rectangle gameBackground;

	CountdownTracker countdown;


	public GameScreen(FourCatsGame game, CatName catName)
	{
		this.game = game;
		this.selectedCat = catName;

		MouseRenderer = new MouseRenderer(game.batch);
		MouseRenderer.loadTextures();
		mouseManager = new SimpleMouseManager(0, MouseRenderer);
		EventBroker.getInstance().MouseSpawnListeners.add(mouseManager);
		EventBroker.getInstance().MouseCaughtListeners.add(mouseManager);



		Animal cat = new Animal(20, 20, Config.CAT_SIZE);
		movementHandler = MovementHandler.createHandlerForCat(cat, catName);
		CatRenderer = new CatRenderer(game.batch, catName);
		specialEffectRenderer = SpecialEffectFactory.getInstance().
				getSpecialEffectRendererByCatname(catName, game.shape, movementHandler.getSpecialEffectTrigger());


		catManager = new CatManager(cat,  catName, movementHandler,  CatRenderer, specialEffectRenderer);

		mouseSpawner = new MouseSpawner();

		CorpseRenderer corpseRenderer = new CorpseRenderer(game.batch);
		corpseRenderer.loadTextures();
		corpseManager = new CorpseManager(corpseRenderer);
		EventBroker.getInstance().MouseCaughtListeners.add(corpseManager);

		caughtChecker = new MouseCaughtChecker(catManager, mouseManager);
		countdown = new CountdownTracker();

		tracker = new CaughtMiceTracker();
		EventBroker.getInstance().MouseCaughtListeners.add(tracker);

		OrthographicCamera camera = new OrthographicCamera();
		gameViewport = new FitViewport(Config.WORLD_SIZE_X, Config.WORLD_SIZE_Y, camera);

		statsViewport = new ScreenViewport();

		statsBackground = new Rectangle();
		gameBackground = new Rectangle(0,0, Config.WORLD_SIZE_X, Config.WORLD_SIZE_Y);
	}

	@Override
	public void resize(int width, int height)
	{
		gameViewport.update(width, height);
		statsViewport.update(width, height);
		gameViewport.getCamera().position.set(Config.WORLD_SIZE_X / 2f, Config.WORLD_SIZE_Y / 2f , 0);
		gameViewport.getCamera().update();
	}

	@Override
	public void render (float delta) {
		catManager.updateMovement();
		mouseManager.updateMovement();
		corpseManager.updateMovement();
		mouseSpawner.update();
		caughtChecker.check();
		countdown.update();


		gameViewport.apply();
		Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

		game.shape.setProjectionMatrix(gameViewport.getCamera().combined);
		game.shape.begin(ShapeRenderer.ShapeType.Filled);
		game.shape.setColor(Color.GREEN);
		game.shape.rect(gameBackground.x, gameBackground.y, gameBackground.width, gameBackground.height);
		catManager.renderEffects();
		game.shape.end();


		game.batch.begin();
		game.batch.setProjectionMatrix(gameViewport.getCamera().combined);
		corpseManager.renderObjects();
		mouseManager.renderObjects();
		catManager.renderObjects();
		game.bigfont.draw(game.batch, str + Integer.toString(tracker.getScore()), Config.WORLD_SIZE_X * 0.1f, Config.WORLD_SIZE_Y * 0.95f);
		game.bigfont.draw(game.batch, Integer.toString(countdown.getCountdown()), Config.WORLD_SIZE_X * 0.7f, Config.WORLD_SIZE_Y * 0.95f);
		game.batch.end();

		checkCountdown();
	}

	private void checkCountdown()
	{
		if (countdown.getCountdown() == 0)
		{
			this.game.setScreen(new ResultScreen(this.game, selectedCat, tracker.getScore()));
			dispose();
		}
	}

	@Override
	public void show() {

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
	public void dispose()
	{
		EventBroker.getInstance().clearListeners();
	}
}