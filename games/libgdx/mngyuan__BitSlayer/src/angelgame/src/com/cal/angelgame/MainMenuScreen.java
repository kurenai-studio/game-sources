package com.cal.angelgame;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.GL10;
import com.badlogic.gdx.graphics.GLCommon;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;

public class MainMenuScreen implements Screen {
	/**
	 * Screen with update and draw functions for
	 * the main menu. Passes control to other Screens.
	 */
	Game game;
	
	OrthographicCamera guiCam;
	SpriteBatch batcher;
	Rectangle soundButtonBounds;
	Rectangle playButtonBounds;
	
	Vector3 touchPoint;
	
	long lastTime = System.nanoTime();
	
	public MainMenuScreen(Game game) {
		this.game = game;
		
		guiCam = new OrthographicCamera(AngelGame.SCREEN_WIDTH, AngelGame.SCREEN_HEIGHT);
		guiCam.position.set( AngelGame.SCREEN_WIDTH / 2, AngelGame.SCREEN_HEIGHT, 0);
		batcher = new SpriteBatch();
		
		soundButtonBounds = new Rectangle(0, 0, 64, 64);
		playButtonBounds = new Rectangle(AngelGame.SCREEN_WIDTH / 2 - 50, AngelGame.SCREEN_HEIGHT / 2 + 100, 100, 50);
		
		touchPoint = new Vector3();
	}
	
	public void update (float deltaTime) {
		/**
		 * MainMenu main loop, called with deltaTime being the time
		 * in seconds since the last call of update()
		 */
		if (Gdx.input.isTouched()) {
			// convert from projected camera coords to screen coords
			guiCam.unproject(touchPoint.set(Gdx.input.getX(), Gdx.input.getY(), 0));
			
			if (OverlapTester.pointInRectangle(playButtonBounds, touchPoint.x, touchPoint.y)) {
				Assets.playSound(Assets.tapSound);
				// pass game on to battle screen and stop updating main menu
				game.setScreen(new BattleScreen(game));
				return;
			}
			if (OverlapTester.pointInRectangle(soundButtonBounds, touchPoint.x, touchPoint.y)) {
				Assets.playSound(Assets.tapSound);
				Settings.soundEnabled = !Settings.soundEnabled;
				if (Settings.soundEnabled)
					Assets.bgMusic.play();
				else
					Assets.bgMusic.pause();
				return;
			}
		}
	}
	
	public void draw (float deltaTime) {
		GLCommon gl = Gdx.gl;
		gl.glClearColor(0,  0, 0, 0);
		gl.glClear(GL10.GL_COLOR_BUFFER_BIT);
		guiCam.update();
		batcher.setProjectionMatrix(guiCam.combined);
		
		batcher.disableBlending();
		batcher.begin();
		batcher.draw(Assets.background, 0, AngelGame.SCREEN_HEIGHT/2, AngelGame.SCREEN_WIDTH, AngelGame.SCREEN_HEIGHT);
		batcher.end();
		
		batcher.enableBlending();
		batcher.begin();
		batcher.draw(Assets.logo, (AngelGame.SCREEN_WIDTH - Assets.logo.getWidth())/ 2.0f, AngelGame.SCREEN_HEIGHT / 2.0f + Assets.logo.getHeight() - 100);
		batcher.draw(Assets.start, (AngelGame.SCREEN_WIDTH - Assets.start.getWidth())/ 2, AngelGame.SCREEN_HEIGHT / 2);
		// we removed the mute button functionality
		// batcher.draw(Settings.soundEnabled ? Assets.soundOn : Assets.soundOff, 0, 0, 64, 64);
		batcher.end();
		
		if (System.nanoTime() - lastTime > 2000000000) {
			// incomplete debug lag logging
			Gdx.app.log("BitSlayer", ", memory: " + Gdx.app.getJavaHeap() + ", " + Gdx.app.getNativeHeap());
			
			lastTime = System.nanoTime();
		}
	}

	@Override
	public void render(float delta) {
		/**
		 * This is the actual function called once per frame
		 * by libgdx. It in turn calls our defined draw and update
		 * functions.
		 */
		update(delta);
		draw(delta);
	}

	@Override
	public void resize(int width, int height) {
	}

	@Override
	public void show() {
	}

	@Override
	public void hide() {
	}

	@Override
	public void pause() {
		// libgdx example perform a Settings.save() here.
		// why do we want to do file io everytime we pause?
		// fuck. that. shit.
	}

	@Override
	public void resume() {
	}

	@Override
	public void dispose() {
	}

}
