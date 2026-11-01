package com.balitechy.crashlanding.screens;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.scenes.scene2d.Group;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.InputListener;
import com.badlogic.gdx.scenes.scene2d.Touchable;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.utils.Align;
import com.balitechy.crashlanding.GameUtils;

public class GameResult extends Group{
	
	Game game;
	private Label label0, label1, label2, label3;
	
	public GameResult(final Game game) {
		this.game = game;
		final GameScreen gs = (GameScreen) game.getScreen();
		
		label0 = new Label("GOOD JOB!", GameUtils.labelStyle());
		label0.setWidth(Gdx.graphics.getWidth());
		label0.setFontScale(1.5f);
		label0.setPosition(0, Gdx.graphics.getHeight()/2 + 50);
		label0.setAlignment(Align.center);
		
		label1 = new Label("GAME OVER!", GameUtils.labelStyle());
		label1.setWidth(Gdx.graphics.getWidth());
		label1.setFontScale(1.5f);
		label1.setPosition(0, Gdx.graphics.getHeight()/2 + 50);
		label1.setAlignment(Align.center);
		
		label2 = new Label("<< RESTART >>", GameUtils.labelStyle());
		label2.setWidth(Gdx.graphics.getWidth());
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
				gs.restartGame();
			}
		});
		
		label3 = new Label("<< HOME >>", GameUtils.labelStyle());
		label3.setWidth(Gdx.graphics.getWidth());
		label3.setFontScale(0.5f);
		label3.setPosition(0, Gdx.graphics.getHeight()/2 - 50);
		label3.setAlignment(Align.center);
		label3.setTouchable(Touchable.enabled);
		label3.addListener(new InputListener(){
			
			@Override
			public boolean touchDown(InputEvent event, float x, float y,
					int pointer, int button) {
				return true;
			}

			@Override
			public void touchUp(InputEvent event, float x, float y,
					int pointer, int button) {
				game.setScreen(new HomeScreen(game));
			}
		});

		this.addActor(label0);
		this.addActor(label1);
		this.addActor(label2);
		this.addActor(label3);
	}

	@Override
	public void draw(Batch batch, float parentAlpha) {
		GameScreen screen = (GameScreen) game.getScreen();
		//Draw when crash landing
		if(screen.getShip().isCrashed()){
			label0.setVisible(false);
			super.draw(batch, parentAlpha);
		}
		
		if(screen.getShip().isLanding()){
			label1.setVisible(false);
			super.draw(batch, parentAlpha);
		}	
	}
}
