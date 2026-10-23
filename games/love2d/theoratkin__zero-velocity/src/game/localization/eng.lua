local l = {
	languageEng    = "English";
	languageNative = "English";

	gameName = "ZERO VELOCITY";
	
	common = {
		back = "Back";
		on   = "On";
		off  = "Off";
	};

	title = {
		authorFmt   = "by %s";
		press2Start = "Press Fire to start";
	};

	main = {
		play    = "Play";
		options = "Options";
		credits = "Credits";
		exit    = "Exit";
	};

	options = {
		music     = "Music -- %d%%";
		sound     = "Sound -- %d%%";
		language  = "Language -- %s";
		msaa      = "MSAA -- %d";
		bloom     = "Bloom -- %d";
		scanlines = "Scanlines -- %s";
		crt       = "CRT -- %d";
		pixel     = "Pixel -- %d";
	};

	credits = {
		author    = "Theogen Ratkin";
		authorFmt = "Author: %s";
		love      = "Made with LÖVE";
		music     = "Music by Eric Skiff";
		font      = "Font Press Start 2P by CodeMan38";
		laser     = "Laser sound effect by sharesynth";
	};

	play = {
		modes = {
			escape  = "Escape Mode",
			endless = "Endless Mode",
		};
		start = "Start";
	};

	ships = {
		fighter    = "Fighter";
		hauler     = "Hauler";
		shuttle    = "Shuttle";
		icebreaker = "Icebreaker";
	};

	shipStats = {
		damage = "Damage";
		range  = "Range";
		speed  = "Speed";
		heat   = "Heating";
	};

	ui = {
		charging = "Charging... %d";
	};

	pause = {
		resume = "Resume";
	};

	gameover = {
		retry = "Retry";
	};

	win = {
		l1 = "Congratulations!";
		l2 = "You have escaped the Black Hole and you are save now.";
		l3 = "... or are you?";
		endlessMode = "Continue to Endless Mode";
	};
}

return l
