local l = {
	languageEng    = "Russian";
	languageNative = "Русский";

	gameName = "ZERO VELOCITY";
	
	common = {
		back = "Назад";
		on   = "Вкл";
		off  = "Выкл";
	};

	title = {
		authorFmt   = "Создатель: %s";
		press2Start = "Нажмите Огонь чтобы начать";
	};

	main = {
		play    = "Играть";
		options = "Опции";
		credits = "Создатели";
		exit    = "Выход";
	};

	options = {
		music     = "Музыка -- %d%%";
		sound     = "Звуки -- %d%%";
		language  = "Язык -- %s";
		msaa      = "MSAA -- %d";
		bloom     = "Блюм -- %d";
		scanlines = "Линии скан. -- %s";
		crt       = "CRT -- %d";
		pixel     = "Пиксель -- %d";
	};

	credits = {
		author    = "Феоген Ратькин";
		authorFmt = "Автор: %s";
		love      = "Сделано с LÖVE";
		music     = "Музыка от Eric Skiff";
		font      = "Шрифт Press Start 2P от CodeMan38";
		laser     = "Звук лазера от sharesynth";
	};

	play = {
		modes = {
			escape  = "Побег",
			endless = "Бесконечный Режим",
		};
		start = "Начать";
	};

	ships = {
		fighter    = "Истребитель";
		hauler     = "Грузчик";
		shuttle    = "Шаттл";
		icebreaker = "Ледокол";
	};

	shipStats = {
		damage = "Урон";
		range  = "Дистанция";
		speed  = "Скорость";
		heat   = "Перегрев";
	};

	ui = {
		charging = "Инициализация... %d";
	};

	pause = {
		resume = "Возобновить";
	};

	gameover = {
		retry = "Еще раз";
	};

	win = {
		l1 = "Поздравляем!";
		l2 = "Вы сбежали из Черной Дыры. Вы теперь в безопасности.";
		l3 = "... так ведь?";
		endlessMode = "Продолжить в Бесконечный Режим";
	};
}

return l
