package net.zachwalker.ballsort;

import com.badlogic.gdx.Game;


public class BallSortGame extends Game {
	
	@Override
	public void create () {
		setScreen(new BallSortScreen());
	}

}
