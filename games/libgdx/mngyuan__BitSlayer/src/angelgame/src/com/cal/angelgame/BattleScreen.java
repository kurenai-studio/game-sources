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
import com.cal.angelgame.Battlefield.BattlefieldEventHandler;
import com.cal.angelgame.enemy.Enemy;
import com.cal.angelgame.player.PlayerCharacter;
import com.cal.angelgame.skill.Skill;

public class BattleScreen implements Screen {
	/**
	 * Screen with draw and update functions for the 
	 * main gameplay mode.
	 * 
	 * Handles main game loop player input. See Battlefield
	 * for main game loop logic.
	 */
	// states
	static final int GAME_RUNNING = 0;
	static final int GAME_PAUSED = 1;
	static final int GAME_LEVEL_END = 2;
	static final int GAME_OVER = 3;

    long lastPause = 0;
    // time in seconds to disable pause button
    public static final float PAUSE_DELAY = 0.1f;
	
	boolean playerSelected = true; // only one guy
	// saves our butts and times
	
	Game game;
	
	int curState;
	OrthographicCamera guiCam;
	Vector3 touchPoint;
	SpriteBatch batcher;
	
	Battlefield battlefield;
	BattlefieldEventHandler handler;
	BattlefieldRenderer renderer;
	
	Rectangle pauseButtonBounds;
	
	public BattleScreen(Game game) {
		this.game = game;
		
		curState = GAME_RUNNING;
		// guiCam uses screen coords. It makes no sense to unproject guiCam..?
		guiCam = new OrthographicCamera(AngelGame.SCREEN_WIDTH, AngelGame.SCREEN_HEIGHT);
		guiCam.position.set(AngelGame.SCREEN_WIDTH / 2, AngelGame.SCREEN_HEIGHT / 2, 0);
		touchPoint = new Vector3();
		batcher = new SpriteBatch();
		handler = new BattlefieldEventHandler() {
			@Override
			public void playerHit() {
				Assets.playSound(Assets.playerHit);
			}
			@Override
			public void playerAttack() {
				Assets.playSound(Assets.playerAttack);
			}
			@Override
			public void playerDie() {
				Assets.playSound(Assets.playerDies);
			}
			@Override
			public void enemyHit(Enemy enemy) {
				Assets.playSound(enemy.hitSound);
			}
			@Override
			public void enemyAttack(Enemy enemy) {
				Assets.playSound(enemy.attackSound);
			}
		};
		battlefield = new Battlefield(handler);
		renderer = new BattlefieldRenderer(batcher, battlefield);
		pauseButtonBounds = new Rectangle(AngelGame.SCREEN_WIDTH - 100, AngelGame.SCREEN_HEIGHT - 100,
				100, 100);
	}
	
	public void update(float deltaTime) {
		// account for lag
		if (deltaTime > 0.1f) deltaTime = 0.1f;
		
		switch (curState) {
		case GAME_RUNNING:
			updateRunning(deltaTime);
			break;
		case GAME_PAUSED:
			updatePaused();
			break;
		case GAME_LEVEL_END:
			updateLevelEnd();
			break;
		case GAME_OVER:
			updateGameOver();
			break;
		}
	}
	
	private void updatePlayerInputs() {
		// attempt to move player based on input
		if (Gdx.input.isTouched()) {
            guiCam.unproject(touchPoint.set(Gdx.input.getX(), Gdx.input.getY(), 0));
            System.out.println("TOUCHEDX: " + touchPoint.x + " TOUCHEDY: " + touchPoint.y);
			if (playerSelected) {
				playerSelected = false;
				
				for (Enemy e : battlefield.enemies) {
					if (OverlapTester.pointInRectangle(e.bounds, touchPoint.x, touchPoint.y))
					{
						battlefield.pchar.trackedEnemy = e;
						battlefield.pchar.trackingEnemy = true;
					}
				}
				if (!battlefield.pchar.trackingEnemy)
				{
                    // something about these points is projecting wrong.
					battlefield.pchar.destination.set(touchPoint.x, touchPoint.y);
				}
			} else {
                if (OverlapTester.pointInRectangle(battlefield.pchar.bounds, touchPoint.x, touchPoint.y))
                {
                    playerSelected = true;
                }
            }
		}
	}
	
	public void updateRunning(float deltaTime) {
        updatePlayerInputs();
		if (Gdx.input.isTouched()) {
			guiCam.unproject(touchPoint.set(Gdx.input.getX(), Gdx.input.getY(),0));
			if (lastPause + PAUSE_DELAY*AngelGame.NANO < System.nanoTime() &&
                    OverlapTester.pointInRectangle(pauseButtonBounds, touchPoint.x, touchPoint.y))
			{
				Assets.playSound(Assets.tapSound);
				curState = GAME_PAUSED;
				Assets.bgMusic.pause();

                lastPause = System.nanoTime();
				return;
			}
		}
		if (battlefield.curState == Battlefield.BF_STATE_NEXT_LEVEL) {
			curState = GAME_LEVEL_END;
		}
		if (battlefield.curState == Battlefield.BF_STATE_GAME_OVER) {
			curState = GAME_OVER;
		}
		battlefield.update(deltaTime);
	}
	
	private void updatePaused() {
		if (lastPause + PAUSE_DELAY*AngelGame.NANO < System.nanoTime() &&
                Gdx.input.isTouched()) {
			//guiCam.unproject(touchPoint.set(Gdx.input.getX(), Gdx.input.getY(),0));
			Assets.playSound(Assets.tapSound);
			Assets.bgMusic.play();
			curState = GAME_RUNNING;
            lastPause = System.nanoTime();
			return;
		}
	}
	
	private void updateLevelEnd() {
		//TODO change levelUp so that it doesn't need
		//to take in inputs
		//also shouldn't be null skill
		if (Gdx.input.isTouched()) {
			battlefield.pchar.levelUp(new Skill());
		}
	}
	
	private void updateGameOver() {
		if (Gdx.input.isTouched()) {
			game.setScreen(new MainMenuScreen(game));
		}
	}
	
	public void draw (float deltaTime) {
		GLCommon gl = Gdx.gl;
		gl.glClear(GL10.GL_COLOR_BUFFER_BIT);

		renderer.render();

		guiCam.update();
		batcher.setProjectionMatrix(guiCam.combined);
		batcher.enableBlending();
		batcher.begin();

		switch (curState) {
		case GAME_RUNNING:
			presentRunning();
			break;
		case GAME_PAUSED:
			presentPaused();
			break;
		case GAME_LEVEL_END:
			presentLevelEnd();
			break;
		case GAME_OVER:
			presentGameOver();
			break;
		}
		batcher.end();
	}
	
	private void presentRunning() {
		batcher.draw(Assets.pauseButton, AngelGame.SCREEN_WIDTH-64, AngelGame.SCREEN_HEIGHT-64, 64, 64);
	}
	
	private void presentPaused() {
		batcher.draw(Assets.pauseLogo, (AngelGame.SCREEN_WIDTH - Assets.pauseLogo.getWidth())/2, AngelGame.SCREEN_HEIGHT/2);
	}
	
	private void presentLevelEnd() {
//		String endText = "ur mum #rekt";
//		float endWidth = Assets.font.getBounds(endText).width;
//		Assets.font.draw(batcher, endText,  AngelGame.SCREEN_WIDTH-endWidth/2, AngelGame.SCREEN_HEIGHT/2);
		// no font asset yet
	}
	
	private void presentGameOver() {
		batcher.draw(Assets.gameOver, AngelGame.SCREEN_WIDTH/2, AngelGame.SCREEN_HEIGHT/2);
	}

	
	
	@Override
	public void render(float delta) {
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
		if (curState == GAME_RUNNING) curState = GAME_PAUSED;
	}

	@Override
	public void resume() {
	}

	@Override
	public void dispose() {
	}
	
}
