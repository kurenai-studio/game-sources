package com.devcariri.submax;

import android.os.Bundle;

import com.badlogic.gdx.backends.android.AndroidApplication;
import com.badlogic.gdx.backends.android.AndroidApplicationConfiguration;
import com.devcariri.submax.SubMaxGame;

public class AndroidLauncher extends AndroidApplication {

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		AndroidApplicationConfiguration cfg = new AndroidApplicationConfiguration();

		//cfg.useGL30 = false;
		cfg.hideStatusBar = true;
		initialize(new SubMaxGame(), cfg);
	}
}
