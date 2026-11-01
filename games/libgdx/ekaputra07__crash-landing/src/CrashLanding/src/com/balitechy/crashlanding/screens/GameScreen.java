package com.balitechy.crashlanding.screens;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL10;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.Texture.TextureFilter;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.InputListener;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.utils.Align;
import com.balitechy.crashlanding.CrashLanding;
import com.balitechy.crashlanding.GameAudio;
import com.balitechy.crashlanding.GameUtils;
import com.balitechy.crashlanding.models.Accelerator;
import com.balitechy.crashlanding.models.FuelMeter;
import com.balitechy.crashlanding.models.LandingPad;
import com.balitechy.crashlanding.models.SpaceShip;

public class GameScreen implements Screen{
	
	private Game game;
	private LandingPad landingpad;
	private SpaceShip ship;
	private SpriteBatch batch;
	private Texture background;
	private ShapeRenderer sr;
	private OrthographicCamera cam;
	private Stage stageActive, stagePasive;
	private FuelMeter fuel;
	private Accelerator accel;
	private static float WORLD_HEIGHT = 1500;
	
	private Label labelFuel;
	
	float screenWidth, screenHeight;
	
	public GameScreen(Game game){
		this.game = game;
	}
	
	public SpaceShip getShip() {
		return ship;
	}

	public LandingPad getLandingpad() {
		return landingpad;
	}
	
	public void restartGame(){
		game.setScreen(new GameScreen(game));
	}

	public Game getGame() {
		return game;
	}

	@Override
	public void render(float delta) {
		//--------------- Draw Screen  ---------------------//
		stageActive.act(delta);
		stagePasive.act(delta);
		
		Gdx.gl.glClearColor(0, 0, 0, 1);
		Gdx.gl.glClear(GL10.GL_COLOR_BUFFER_BIT);

		if(ship.getPosition().y > 1200){
			cam.position.set(screenWidth/2, 1200, 0);
			cam.update();
		}else{
			if(cam.position.y >= screenHeight/2){
				cam.position.set(screenWidth/2, ship.getPosition().y, 0);
				cam.update();
			}
		}
		
		batch.setProjectionMatrix(cam.combined);
		batch.begin();
		//draw Stage
		stageActive.draw();
		stagePasive.draw();
		batch.end();
		
		//In DEBUG mode show objects bounds
		if(CrashLanding.DEBUG){
			sr.begin(ShapeType.Line);
			
			//Draw landingpad bounds area
			sr.setColor(Color.RED);
			sr.rect(landingpad.getBounds().x, landingpad.getBounds().y, landingpad.getBounds().width, landingpad.getBounds().height);
			//Draw ship bounds area
			sr.setColor(Color.CYAN);
			sr.rect(ship.getBounds().x, ship.getBounds().y, ship.getBounds().width, ship.getBounds().height);
			sr.end();
		}
	}

	@Override
	public void resize(int width, int height) {
		
	}

	@Override
	public void show() {
		//Get screen info
		screenWidth = GameUtils.getScreenWidth();
		screenHeight = GameUtils.getScreenHeight();
		
		stageActive = new Stage(screenWidth, screenHeight, true);
		stagePasive = new Stage(screenWidth, screenHeight, true);
		
		batch = new SpriteBatch();
		
		cam = new OrthographicCamera(screenWidth, screenHeight);
		stageActive.setCamera(cam);
		
		//Create background
		final Texture bgImg = new Texture(Gdx.files.internal("data/background.png"));
		bgImg.setFilter(TextureFilter.Linear, TextureFilter.Linear);
		
		Actor background = new Actor() {
			@Override
			public void draw(Batch batch, float parentAlpha) {
				batch.draw(bgImg, 0, 0, screenWidth, WORLD_HEIGHT);
			}
		};
		
		//Create Landing pad object
		landingpad = new LandingPad(new Vector2(0, -10), screenWidth, LandingPad.HEIGHT);
		
		// Create Engine Accelerator
		accel = new Accelerator(new Vector2(screenWidth-Accelerator.WIDTH, 0), Accelerator.WIDTH, Accelerator.HEIGHT);
		accel.addListener(new InputListener(){

			@Override
			public boolean touchDown(InputEvent event, float x, float y,
					int pointer, int button) {

				if(!ship.isCrashed() && !ship.isLanding()){
					ship.setEngineState(SpaceShip.EngineState.ON);
					GameAudio.jet.play();
				}
				return true;
			}

			@Override
			public void touchUp(InputEvent event, float x, float y,
					int pointer, int button) {
				
					ship.setEngineState(SpaceShip.EngineState.OFF);
					GameAudio.jet.stop();
			}
		});
		
		//Create FuelMeter
		float fuelWidth = 80;
		float fuelHeight = 15;
		fuel = new FuelMeter(new Vector2(screenWidth-fuelWidth-10, screenHeight-fuelHeight-10), fuelWidth, fuelHeight);
		
		//Create Ship object
		ship = new SpaceShip(new Vector2(screenWidth/2-SpaceShip.WIDTH/2, WORLD_HEIGHT-SpaceShip.HEIGHT), SpaceShip.WIDTH, SpaceShip.HEIGHT);
		ship.setLandingPad(landingpad);
		ship.setFuelMeter(fuel);
		
		//Create top labels
		labelFuel = new Label("Fuel", GameUtils.labelStyle());
		labelFuel.setWidth(75);
		labelFuel.setFontScale(0.7f);
		labelFuel.setPosition(screenWidth-fuelWidth-labelFuel.getWidth(), screenHeight - labelFuel.getHeight());
		labelFuel.setAlignment(Align.left);
		
		//Create GameOver message
		GameResult gameover = new GameResult(game);
		
		Gdx.input.setInputProcessor(stagePasive);
		
		stageActive.addActor(background);
		stageActive.addActor(landingpad);
		stageActive.addActor(ship);
		
		stagePasive.addActor(accel);
		stagePasive.addActor(gameover);
		stagePasive.addActor(labelFuel);
		stagePasive.addActor(fuel);

		
		if(CrashLanding.DEBUG){
			sr = new ShapeRenderer();
		}
	}

	@Override
	public void hide() {
	}

	@Override
	public void pause() {
	}

	@Override
	public void resume() {
		
	}

	@Override
	public void dispose() {
		background.dispose();
		landingpad.dispose();
		ship.dispose();
		batch.dispose();
		fuel.dispose();
		stageActive.dispose();
		stagePasive.dispose();
		
		if(CrashLanding.DEBUG){
			sr.dispose();
		}
	}

}
