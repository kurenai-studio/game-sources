package com.mygdx.game;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ScreenUtils;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.utils.TimeUtils;
import java.util.Iterator;

public class BakeTheBread extends ApplicationAdapter {
	private Texture BakeTheBreadLogo, menuButton, menuButtonPressed, quitButtonPressed, playButtonPressed, playButton, quitButton, breadImage, bucketImage, bucketImageSemiFull, bucketImageSemiFull2, bucketImageFull, match, backgroundTexture;
	private Sprite backgroundSprite;
	private Sound bucketSound, liveSound, oven, liveLostSound, matchSound;
	private Music backgroundMusic, fire;
	private OrthographicCamera camera;
	private SpriteBatch batch;
	private Rectangle bucket;
	private Array<Rectangle> raindrops, lives, planes;
	private long lastDropTime, lastDropTimeLive;
	private BitmapFont font;
	private int liveCounter = 3, breadCounter = 0, backgroundCounter = 0, randomBackground, bucketCounter = 0, levelCounter = 0;
	private double acceleration = 0.45, velocity = 6, xAcceleration = 0, friction = 0.025, breadVelocity = 2;
	private String[] BucketSound = {"bucketSound", "bucketSound2", "bucketSound3"};
	private Boolean matchBoolean = false, paused = false, menu = true;
	private AssetManager assetManager;
	@Override
	public void create () {
		font = new BitmapFont();
		playButtonPressed = new Texture(Gdx.files.internal("playbuttonpressed.png"));
		menuButtonPressed = new Texture(Gdx.files.internal("menubuttonpressed.png"));
		menuButton = new Texture(Gdx.files.internal("menubutton.png"));
		quitButtonPressed = new Texture(Gdx.files.internal("quitbuttonpressed.png"));
		breadImage = new Texture(Gdx.files.internal("bread.png"));
		bucketImage = new Texture(Gdx.files.internal("bucket.png"));
		BakeTheBreadLogo = new Texture(Gdx.files.internal("bakethebread.png"));
		playButton = new Texture(Gdx.files.internal("playbutton.png"));
		quitButton = new Texture(Gdx.files.internal("quitbutton.png"));
		bucketImageSemiFull = new Texture(Gdx.files.internal("bucketsemifull.png"));
		bucketImageSemiFull2 = new Texture(Gdx.files.internal("bucketsemifull2.png"));
		bucketImageFull = new Texture(Gdx.files.internal("bucketfull.png"));
		match = new Texture(Gdx.files.internal("match.png"));
		backgroundMusic = Gdx.audio.newMusic(Gdx.files.internal("backgroundMusic.mp3"));
		fire = Gdx.audio.newMusic(Gdx.files.internal("fire.mp3"));
		oven = Gdx.audio.newSound(Gdx.files.internal("oven.mp3"));
		liveSound = Gdx.audio.newSound(Gdx.files.internal("live.mp3"));
		matchSound = Gdx.audio.newSound(Gdx.files.internal("matchSound.mp3"));
		liveLostSound = Gdx.audio.newSound(Gdx.files.internal("liveLost.mp3"));
		randomBackground = MathUtils.random(1, 4);
		backgroundTexture = new Texture(Gdx.files.internal("background" + randomBackground + ".png"));
		backgroundSprite = new Sprite(backgroundTexture);

		camera = new OrthographicCamera();
		camera.setToOrtho(false, 800, 480);
		batch = new SpriteBatch();
		bucket = new Rectangle();
		bucket.x = 800 / 2 - 64 / 2;
		bucket.y = 23;
		bucket.width = 64;
		bucket.height = 64;
	}

	private void spawnBread() {
		Rectangle raindrop = new Rectangle();
		raindrop.x = MathUtils.random(0, 500);
		raindrop.y = 480;
		raindrop.width = 64;
		raindrop.height = 64;
		raindrops.add(raindrop);
		lastDropTime = TimeUtils.nanoTime();
	}


	private void renderBackground() {
		backgroundSprite.draw(batch);
	}


	private void fallingLives(){
		//Builds the array based on a probability of 0.05%
		int probability = (int) (10000 * Math.random());
		System.out.println(probability);
		Rectangle live = new Rectangle();
		if (probability <= 5){
			live.x = MathUtils.random(0, 500);
			live.y = 480;
			live.width = 64;
			live.height = 64;
			lives.add(live);
			lastDropTimeLive = TimeUtils.nanoTime();
		}
	}
	public void menuScreen(){
		//The menu screen creates the arrays with the objects and allows you to start a new game
		backgroundCounter++;
		fire.setLooping(true);
		fire.setVolume(0.5f);
		fire.play();
		setBackground();
		batch.setProjectionMatrix(camera.combined);
		batch.begin();
		renderBackground();
		batch.draw(BakeTheBreadLogo, 0, 200);
		batch.draw(playButton, 300, 240);
		batch.draw(quitButton, 300, 120);
		if (Gdx.input.getX() > 300 && Gdx.input.getX() < 500 && Gdx.input.getY() < 240 && Gdx.input.getY() > 130){
			batch.draw(playButtonPressed, 300, 240);
			if (Gdx.input.isButtonPressed(Input.Buttons.LEFT)){
				backgroundMusic.setLooping(true);
				backgroundMusic.play();
				raindrops = new Array<>();
				spawnBread();
				lives = new Array<>();
				fallingLives();
				menu = false;
			}
		}

		if (Gdx.input.getX() > 300 && Gdx.input.getX() < 500 && Gdx.input.getY() < 350 && Gdx.input.getY() > 250){
			batch.draw(quitButtonPressed, 300, 120);
			if (Gdx.input.isButtonPressed(Input.Buttons.LEFT)) {
				Gdx.app.exit();
			}
		}
		batch.end();
	}


	@Override

	public void render() {
		//Initialize different game screens
		menuScreen();
		if (!menu){
			gameScreen();
		}

	}

	public void killPlayer(){
		//Reset all variables and create every object
		menu = true;
		liveCounter = 3;
		breadCounter = 0;
		backgroundCounter = 0;
		bucketCounter = 0;
		levelCounter = 0;
		acceleration = 0.45;
		velocity = 6;
		xAcceleration = 0;
		breadVelocity = 2;
		matchBoolean = false;
		backgroundMusic.stop();
		fire.stop();
		batch = new SpriteBatch();
		create();
	}

	public void gameScreen () {
		//In paused it uses the same scene but there is no movement, that's why I divided the code in setScene() and gameScreen()
		if (!paused) {
			setScene();
			batch.end();

			if (Gdx.input.isKeyPressed(Input.Keys.LEFT) && !Gdx.input.isKeyPressed(Input.Keys.RIGHT))
				xAcceleration = -acceleration;
			if (Gdx.input.isKeyPressed(Input.Keys.RIGHT) && !Gdx.input.isKeyPressed(Input.Keys.LEFT))
				xAcceleration = acceleration;
			if (!Gdx.input.isKeyPressed(Input.Keys.RIGHT) && !Gdx.input.isKeyPressed(Input.Keys.LEFT)) {
				if (velocity > 0) {
					xAcceleration = -0.02;
				} else if (velocity < 0) {
					xAcceleration = +0.02;
				}
			}
			velocity += xAcceleration;
			velocity *= 1 - friction;
			bucket.x += velocity;

			if (bucket.x < 0) bucket.x = 0;
			if (bucket.x > 645) bucket.x = 645;

			if (TimeUtils.nanoTime() - lastDropTime > 1900000000) spawnBread();
			if (TimeUtils.nanoTime() - lastDropTimeLive > 1000000000) fallingLives();


			for (Iterator<Rectangle> iter = raindrops.iterator(); iter.hasNext(); ) {
				Rectangle raindrop = iter.next();
				raindrop.y -= breadVelocity;
				if (raindrop.y - 20 < 0) {
					iter.remove();
					liveLostSound.play();
					liveCounter -= 1;
					if (liveCounter == 0) {
						killPlayer();
					}
				}if (raindrop.overlaps(bucket)) {
					if (bucketCounter < 10) {
						bucketSound.play();
						bucketCounter++;
						iter.remove();
					} else {
						killPlayer();
					}
				}
			}

			for (Iterator<Rectangle> iter = lives.iterator(); iter.hasNext(); ) {
				Rectangle live = iter.next();
				live.y -= breadVelocity;
				if (live.y - 20 < 0) {
					iter.remove();
				}if (live.overlaps(bucket)) {
					if (!matchBoolean) {
						matchBoolean = true;
					}
					bucketSound.play();
					iter.remove();
				}
			}
			if (bucket.x == 645) {
				if (matchBoolean && Gdx.input.isKeyPressed(Input.Keys.E) && liveCounter < 3) {
					liveSound.play();
					matchSound.play();
					matchBoolean = false;
					liveCounter++;
				}
			}
			if (bucket.x == 645 && bucketCounter > 0) {
				breadCounter += bucketCounter;
				levelCounter += bucketCounter;
				bucketCounter = 0;
				oven.play();
			}

			if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) paused = true;

		}else if (paused && !menu){
			setScene();
			font.draw(batch, "GAME PAUSED", 320, 240);
			batch.end();
			if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) paused = false;
		}
	}

	private void setScene() {
		setBackground();
		if (levelCounter >= 5 && breadVelocity < 7) {
			levelCounter = 5 - levelCounter;
			breadVelocity += 0.25;
		}
		bucketSound = Gdx.audio.newSound(Gdx.files.internal(BucketSound[MathUtils.random(0, 2)] + ".mp3"));
		ScreenUtils.clear(0, 0, 0.2f, 1);
		batch.setProjectionMatrix(camera.combined);
		batch.begin();

		backgroundCounter++;
		renderBackground();
		for (Rectangle raindrop : raindrops) {
			batch.draw(breadImage, raindrop.x, raindrop.y);
		}
		for (Rectangle live : lives) {
			batch.draw(match, live.x, live.y);
		}

		batch.draw(breadImage, 460, 420);
		if (matchBoolean) {
			batch.draw(match, 460, 360);
		}
		font.draw(batch, Integer.toString(breadCounter), 550, 440);
		if (bucketCounter == 0) {
			batch.draw(bucketImage, bucket.x, bucket.y);
		} else if (bucketCounter > 0 && bucketCounter < 5) {
			batch.draw(bucketImageSemiFull, bucket.x, bucket.y);
		} else if (bucketCounter > 4 && bucketCounter < 10) {
			batch.draw(bucketImageSemiFull2, bucket.x, bucket.y);
		} else {
			batch.draw(bucketImageFull, bucket.x, bucket.y);
		}

		if (bucket.x == 645 && matchBoolean) font.draw(batch, "Press 'E' to ignite", 320, 50);

		if (bucketCounter < 10) {
			font.setColor(1, 1, 1, 1);
			font.draw(batch, Integer.toString(bucketCounter), bucket.x + 28, bucket.y + 20);
		}else{
			font.setColor(1, 0, 0, 1);
			font.draw(batch, Integer.toString(bucketCounter), bucket.x + 25, bucket.y + 20);
		}
	}

	private void setBackground() {
		//Background update depending on the flames (lives) left
		if (backgroundCounter > 6) {
			if (liveCounter == 3) {
				randomBackground = MathUtils.random(1, 4);
				backgroundCounter = 0;
				backgroundTexture = new Texture(Gdx.files.internal("background" + randomBackground + ".png"));
				backgroundSprite = new Sprite(backgroundTexture);
			} else if (liveCounter == 2) {
				randomBackground = MathUtils.random(1, 3);
				backgroundCounter = 0;
				backgroundTexture = new Texture(Gdx.files.internal("twolives" + randomBackground + ".png"));
				backgroundSprite = new Sprite(backgroundTexture);
			} else {
				randomBackground = MathUtils.random(1, 2);
				backgroundCounter = 0;
				backgroundTexture = new Texture(Gdx.files.internal("onelive" + randomBackground + ".png"));
				backgroundSprite = new Sprite(backgroundTexture);
			}
		}
	}


	@Override
	public void dispose () {
		assetManager.dispose();
	}
}
