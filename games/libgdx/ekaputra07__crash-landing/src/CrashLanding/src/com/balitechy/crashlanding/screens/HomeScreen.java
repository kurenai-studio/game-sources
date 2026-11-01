package com.balitechy.crashlanding.screens;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.GL10;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.InputListener;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.utils.Align;
import com.balitechy.crashlanding.GameAudio;
import com.balitechy.crashlanding.GameUtils;

public class HomeScreen implements Screen {
	
	private Game game;
	private Label label1, label2, label3;
	private Stage stage;
	private SpriteBatch batch;
	
	float screenWidth, screenHeight;

	public HomeScreen(Game game) {		
		this.game = game;
	}

	@Override
	public void render(float delta) {
		Gdx.gl.glClearColor(0, 0, 0, 1);
		Gdx.gl.glClear(GL10.GL_COLOR_BUFFER_BIT);
		
		stage.act(delta);
		
		batch.begin();
		stage.draw();
		batch.end();
	}

	@Override
	public void resize(int width, int height) {

	}

	@Override
	public void show() {
		screenWidth = GameUtils.getScreenWidth();
		screenHeight = GameUtils.getScreenHeight();
		
		batch = new SpriteBatch();
		
		label1 = new Label("Crash Landing", GameUtils.labelStyle());
		label1.setWidth(screenWidth);
		label1.setFontScale(1f);
		label1.setPosition(0, Gdx.graphics.getHeight()/2 + 50);
		label1.setAlignment(Align.center);
		
		label2 = new Label("<< START >>", GameUtils.labelStyle());
		label2.setWidth(screenWidth);
		label2.setFontScale(0.5f);
		label2.setPosition(0, Gdx.graphics.getHeight()/2);
		label2.setAlignment(Align.center);
		label2.addListener(new InputListener(){

			@Override
			public boolean touchDown(InputEvent event, float x, float y,
					int pointer, int button) {
				return true;
			}

			@Override
			public void touchUp(InputEvent event, float x, float y,
					int pointer, int button) {
				game.setScreen(new GameScreen(game));
			}
			
		});
		
		label3 = new Label("2014 - www.balitechy.com", GameUtils.labelStyle());
		label3.setWidth(screenWidth);
		label3.setFontScale(0.3f);
		label3.setPosition(0, Gdx.graphics.getHeight()/2 - 50);
		label3.setAlignment(Align.center);
		
		stage = new Stage(screenWidth, screenHeight);
		
		Gdx.input.setInputProcessor(stage);

		stage.addActor(label1);
		stage.addActor(label2);
		stage.addActor(label3);
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
		stage.dispose();
	}
}
