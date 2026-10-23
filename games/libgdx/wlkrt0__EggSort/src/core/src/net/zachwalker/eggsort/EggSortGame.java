package net.zachwalker.eggsort;

import com.badlogic.gdx.Game;

public class EggSortGame extends Game {
	
	@Override
	public void create () {
		setScreen(new EggSortScreen());
	}

}
