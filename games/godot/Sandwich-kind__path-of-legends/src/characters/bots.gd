class_name Bots
# Виды ботов для Арены. У каждого свой размер, оружие, повадки и способности.
# Способности: grenade — граната, shell — массивный снаряд, shield — щит,
# barrage — залп навесом, quake — взрывы из-под земли.

const TYPES := {
	"grunt": {
		"name": "Рядовой", "color": Color(0.85, 0.32, 0.30), "size": Vector2(40, 60),
		"hp": 60, "speed": 300.0, "decor": "",
		"gun": [650.0, 6, 0.0, 0.85, 9.0], "clip": 6, "reload": 2.2,   # скорость, урон, взрыв, темп, размер
		"keep": [250.0, 450.0], "jump": 0.2, "abilities": {},
	},
	"runner": {
		"name": "Шустрик", "color": Color(0.80, 0.86, 0.28), "size": Vector2(28, 38),
		"hp": 30, "speed": 480.0, "decor": "band",
		"gun": [800.0, 4, 0.0, 0.45, 6.0], "clip": 5, "reload": 1.8,
		"keep": [45.0, 60.0], "jump": 0.35, "melee": 5, "abilities": {},
	},
	"soldier": {
		"name": "Солдат", "color": Color(0.42, 0.62, 0.36), "size": Vector2(40, 60),
		"hp": 85, "speed": 320.0, "decor": "helmet",
		"gun": [700.0, 7, 0.0, 0.7, 9.0], "clip": 8, "reload": 2.2,
		"keep": [300.0, 550.0], "jump": 0.2, "abilities": {"grenade": 7.0},
	},
	"tank": {
		"name": "Танк", "color": Color(0.48, 0.50, 0.60), "size": Vector2(62, 82),
		"hp": 240, "speed": 190.0, "decor": "armor",
		"gun": [460.0, 14, 18.0, 1.5, 15.0], "clip": 3, "reload": 2.8,
		"keep": [200.0, 480.0], "jump": 0.05, "abilities": {"shield": 11.0},
	},
	"gunner": {
		"name": "Артиллерист", "color": Color(0.66, 0.40, 0.75), "size": Vector2(44, 58),
		"hp": 70, "speed": 260.0, "decor": "cap",
		"gun": [600.0, 5, 0.0, 1.0, 8.0], "clip": 5, "reload": 2.4,
		"keep": [650.0, 1100.0], "jump": 0.15, "abilities": {"barrage": 10.0}, "mortars": 4,
	},
	"breacher": {
		"name": "Пробойщик", "color": Color(0.30, 0.56, 0.78), "size": Vector2(48, 66),
		"hp": 130, "speed": 250.0, "decor": "visor",
		"gun": [580.0, 9, 10.0, 1.0, 11.0], "clip": 5, "reload": 2.4,
		"keep": [350.0, 750.0], "jump": 0.1, "abilities": {"shell": 8.0},
	},
	# ----- мини-босс 5-й волны и босс 10-й -----
	"gladiator": {
		"name": "Гладиатор", "color": Color(0.72, 0.45, 0.25), "size": Vector2(76, 104),
		"hp": 1350, "speed": 240.0, "decor": "gladiator", "boss": true, "raid_brain": true,
		"gun": [0.0, 12, 0.0, 1.6, 0.0], "clip": 2, "reload": 1.8, "gun_kind": "spear", "range": 800.0,
		"keep": [120.0, 420.0], "jump": 0.05, "swing": 22,
		"abilities": {"charge": 6.0, "swing": 2.0, "volley": 9.0, "whirlwind": 12.0},
		"hint": "Гладиатор разбегается — уклонись, и пусть врежется в стену: оглушённый, он получает двойной урон! После вихря с мечом у него кружится голова.",
	},
	"colossus": {
		"name": "Колосс", "color": Color(0.26, 0.20, 0.32), "size": Vector2(160, 220),
		"hp": 2000, "speed": 130.0, "decor": "horns", "boss": true, "eye": Color(1.0, 0.25, 0.2), "raid_brain": true,
		"phase2_hp": 1600, "phase2_name": "Колосс Пробуждённый",
		"gun": [540.0, 15, 24.0, 0.9, 18.0], "clip": 6, "reload": 2.5,
		"keep": [160.0, 480.0], "jump": 0.0,
		"abilities": {"quake": 11.0, "grenade": 7.0, "barrage": 13.0, "shell": 8.0, "shockwave": 8.0,
				"chain_pull": 10.0, "summon": 26.0}, "mortars": 8,
		"front_armor": 0.85, "turn_time": 1.2, "quake_stun": 2.5,
		"hint": "Спереди Колосса не пробить — бей в спину! Перепрыгивай ударную волну, уходи с линии цепи. Ранен — он злится и бьёт чаще, а раскалившись, слабеет сзади ещё сильнее.",
		"hint2": "Броня разбита — бей с любой стороны! Прыгай через огненный рывок и столбы пламени, следи за тенью с неба. После «Сверхновой» Колосс выдыхается — тогда урон по нему двойной.",
	},
	# ----- гоблины джунглей -----
	"goblin": {
		"name": "Гоблин-копейщик", "color": Color(0.45, 0.70, 0.30), "size": Vector2(34, 48),
		"hp": 45, "speed": 330.0, "decor": "goblin",
		"gun": [0.0, 8, 0.0, 1.3, 0.0], "clip": 3, "reload": 2.0, "gun_kind": "spear", "range": 900.0,
		"keep": [300.0, 600.0], "jump": 0.25, "abilities": {},
	},
	"sneak": {
		"name": "Гоблин-лазутчик", "color": Color(0.30, 0.50, 0.35), "size": Vector2(30, 42),
		"hp": 35, "speed": 470.0, "decor": "hood",
		"gun": [750.0, 3, 0.0, 0.5, 6.0], "clip": 4, "reload": 1.6,
		"keep": [40.0, 60.0], "jump": 0.35, "melee": 6, "abilities": {"smoke": 9.0},
	},
	"bomber": {
		"name": "Гоблин-подрывник", "color": Color(0.58, 0.66, 0.26), "size": Vector2(38, 48),
		"hp": 55, "speed": 280.0, "decor": "goggles",
		"gun": [0.0, 16, 0.0, 2.2, 0.0], "clip": 1, "reload": 2.5, "gun_kind": "spear", "payload": "bomb",
		"range": 850.0, "keep": [400.0, 700.0], "jump": 0.2, "abilities": {"bombs": 10.0},
	},
	"shaman": {
		"name": "Гоблин-шаман", "color": Color(0.40, 0.60, 0.52), "size": Vector2(36, 52),
		"hp": 60, "speed": 260.0, "decor": "mask",
		"gun": [520.0, 6, 0.0, 1.1, 12.0], "clip": 4, "reload": 2.2,
		"keep": [550.0, 900.0], "jump": 0.15, "abilities": {"heal_allies": 6.0, "smoke": 15.0},
	},
	"brute": {
		"name": "Гоблин-громила", "color": Color(0.36, 0.50, 0.25), "size": Vector2(64, 80),
		"hp": 220, "speed": 220.0, "decor": "brute",
		"gun": [500.0, 10, 0.0, 1.2, 12.0], "clip": 3, "reload": 2.4,
		"keep": [60.0, 140.0], "jump": 0.1, "melee": 12, "abilities": {"slam": 5.0},
	},
	# ----- мини-босс 15-й волны и босс 20-й -----
	"chief": {
		"name": "Вождь гоблинов", "color": Color(0.60, 0.56, 0.22), "size": Vector2(64, 88),
		"hp": 1300, "speed": 260.0, "decor": "chief", "boss": true,
		"gun": [0.0, 12, 0.0, 1.0, 0.0], "clip": 3, "reload": 1.8, "gun_kind": "spear", "range": 1000.0,
		"keep": [300.0, 700.0], "jump": 0.2,
		"abilities": {"volley": 7.0, "warcry": 15.0, "summon": 22.0, "smoke": 12.0},
		"hint": "Вождь бросает веер копий, боевым кличем лечит и ускоряет гоблинов и зовёт подмогу.",
	},
	"treant": {
		"name": "Древний Энт", "color": Color(0.42, 0.30, 0.18), "size": Vector2(150, 215),
		"hp": 2200, "speed": 110.0, "decor": "treant", "boss": true, "eye": Color(0.5, 1.0, 0.3),
		"gun": [0.0, 14, 0.0, 1.4, 0.0], "clip": 4, "reload": 2.4, "gun_kind": "spear", "payload": "seed",
		"range": 1100.0, "keep": [250.0, 700.0], "jump": 0.0,
		"abilities": {"roots": 6.0, "spores": 13.0, "summon": 25.0},
		"hint": "Пока стоят Тотемы жизни, Энта не ранить — сломай их! За бой они вырастут ещё два раза: когда у Энта останется 2/3 и 1/3 здоровья.",
	},
	"totem": {
		"name": "Тотем жизни", "color": Color(0.50, 0.36, 0.20), "size": Vector2(40, 80),
		"hp": 140, "speed": 0.0, "decor": "totem", "eye": Color(0.5, 1.0, 0.3),
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [0.0, 99999.0], "jump": 0.0, "abilities": {},
	},
	# ----- Жуткий лес (волны 51–55) -----
	"ghoul": {
		"name": "Упырь", "color": Color(0.55, 0.58, 0.55), "size": Vector2(40, 58),
		"hp": 110, "speed": 340.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [30.0, 70.0], "jump": 0.2, "abilities": {"swing": 1.8, "pounce": 5.0}, "swing": 13, "melee": 6,
	},
	"scarecrow": {
		"name": "Живое пугало", "color": Color(0.78, 0.66, 0.44), "size": Vector2(44, 68),
		"hp": 150, "speed": 240.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [60.0, 140.0], "jump": 0.1, "abilities": {"swing": 2.2, "summon": 14.0}, "swing": 16,
	},
	"crow": {
		"name": "Ворон", "color": Color(0.10, 0.10, 0.12), "size": Vector2(36, 26),
		"hp": 40, "speed": 380.0, "decor": "", "flying": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [0.0, 99999.0], "jump": 0.0, "melee": 7, "abilities": {"dive": 3.0},
	},
	"wisp": {
		"name": "Блуждающий огонёк", "color": Color(0.55, 1.0, 0.75), "size": Vector2(34, 34),
		"hp": 60, "speed": 200.0, "decor": "", "flying": true,
		"gun": [0.0, 9, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [0.0, 99999.0], "jump": 0.0, "abilities": {"fire_orb": 2.6},
	},
	"deadwood": {
		"name": "Корявник", "color": Color(0.30, 0.26, 0.24), "size": Vector2(64, 90),
		"hp": 280, "speed": 150.0, "decor": "",
		"gun": [0.0, 12, 0.0, 1.6, 0.0], "clip": 2, "reload": 2.5, "gun_kind": "spear", "payload": "branch",
		"range": 900.0, "keep": [250.0, 600.0], "jump": 0.05, "abilities": {"roots": 9.0},
	},
	"witch": {
		"name": "Ведьма Полынь", "color": Color(0.62, 0.72, 0.55), "size": Vector2(56, 84),
		"hp": 1400, "speed": 230.0, "decor": "", "boss": true, "raid_brain": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [350.0, 700.0], "jump": 0.05,
		"abilities": {"hex": 6.0, "flask_volley": 7.5, "witch_blink": 9.0, "summon": 18.0},
		"hint": "Ведьма проклинает землю под тобой — вовремя сойди с фиолетового круга! После вспышки воронов она оказывается в другом месте.",
	},
	# ----- Болото (волны 56–60) -----
	"bogman": {
		"name": "Болотник", "color": Color(0.30, 0.32, 0.20), "size": Vector2(48, 66),
		"hp": 160, "speed": 210.0, "decor": "",
		"gun": [0.0, 8, 0.0, 2.0, 0.0], "clip": 2, "reload": 2.2, "gun_kind": "spear", "payload": "mud",
		"range": 850.0, "keep": [300.0, 600.0], "jump": 0.08, "abilities": {"swing": 2.4}, "swing": 14,
	},
	"frogman": {
		"name": "Жаболюд", "color": Color(0.38, 0.58, 0.30), "size": Vector2(44, 54),
		"hp": 120, "speed": 320.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [70.0, 170.0], "jump": 0.15, "abilities": {"pounce": 4.5, "tongue": 7.0, "swing": 2.0}, "swing": 12, "melee": 6,
	},
	"leech": {
		"name": "Пиявка", "color": Color(0.30, 0.20, 0.24), "size": Vector2(36, 20),
		"hp": 50, "speed": 260.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [10.0, 25.0], "jump": 0.0, "melee": 5, "abilities": {"latch": 2.5},
	},
	"mosquito": {
		"name": "Комариный рой", "color": Color(0.35, 0.32, 0.28), "size": Vector2(42, 32),
		"hp": 45, "speed": 360.0, "decor": "", "flying": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [0.0, 99999.0], "jump": 0.0, "melee": 5, "abilities": {"dive": 3.5},
	},
	"drowned": {
		"name": "Утопленник", "color": Color(0.52, 0.62, 0.62), "size": Vector2(50, 72),
		"hp": 240, "speed": 170.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [60.0, 140.0], "jump": 0.05, "abilities": {"swing": 2.6, "anchor_pull": 9.0}, "swing": 20,
	},
	"bog_lord": {
		"name": "Трясинный Владыка", "color": Color(0.26, 0.30, 0.20), "size": Vector2(170, 200),
		"hp": 3400, "speed": 120.0, "decor": "", "boss": true, "eye": Color(1.0, 0.85, 0.3), "raid_brain": true,
		"gun": [0.0, 14, 0.0, 1.8, 0.0], "clip": 3, "reload": 2.6, "gun_kind": "spear", "payload": "mud",
		"range": 1000.0, "keep": [200.0, 600.0], "jump": 0.0,
		"abilities": {"submerge": 11.0, "mud_wave": 8.0, "gas_burst": 10.0, "roots": 9.0, "summon": 22.0},
		"hint": "Владыка ныряет в трясину и вылезает прямо под тобой — смотри на пузыри! Перепрыгивай волну грязи и не стой у газовых пузырей.",
	},
	# Хрустальная приманка Призмы (способность «Преломление»): стоит и отвлекает врагов
	"crystal_decoy": {
		"name": "Хрустальная приманка", "color": Color(0.70, 0.82, 1.0), "size": Vector2(40, 60),
		"hp": 60, "speed": 0.0, "decor": "", "eye": Color(0.9, 0.95, 1.0),
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [0.0, 99999.0], "jump": 0.0, "abilities": {},
	},
	# ----- Лесная тропа: приспешники Тёмного лорда (волны 1–5) -----
	"minion": {
		"name": "Прислужник", "color": Color(0.30, 0.28, 0.34), "size": Vector2(38, 58),
		"hp": 45, "speed": 280.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [40.0, 90.0], "jump": 0.2, "abilities": {"swing": 2.2}, "swing": 7,
	},
	"imp": {
		"name": "Бесёнок", "color": Color(0.62, 0.24, 0.30), "size": Vector2(28, 38),
		"hp": 24, "speed": 440.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [15.0, 35.0], "jump": 0.4, "melee": 5, "abilities": {},
	},
	"minion_archer": {
		"name": "Прислужник-лучник", "color": Color(0.26, 0.30, 0.26), "size": Vector2(36, 56),
		"hp": 35, "speed": 270.0, "decor": "",
		"gun": [850.0, 6, 0.0, 1.3, 8.0], "clip": 3, "reload": 2.0, "bullet_style": "arrow", "range": 1000.0,
		"keep": [450.0, 800.0], "jump": 0.15, "abilities": {},
	},
	"minion_shield": {
		"name": "Прислужник со щитом", "color": Color(0.34, 0.32, 0.36), "size": Vector2(44, 62),
		"hp": 90, "speed": 220.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [40.0, 90.0], "jump": 0.1, "abilities": {"swing": 2.4}, "swing": 9, "front_armor": 0.5,
	},
	"sergeant": {
		"name": "Десятник Гнилозуб", "color": Color(0.36, 0.30, 0.30), "size": Vector2(60, 86),
		"hp": 650, "speed": 240.0, "decor": "", "boss": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [60.0, 140.0], "jump": 0.08, "swing": 16,
		"abilities": {"swing": 2.2, "slam": 7.0, "warcry": 15.0, "summon": 18.0},
		"hint": "Десятник зовёт прислужников и боевым кличем лечит и подбадривает их. Не стой рядом, когда он бьёт по земле!",
	},
	# ----- Окраина деревни: бандиты (волны 6–10) -----
	"bandit_thug": {
		"name": "Бандит", "color": Color(0.46, 0.30, 0.22), "size": Vector2(40, 60),
		"hp": 60, "speed": 290.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [40.0, 90.0], "jump": 0.2, "abilities": {"swing": 2.0}, "swing": 10,
	},
	"bandit_shuriken": {
		"name": "Метатель сюрикенов", "color": Color(0.30, 0.30, 0.36), "size": Vector2(38, 58),
		"hp": 45, "speed": 310.0, "decor": "",
		"gun": [900.0, 5, 0.0, 0.9, 9.0], "clip": 4, "reload": 1.8, "bullet_style": "shuriken", "range": 950.0,
		"keep": [350.0, 650.0], "jump": 0.25, "abilities": {"shuriken_fan": 7.0},
	},
	"bandit_kunai": {
		"name": "Головорез с кунаями", "color": Color(0.22, 0.24, 0.28), "size": Vector2(38, 58),
		"hp": 55, "speed": 330.0, "decor": "",
		"gun": [1000.0, 8, 0.0, 1.2, 9.0], "clip": 3, "reload": 1.6, "bullet_style": "kunai", "range": 1000.0,
		"keep": [250.0, 500.0], "jump": 0.25, "abilities": {"smoke_step": 9.0}, "swing": 12,
	},
	"bandit_torch": {
		"name": "Поджигатель", "color": Color(0.55, 0.30, 0.18), "size": Vector2(40, 60),
		"hp": 55, "speed": 270.0, "decor": "",
		"gun": [0.0, 8, 0.0, 2.4, 0.0], "clip": 1, "reload": 0.4, "gun_kind": "spear", "payload": "firebottle",
		"range": 850.0, "keep": [380.0, 700.0], "jump": 0.15, "abilities": {},
	},
	"bandit_bola": {
		"name": "Ловчий с боласом", "color": Color(0.40, 0.36, 0.22), "size": Vector2(40, 60),
		"hp": 60, "speed": 300.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [70.0, 150.0], "jump": 0.2, "abilities": {"net": 6.0, "swing": 2.2}, "swing": 9,
	},
	"bandit_brute": {
		"name": "Вышибала", "color": Color(0.50, 0.32, 0.24), "size": Vector2(58, 78),
		"hp": 200, "speed": 210.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [50.0, 120.0], "jump": 0.08, "abilities": {"swing": 2.4, "slam": 6.0}, "swing": 18,
	},
	"ataman": {
		"name": "Атаман Чёрный Вепрь", "color": Color(0.30, 0.20, 0.18), "size": Vector2(76, 104),
		"hp": 1150, "speed": 230.0, "decor": "", "boss": true, "raid_brain": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [70.0, 180.0], "jump": 0.05, "swing": 24,
		"abilities": {"swing": 2.3, "whirlwind": 9.0, "powder_keg": 8.0, "summon": 20.0},
		"hint": "Атаман раскручивается вихрем с топором — отбегай! Потом у него кружится голова: бей, урон ×2. Бочки с порохом перепрыгивай.",
	},
	# ----- Колизей: ветераны арены (волны 41–50) -----
	# ----- История: противники поля -----
	"bandit": {
		"name": "Разбойник", "color": Color(0.45, 0.25, 0.20), "size": Vector2(40, 60),
		"hp": 55, "speed": 270.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [40.0, 90.0], "jump": 0.15, "abilities": {"swing": 2.4}, "swing": 7,
	},
	"dummy": {
		"name": "Тренировочное чучело", "color": Color(0.85, 0.72, 0.40), "size": Vector2(40, 60),
		"hp": 100000, "speed": 0.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [0.0, 99999.0], "jump": 0.0, "abilities": {},
	},
	"fighter": {
		"name": "Боец арены", "color": Color(0.58, 0.40, 0.22), "size": Vector2(40, 60),
		"hp": 90, "speed": 300.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [40.0, 90.0], "jump": 0.2, "abilities": {"swing": 1.9, "lunge": 6.0}, "swing": 14,
	},
	"thrower": {
		"name": "Метатель копий", "color": Color(0.86, 0.80, 0.64), "size": Vector2(38, 58),
		"hp": 60, "speed": 300.0, "decor": "",
		"gun": [0.0, 11, 0.0, 1.4, 0.0], "clip": 2, "reload": 2.0, "gun_kind": "spear", "range": 950.0,
		"keep": [350.0, 650.0], "jump": 0.2, "abilities": {"volley": 8.0},
	},
	"slinger": {
		"name": "Пращник", "color": Color(0.55, 0.48, 0.30), "size": Vector2(34, 52),
		"hp": 55, "speed": 320.0, "decor": "",
		"gun": [0.0, 8, 0.0, 0.8, 0.0], "clip": 4, "reload": 1.8, "gun_kind": "spear", "payload": "stone",
		"range": 850.0, "keep": [400.0, 700.0], "jump": 0.25, "abilities": {"triple_sling": 6.0},
	},
	"retiarius": {
		"name": "Ретиарий", "color": Color(0.85, 0.66, 0.50), "size": Vector2(40, 60),
		"hp": 100, "speed": 310.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [60.0, 140.0], "jump": 0.2, "abilities": {"net": 6.0, "swing": 1.8, "lunge": 7.0}, "swing": 14,
	},
	"murmillo": {
		"name": "Мирмиллон", "color": Color(0.75, 0.62, 0.35), "size": Vector2(52, 72),
		"hp": 240, "speed": 210.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [50.0, 110.0], "jump": 0.08, "abilities": {"swing": 2.0, "shield_bash": 7.0}, "swing": 24, "front_armor": 0.5,
	},
	"lion": {
		"name": "Лев арены", "color": Color(0.82, 0.60, 0.30), "size": Vector2(70, 44),
		"hp": 110, "speed": 430.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [20.0, 40.0], "jump": 0.15, "melee": 12, "abilities": {"pounce": 4.0, "lion_roar": 10.0},
	},
	"beastmaster": {
		"name": "Укротитель", "color": Color(0.55, 0.30, 0.22), "size": Vector2(42, 62),
		"hp": 130, "speed": 270.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [90.0, 200.0], "jump": 0.15, "abilities": {"swing": 2.0, "summon": 20.0, "lion_roar": 12.0}, "swing": 13,
	},
	"sagittarius": {
		"name": "Сагиттарий", "color": Color(0.36, 0.42, 0.30), "size": Vector2(38, 58),
		"hp": 80, "speed": 290.0, "decor": "",
		"gun": [1100.0, 9, 0.0, 1.0, 8.0], "clip": 3, "reload": 2.0, "bullet_style": "arrow", "range": 1200.0,
		"keep": [600.0, 1000.0], "jump": 0.15, "abilities": {"arrow_rain": 9.0},
	},
	# ----- Пещеры: скелеты и твари (волны 21–30) -----
	"skeleton": {
		"name": "Скелет", "color": Color(0.90, 0.88, 0.80), "size": Vector2(36, 58),
		"hp": 28, "speed": 260.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [20.0, 40.0], "jump": 0.2, "melee": 7, "abilities": {},
	},
	"skel_sword": {
		"name": "Скелет-мечник", "color": Color(0.90, 0.88, 0.80), "size": Vector2(40, 60),
		"hp": 75, "speed": 270.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [50.0, 100.0], "jump": 0.2, "abilities": {"swing": 1.7}, "swing": 14,
	},
	"skel_thrower": {
		"name": "Скелет-метатель", "color": Color(0.90, 0.88, 0.80), "size": Vector2(38, 58),
		"hp": 45, "speed": 280.0, "decor": "",
		"gun": [0.0, 8, 0.0, 1.1, 0.0], "clip": 3, "reload": 2.0, "gun_kind": "spear", "payload": "bone",
		"range": 900.0, "keep": [350.0, 650.0], "jump": 0.2, "abilities": {},
	},
	"necromancer": {
		"name": "Некромант", "color": Color(0.18, 0.12, 0.24), "size": Vector2(40, 64),
		"hp": 120, "speed": 240.0, "decor": "",
		"gun": [480.0, 8, 0.0, 1.3, 12.0], "clip": 3, "reload": 2.2, "range": 900.0,
		"keep": [450.0, 800.0], "jump": 0.15, "abilities": {"raise": 3.0, "swing": 2.0}, "swing": 12,
	},
	"bat": {
		"name": "Пещерная мышь", "color": Color(0.30, 0.22, 0.24), "size": Vector2(36, 26),
		"hp": 22, "speed": 380.0, "decor": "", "flying": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [0.0, 99999.0], "jump": 0.0, "melee": 6, "abilities": {"dive": 3.5},
	},
	"spider": {
		"name": "Пещерный паук", "color": Color(0.22, 0.18, 0.22), "size": Vector2(44, 26),
		"hp": 40, "speed": 400.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [120.0, 260.0], "jump": 0.2, "melee": 6, "abilities": {"pounce": 3.5, "web": 6.0},
	},
	"spider_queen": {
		"name": "Паучья королева", "color": Color(0.28, 0.12, 0.22), "size": Vector2(130, 70),
		"hp": 1500, "speed": 260.0, "decor": "", "boss": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [80.0, 400.0], "jump": 0.1, "melee": 14,
		"abilities": {"pounce": 5.0, "web_volley": 7.0, "summon": 18.0},
		"hint": "Королева опутывает паутиной и прыгает. Уклоняйся от прыжка и бей паучат, пока их не стало много!",
	},
	"skeleton_king": {
		"name": "Король скелетов", "color": Color(0.90, 0.88, 0.80), "size": Vector2(100, 175),
		"hp": 2800, "speed": 150.0, "decor": "", "boss": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [80.0, 300.0], "jump": 0.03, "swing": 30,
		"abilities": {"swing": 2.4, "bone_wave": 7.0, "bone_storm": 10.0, "summon": 24.0},
		"hint": "Теряя каждую треть здоровья, Король зовёт стражу и ненадолго становится неуязвим. Перепрыгивай волну костей!",
	},
	# ----- Драгоценные пещеры: кобольды и их добыча (волны 31–35) -----
	"kobold_miner": {
		"name": "Кобольд-рудокоп", "color": Color(0.66, 0.40, 0.24), "size": Vector2(34, 46),
		"hp": 60, "speed": 300.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [40.0, 90.0], "jump": 0.2, "abilities": {"swing": 1.8}, "swing": 10, "brain": true,
	},
	"kobold_bomber": {
		"name": "Кобольд-подрывник", "color": Color(0.70, 0.46, 0.26), "size": Vector2(34, 46),
		"hp": 50, "speed": 270.0, "decor": "",
		"gun": [0.0, 20, 0.0, 2.6, 0.0], "clip": 1, "reload": 0.6, "gun_kind": "spear", "payload": "dynamite",
		"range": 950.0, "keep": [380.0, 700.0], "jump": 0.2, "abilities": {},
	},
	"gem_beetle": {
		"name": "Самоцветный жук", "color": Color(0.18, 0.72, 0.42), "size": Vector2(52, 30),
		"hp": 75, "speed": 230.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [30.0, 60.0], "jump": 0.1, "melee": 8, "front_armor": 0.7, "abilities": {"roll": 5.0}, "brain": true,
	},
	"cart_rider": {
		"name": "Вагонетчик", "color": Color(0.62, 0.38, 0.22), "size": Vector2(56, 54),
		"hp": 95, "speed": 230.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [250.0, 650.0], "jump": 0.05, "melee": 10, "abilities": {"charge": 4.5}, "brain": true,
	},
	"ruby_golem": {
		"name": "Рубиновый голем", "color": Color(0.42, 0.36, 0.38), "size": Vector2(70, 88),
		"hp": 260, "speed": 150.0, "decor": "",
		"gun": [0.0, 14, 0.0, 2.3, 0.0], "clip": 1, "reload": 0.5, "gun_kind": "spear", "payload": "ruby",
		"range": 900.0, "keep": [220.0, 600.0], "jump": 0.03, "abilities": {"slam": 6.0}, "stagger": 0.25, "brain": true,
	},
	"gem_shaman": {
		"name": "Гранильщик", "color": Color(0.26, 0.42, 0.36), "size": Vector2(36, 52),
		"hp": 70, "speed": 240.0, "decor": "",
		"gun": [560.0, 7, 0.0, 1.2, 10.0], "clip": 4, "reload": 2.0, "range": 850.0,
		"keep": [500.0, 850.0], "jump": 0.15, "abilities": {"gem_shield": 7.0},
	},
	"baron_gryz": {
		"name": "Барон Грызь", "color": Color(0.45, 0.18, 0.22), "size": Vector2(150, 112),
		"hp": 1800, "speed": 190.0, "decor": "", "boss": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [90.0, 450.0], "jump": 0.0, "melee": 14, "swing": 26, "back_mult": 2.0,
		"abilities": {"swing": 2.6, "burrow": 9.0, "dynamite_bundle": 6.0, "cart_call": 13.0}, "brain": true,
		"hint": "Барон уходит под землю и вылезает прямо под тобой — смотри на трещины! Котёл сзади машины — бей туда, урон ×2.",
	},
	# ----- Кристальные пещеры (волны 36–40) -----
	"shardling": {
		"name": "Осколочник", "color": Color(0.55, 0.80, 1.0), "size": Vector2(46, 34),
		"hp": 48, "speed": 380.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [20.0, 40.0], "jump": 0.3, "melee": 7, "abilities": {}, "split": "shardling_s", "brain": true,
	},
	"shardling_s": {
		"name": "Осколочек", "color": Color(0.72, 0.55, 1.0), "size": Vector2(36, 28),
		"hp": 22, "speed": 420.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [20.0, 40.0], "jump": 0.35, "melee": 5, "abilities": {}, "split": "shardling_xs", "brain": true,
	},
	"shardling_xs": {
		"name": "Крошка", "color": Color(0.55, 0.80, 1.0), "size": Vector2(28, 22),
		"hp": 9, "speed": 460.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [15.0, 30.0], "jump": 0.4, "melee": 3, "abilities": {},
	},
	"prismatic": {
		"name": "Призматик", "color": Color(0.80, 0.88, 1.0), "size": Vector2(44, 70),
		"hp": 95, "speed": 130.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [450.0, 850.0], "jump": 0.0, "abilities": {"beam": 3.8},
	},
	"crystal_guard": {
		"name": "Кристальный страж", "color": Color(0.55, 0.75, 1.0), "size": Vector2(48, 68),
		"hp": 170, "speed": 230.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [50.0, 110.0], "jump": 0.08, "abilities": {"swing": 2.0}, "swing": 16, "front_armor": 0.85, "brain": true,
	},
	"mirror_double": {
		"name": "Зеркальный двойник", "color": Color(0.70, 0.90, 1.0), "size": Vector2(40, 60),
		"hp": 75, "speed": 330.0, "decor": "",
		"gun": [700.0, 6, 0.0, 0.7, 9.0], "clip": 6, "reload": 2.0,
		"keep": [250.0, 500.0], "jump": 0.2, "abilities": {},
	},
	"resonator": {
		"name": "Резонатор", "color": Color(0.72, 0.55, 1.0), "size": Vector2(42, 72),
		"hp": 120, "speed": 150.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [90.0, 260.0], "jump": 0.0, "abilities": {"resonate": 4.5},
	},
	"crystal_moth": {
		"name": "Хрустальная моль", "color": Color(0.82, 0.78, 1.0), "size": Vector2(46, 32),
		"hp": 38, "speed": 360.0, "decor": "", "flying": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [0.0, 99999.0], "jump": 0.0, "melee": 5, "abilities": {"dive": 4.0, "dust": 5.0},
	},
	"irida": {
		"name": "Ирида, Хранительница Сердца", "color": Color(0.70, 0.75, 1.0), "size": Vector2(100, 175),
		"hp": 3500, "speed": 170.0, "decor": "", "boss": true, "eye": Color(0.95, 0.85, 1.0),
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [300.0, 700.0], "jump": 0.0, "brain": true,
		"abilities": {"rainbow_beam": 5.0, "spike_trail": 7.5, "mirror_images": 24.0, "shatter": 12.0, "summon": 26.0},
		"hint": "У настоящей Ириды есть тень — копии без тени. Её луч отражается от зеркальных кристаллов: попади им в неё саму — и она оглушена!",
	},
	"irida_image": {
		"name": "Отражение Ириды", "color": Color(0.70, 0.75, 1.0), "size": Vector2(100, 175),
		"hp": 120, "speed": 170.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [300.0, 700.0], "jump": 0.0, "brain": true, "abilities": {"rainbow_beam": 6.5},
	},
	# ----- Ледяная тропа (волны 61–65) -----
	"snow_wolf": {
		"name": "Снежный волк", "color": Color(0.82, 0.86, 0.94), "size": Vector2(64, 40),
		"hp": 110, "speed": 440.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [20.0, 40.0], "jump": 0.15, "melee": 10, "abilities": {"pounce": 4.0, "howl": 12.0},
	},
	"frost_archer": {
		"name": "Морозный лучник", "color": Color(0.82, 0.86, 0.93), "size": Vector2(38, 58),
		"hp": 90, "speed": 290.0, "decor": "",
		"gun": [1050.0, 9, 0.0, 1.2, 8.0], "clip": 3, "reload": 2.0, "bullet_style": "arrow", "range": 1100.0,
		"keep": [500.0, 900.0], "jump": 0.15, "abilities": {"frost_volley": 8.0}, "chill_shots": 1.0,
	},
	"yeti": {
		"name": "Йети", "color": Color(0.88, 0.91, 0.96), "size": Vector2(66, 86),
		"hp": 300, "speed": 220.0, "decor": "",
		"gun": [0.0, 14, 0.0, 2.2, 0.0], "clip": 1, "reload": 0.6, "gun_kind": "spear", "payload": "snowball",
		"range": 900.0, "keep": [180.0, 560.0], "jump": 0.08, "melee": 10, "abilities": {"slam": 6.0}, "stagger": 0.3,
	},
	"ice_wraith": {
		"name": "Ледяной дух", "color": Color(0.72, 0.88, 1.0), "size": Vector2(40, 46),
		"hp": 70, "speed": 220.0, "decor": "", "flying": true,
		"gun": [0.0, 9, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [0.0, 99999.0], "jump": 0.0, "abilities": {"ice_shard": 2.8},
	},
	"frost_knight": {
		"name": "Мёрзлый рыцарь", "color": Color(0.56, 0.70, 0.90), "size": Vector2(48, 68),
		"hp": 210, "speed": 230.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [50.0, 110.0], "jump": 0.08, "swing": 18, "front_armor": 0.7,
		"abilities": {"swing": 2.0, "frost_slam": 8.0},
	},
	"jotun": {
		"name": "Ётун Стужа", "color": Color(0.55, 0.68, 0.86), "size": Vector2(130, 190),
		"hp": 1750, "speed": 170.0, "decor": "", "boss": true, "eye": Color(0.6, 0.95, 1.0), "far_brain": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [80.0, 260.0], "jump": 0.0, "swing": 26,
		"abilities": {"swing": 2.4, "frost_breath": 7.0, "icicle_rain": 10.0, "ice_armor": 15.0, "glacier_wave": 9.0, "summon": 22.0},
		"hint": "Ётун дышит морозом — попадёшься второй раз, пока на тебе иней, вмёрзнешь в лёд! Ледяную броню разбей, прежде чем бить его самого.",
	},
	# ----- Храм шторма (волны 66–70) -----
	"storm_acolyte": {
		"name": "Послушник бури", "color": Color(0.32, 0.40, 0.58), "size": Vector2(38, 60),
		"hp": 100, "speed": 280.0, "decor": "",
		"gun": [760.0, 6, 0.0, 1.1, 10.0], "clip": 3, "reload": 2.0, "bullet_style": "spark", "range": 950.0,
		"keep": [380.0, 720.0], "jump": 0.15, "abilities": {"chain_spark": 5.0},
	},
	"temple_guard": {
		"name": "Храмовый страж", "color": Color(0.30, 0.40, 0.58), "size": Vector2(50, 70),
		"hp": 230, "speed": 230.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [60.0, 130.0], "jump": 0.08, "swing": 18, "front_armor": 0.6,
		"abilities": {"swing": 2.0, "lunge": 6.0},
	},
	"harpy": {
		"name": "Гарпия", "color": Color(0.42, 0.48, 0.60), "size": Vector2(56, 42),
		"hp": 80, "speed": 400.0, "decor": "", "flying": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [0.0, 99999.0], "jump": 0.0, "melee": 9, "abilities": {"dive": 3.0, "feathers": 6.0},
	},
	"ball_lightning": {
		"name": "Шаровая молния", "color": Color(0.70, 0.85, 1.0), "size": Vector2(36, 36),
		"hp": 45, "speed": 300.0, "decor": "", "flying": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [0.0, 99999.0], "jump": 0.0, "abilities": {"overload": 0.4},
	},
	"thunder_priest": {
		"name": "Жрец грома", "color": Color(0.86, 0.88, 0.94), "size": Vector2(40, 64),
		"hp": 130, "speed": 230.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [550.0, 950.0], "jump": 0.1, "abilities": {"call_lightning": 5.5, "heal_allies": 10.0},
	},
	"storm_lord": {
		"name": "Громовник, Владыка Бури", "color": Color(0.32, 0.38, 0.54), "size": Vector2(110, 190),
		"hp": 3700, "speed": 165.0, "decor": "", "boss": true, "eye": Color(0.92, 0.98, 1.0), "far_brain": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [260.0, 650.0], "jump": 0.0,
		"abilities": {"chain_lightning": 5.0, "storm_call": 8.0, "tornado": 12.0, "wind_blast": 9.0, "overload_storm": 19.0, "summon": 24.0},
		"hint": "Когда Громовник копит Перегрузку, беги к громоотводу — молния уйдёт в него и ударит обратно в Владыку: он рухнет оглушённым! Остальное время уворачивайся от молний и смерчей.",
	},
	# ----- Лавовые просторы (волны 71–75) -----
	"fire_imp": {
		"name": "Огненный бес", "color": Color(0.95, 0.40, 0.14), "size": Vector2(30, 40),
		"hp": 60, "speed": 420.0, "decor": "", "fireproof": true,
		"gun": [0.0, 8, 0.0, 1.8, 0.0], "clip": 1, "reload": 0.5, "gun_kind": "spear", "payload": "firebottle",
		"range": 800.0, "keep": [250.0, 520.0], "jump": 0.4, "abilities": {},
	},
	"magma_blob": {
		"name": "Магмовый слизень", "color": Color(0.95, 0.40, 0.10), "size": Vector2(54, 42),
		"hp": 130, "speed": 230.0, "decor": "", "fireproof": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [20.0, 40.0], "jump": 0.3, "melee": 10, "abilities": {}, "split": "magma_blob_s", "brain": true,
	},
	"magma_blob_s": {
		"name": "Магмовая капля", "color": Color(1.0, 0.50, 0.15), "size": Vector2(34, 28),
		"hp": 40, "speed": 300.0, "decor": "", "fireproof": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [15.0, 30.0], "jump": 0.35, "melee": 6, "abilities": {},
	},
	"salamander": {
		"name": "Саламандра", "color": Color(0.88, 0.36, 0.14), "size": Vector2(78, 36),
		"hp": 150, "speed": 360.0, "decor": "", "fireproof": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [90.0, 220.0], "jump": 0.1, "melee": 8, "abilities": {"fire_breath": 5.0, "pounce": 7.0},
	},
	"obsidian_golem": {
		"name": "Обсидиановый голем", "color": Color(0.16, 0.13, 0.18), "size": Vector2(72, 92),
		"hp": 330, "speed": 150.0, "decor": "", "fireproof": true,
		"gun": [0.0, 14, 0.0, 2.4, 0.0], "clip": 1, "reload": 0.5, "gun_kind": "spear", "payload": "lava",
		"range": 900.0, "keep": [220.0, 600.0], "jump": 0.03, "abilities": {"slam": 6.0}, "stagger": 0.25, "front_armor": 0.4,
	},
	"ash_walker": {
		"name": "Пепельник", "color": Color(0.42, 0.40, 0.40), "size": Vector2(44, 64),
		"hp": 180, "speed": 210.0, "decor": "", "fireproof": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [40.0, 100.0], "jump": 0.1, "swing": 14, "abilities": {"swing": 2.2},
	},
	"fire_cultist": {
		"name": "Культист пламени", "color": Color(0.55, 0.10, 0.08), "size": Vector2(40, 64),
		"hp": 125, "speed": 240.0, "decor": "", "fireproof": true,
		"gun": [600.0, 7, 0.0, 1.3, 12.0], "clip": 3, "reload": 2.2, "bullet_style": "ember", "range": 950.0,
		"keep": [500.0, 900.0], "jump": 0.12, "abilities": {"meteor": 7.0}, "burn_shots": 1.5,
	},
	"cerberus": {
		"name": "Цербер", "color": Color(0.20, 0.12, 0.12), "size": Vector2(190, 120),
		"hp": 2050, "speed": 300.0, "decor": "", "boss": true, "eye": Color(1.0, 0.75, 0.2), "far_brain": true, "fireproof": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [80.0, 320.0], "jump": 0.08, "melee": 14,
		"abilities": {"pounce": 5.0, "triple_fire": 6.5, "howl_imps": 16.0, "lava_charge": 9.0, "bite": 2.6},
		"hint": "У каждой головы Цербера своя атака: левая плюёт огнём, средняя кусает, правая воет и зовёт бесов. Огненный рывок перепрыгивай — за ним горит земля.",
	},
	# ----- Тронный зал Тёмного лорда (волны 76–80) -----
	"dark_knight": {
		"name": "Чёрный рыцарь", "color": Color(0.17, 0.15, 0.19), "size": Vector2(50, 72),
		"hp": 260, "speed": 240.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [60.0, 130.0], "jump": 0.08, "swing": 20, "front_armor": 0.7,
		"abilities": {"swing": 2.0, "charge": 7.0},
	},
	"warlock": {
		"name": "Чернокнижник", "color": Color(0.20, 0.12, 0.28), "size": Vector2(40, 64),
		"hp": 135, "speed": 230.0, "decor": "",
		"gun": [0.0, 9, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [500.0, 900.0], "jump": 0.12, "abilities": {"shadow_orbs": 4.5, "hex": 8.0},
	},
	"shade": {
		"name": "Тень", "color": Color(0.12, 0.10, 0.14), "size": Vector2(38, 60),
		"hp": 105, "speed": 380.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [40.0, 80.0], "jump": 0.2, "swing": 14, "abilities": {"shade_step": 6.0, "swing": 1.8},
	},
	"gargoyle": {
		"name": "Горгулья", "color": Color(0.42, 0.40, 0.44), "size": Vector2(58, 46),
		"hp": 150, "speed": 300.0, "decor": "", "flying": true,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [0.0, 99999.0], "jump": 0.0, "melee": 12, "abilities": {"dive": 3.5, "stone_skin": 9.0},
	},
	"executioner": {
		"name": "Палач", "color": Color(0.80, 0.62, 0.50), "size": Vector2(66, 88),
		"hp": 400, "speed": 190.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [60.0, 140.0], "jump": 0.05, "swing": 28, "stagger": 0.3,
		"abilities": {"swing": 2.6, "anchor_pull": 9.0, "slam": 7.0},
	},
	"dark_lord": {
		"name": "Тёмный Лорд", "color": Color(0.21, 0.19, 0.23), "size": Vector2(120, 200),
		"hp": 3600, "speed": 200.0, "decor": "", "boss": true, "eye": Color(1.0, 0.55, 0.15), "far_brain": true,
		"phase2_hp": 2800, "phase2_name": "Тёмный Лорд — истинный облик",
		"phase3_hp": 2600, "phase3_hand_hp": 340,
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [80.0, 320.0], "jump": 0.0, "swing": 30,
		"abilities": {"swing": 2.2, "dark_wave": 6.0, "shadow_dash": 8.0, "dark_orbs": 7.0, "eclipse": 24.0, "summon": 26.0},
		"hint": "Тёмный Лорд рассекает воздух волнами тьмы — перепрыгивай их! Во время Затмения видны только его глаза: следи за ними.",
		"hint2": "Истинный облик: метеоры с неба, столбы адского пламени и чёрная дыра. После чёрной дыры Лорд выдыхается — камень в груди гаснет, и урон по нему двойной!",
		"hint3": "Воплощение Тьмы: тень на полу — туда упадёт кулак, после удара волна по полу — перепрыгни. Сломай обе руки — голова опустится к полу, и урон по ней двойной!",
	},
	# ----- Союзники новых легенд (призываются, в волнах не встречаются) -----
	"skel_archer": {
		"name": "Скелет-лучник", "color": Color(0.90, 0.88, 0.80), "size": Vector2(38, 58),
		"hp": 40, "speed": 280.0, "decor": "",
		"gun": [850.0, 9, 0.0, 0.9, 7.0], "clip": 4, "reload": 1.8, "range": 950.0,
		"keep": [300.0, 600.0], "jump": 0.2, "abilities": {},
	},
	"sapling": {
		"name": "Лесное деревце", "color": Color(0.55, 0.40, 0.22), "size": Vector2(32, 42),
		"hp": 30, "speed": 360.0, "decor": "",
		"gun": [0.0, 0, 0.0, 99.0, 0.0], "clip": 1, "reload": 99.0, "range": 0.0,
		"keep": [20.0, 40.0], "jump": 0.3, "melee": 6, "abilities": {},
	},
}

# Кого призывают боссы и некромант
const SUMMONS := {"chief": "goblin", "treant": "goblin", "necromancer": "skeleton",
		"spider_queen": "spider", "skeleton_king": "skel_sword", "irida": "shardling",
		"sergeant": "minion", "ataman": "bandit_thug", "beastmaster": "lion", "colossus": "fighter",
		"scarecrow": "crow", "witch": "crow", "bog_lord": "frogman",
		"jotun": "snow_wolf", "storm_lord": "ball_lightning", "cerberus": "fire_imp", "dark_lord": "dark_knight"}

# Кто где встречается (для бестиария)
const LOCATIONS := {
	"forest": ["minion", "imp", "minion_archer", "minion_shield", "sergeant"],
	"village": ["bandit_thug", "bandit_shuriken", "bandit_kunai", "bandit_torch", "bandit_bola", "bandit_brute", "ataman"],
	"jungle": ["goblin", "sneak", "bomber", "shaman", "brute", "chief", "treant", "totem"],
	"caves": ["skeleton", "skel_sword", "skel_thrower", "necromancer", "bat", "spider", "spider_queen", "skeleton_king"],
	"deep": ["kobold_miner", "kobold_bomber", "gem_beetle", "cart_rider", "ruby_golem", "gem_shaman", "baron_gryz",
			"shardling", "prismatic", "crystal_guard", "mirror_double", "resonator", "crystal_moth", "irida"],
	"colosseum": ["fighter", "thrower", "slinger", "retiarius", "murmillo", "lion", "beastmaster", "sagittarius",
			"gladiator", "colossus"],
	"eerie": ["ghoul", "scarecrow", "crow", "wisp", "deadwood", "witch"],
	"swamp": ["bogman", "frogman", "leech", "mosquito", "drowned", "bog_lord"],
	"ice": ["snow_wolf", "frost_archer", "yeti", "ice_wraith", "frost_knight", "jotun"],
	"storm": ["storm_acolyte", "temple_guard", "harpy", "ball_lightning", "thunder_priest", "storm_lord"],
	"lava": ["fire_imp", "magma_blob", "magma_blob_s", "salamander", "obsidian_golem", "ash_walker", "fire_cultist", "cerberus"],
	"throne": ["dark_knight", "warlock", "shade", "gargoyle", "executioner", "dark_lord"],
}

# Описания для бестиария
const LORE := {
	"ghoul": "Серый голодный упырь. Прыгает издалека и рвёт когтями. Поодиночке не страшен, стаей — очень.",
	"scarecrow": "Пугало, в которое вселилось что-то злое. Машет серпом и криком созывает воронов.",
	"crow": "Чёрный ворон Жуткого леса. Кружит над головой и пикирует, целясь в глаза.",
	"wisp": "Блуждающий огонёк: висит в воздухе и пускает зелёные шары огня, которые доворачивают на цель.",
	"deadwood": "Ожившее мёртвое дерево. Медленно бредёт, швыряет сучья и пускает корни из-под земли.",
	"witch": "Ведьма Полынь, хозяйка Жуткого леса. Проклинает землю, швыряет склянки с ядом, исчезает в стае воронов.",
	"bogman": "Ком болотной грязи с горящими глазами. Кидается грязью — кого заляпает, тот вязнет.",
	"frogman": "Жаболюд с острогой. Прыгает далеко, а длинным языком подтягивает добычу к себе.",
	"leech": "Пиявка ползёт по грязи и присасывается: пьёт кровь и лечит себя.",
	"mosquito": "Комариный рой. Мелкий, быстрый, кусачий — пикирует целой тучей.",
	"drowned": "Утопленник с якорем на цепи. Забрасывает якорь и тянет к себе, бьёт тяжело.",
	"bog_lord": "Трясинный Владыка — древняя тварь из глубины болота. Ныряет в трясину, гонит волны грязи, выпускает ядовитый газ.",
	"minion": "Рядовой приспешник Тёмного лорда в дырявом капюшоне. Ржавый нож, никакой выучки — берёт числом.",
	"imp": "Мелкий бес с рожками. Шустро скачет и кусается, но рассыпается от пары попаданий.",
	"minion_archer": "Приспешник с коротким луком. Держится подальше и стреляет тёмными стрелами.",
	"minion_shield": "Прикрывается щитом из старой двери: спереди его почти не пробить. Зайди сбоку или сзади!",
	"sergeant": "Десятник шайки приспешников. Громко орёт, лупит дубиной по земле и зовёт своих на подмогу.",
	"bandit_thug": "Обычный бандит с дубинкой. Ничего особенного — кроме того, что их много.",
	"bandit_shuriken": "Метает сюрикены прямо в цель, а иногда сразу три веером.",
	"bandit_kunai": "Кидает кунаи, прячется в дыму и вдруг оказывается у тебя за спиной.",
	"bandit_torch": "Швыряет бутылки с горючей смесью — земля горит ещё несколько секунд. Не стой в огне!",
	"bandit_bola": "Бросает болас: опутанный еле двигается и не может прыгать, а ловчий уже рядом с ножом.",
	"bandit_brute": "Огромный вышибала из таверны. Бьёт кулачищем по земле так, что всех отбрасывает.",
	"ataman": "Главарь бандитов, напавших на деревню. Крутится вихрем с огромным топором и катит бочки с порохом.",
	"beastmaster": "Укротитель зверей Колизея. Хлещет кнутом, рыком пугает и выпускает львов.",
	"sagittarius": "Лучник-ветеран. Стрелы летят далеко и быстро, а залпом с неба он накрывает целую площадку.",
	"fighter": "Ветеран арены: лёгкий доспех, короткий меч, маленький щит. Резким выпадом достаёт издалека.",
	"thrower": "Без доспехов — зато быстрый. Метает копья по дуге, а иногда сразу пять веером.",
	"slinger": "Стрелок арены с пращой. Камни летят быстро и далеко, иногда сразу три подряд.",
	"retiarius": "Боец с сетью и трезубцем. Запутанный в сети враг еле двигается — и тут трезубец довершает дело.",
	"murmillo": "Тяжёлый гладиатор с огромным щитом. Спереди почти неуязвим, а ударом щита оглушает.",
	"lion": "Голодный зверь из подвалов Колизея. Прыгает издалека, а от его рыка всё вокруг замирает.",
	"gladiator": "Любимец публики. Разбегается напролом, крутится вихрем с мечом и бросает веер копий. О стену бьётся головой — и тогда беззащитен.",
	"colossus": "Чудовищная живая крепость — хозяин Колизея. Спереди не пробить, бьёт волной по земле, подтягивает цепью, а раненый — раскаляется добела. Говорят, повергнуть его мало: в груди у Колосса бьётся огненное сердце.",
	"goblin": "Обычный житель джунглей с копьём. Поодиночке слаб, толпой опасен.",
	"sneak": "Тихий охотник в капюшоне. Прячется за дымом и кусает исподтишка.",
	"bomber": "Обожает всё, что взрывается. Носит сумку бомб и не боится ими делиться.",
	"shaman": "Знахарь племени. Лечит сородичей и напускает дым. Бей его первым!",
	"brute": "Самый большой гоблин в деревне. Бьёт кулаками по земле так, что трясётся всё вокруг.",
	"chief": "Вождь гоблинов. Боевым кличем лечит и ускоряет своих, зовёт подмогу.",
	"treant": "Древний страж джунглей. Пока стоят Тотемы жизни, его не ранить. За бой тотемы вырастают трижды: один, три и четыре.",
	"totem": "Резной столб, питающий Энта силой леса. Пока стоит хоть один — Энт неуязвим.",
	"skeleton": "Просто кости, без оружия и доспехов. Хрупкий — рассыпается от пары выстрелов.",
	"skel_sword": "Страж древнего королевства. Ржавый доспех и меч, который всё ещё режет.",
	"skel_thrower": "Скелет в истлевшей кожаной куртке. Метает кости — свои и чужие.",
	"necromancer": "Тёмный колдун в робе. Когда его союзники падают, поднимает новых мертвецов. Вблизи бьёт посохом.",
	"bat": "Кружит под сводами пещеры и пикирует на всё живое.",
	"spider": "Быстрый пещерный паук. Плюётся паутиной и прыгает на добычу.",
	"spider_queen": "Хозяйка глубинных нор. Опутывает паутиной, прыгает и выводит паучат.",
	"skeleton_king": "Повелитель царства мёртвых. Веками ждал на троне достойного противника.",
	"kobold_miner": "Кобольд с киркой. Прорубает путь сквозь камень прямо к тебе — за стенкой не спрятаться.",
	"kobold_bomber": "Любит динамит. Видно, куда упадёт шашка, и пока горит фитиль, есть время отбежать.",
	"gem_beetle": "Панцирь из самоцветов спереди почти не пробить. Сворачивается в шар и катится. Если разбить, роняет золото.",
	"cart_rider": "Разгоняется на вагонетке. Перепрыгни! Сбитая тележка катится дальше сама.",
	"ruby_golem": "Каменный великан с рубиновым сердцем. Пока сердце цело, урон по нему вдвое меньше — оглуши, и оно треснет.",
	"gem_shaman": "Кобольд-гранильщик. Покрывает своих самоцветной коркой, которая принимает удары. Бей его первым!",
	"baron_gryz": "Хозяин шахты на буровой машине. Ныряет под землю, бросает связки динамита и зовёт вагонетки. Котёл сзади — его слабое место.",
	"shardling": "Ходячая друза. Разбей — и она расколется на два осколка, а те — на крошки.",
	"prismatic": "Парящая призма. Сначала видна тонкая линия прицела — потом бьёт луч. Луч отражается от зеркальных кристаллов.",
	"crystal_guard": "Страж с зеркальным щитом: спереди почти неуязвим и отбивает выстрелы обратно. Заходи со спины!",
	"mirror_double": "Отражение героя, который с ним сражается: та же внешность и та же атака, только слабее.",
	"resonator": "Кристальный камертон. Его гул ломает кристаллы вокруг и оглушает всех рядом. Не стой близко!",
	"crystal_moth": "Порхает под сводами и сыплет сверкающую пыльцу — в её облаке двигаешься медленнее.",
	"irida": "Хранительница Хрустального Сердца. Режет лучами, растит кристальные шипы, создаёт отражения себя и рассыпается вихрем осколков.",
	"snow_wolf": "Серебристый волк ледяных перевалов. Прыгает издалека, а воем подгоняет стаю — вместе волки бегут быстрее.",
	"frost_archer": "Лучник в белой шубе. Его стрелы обдают инеем, а залпом из трёх ледяных стрел он накрывает целую площадку.",
	"yeti": "Косматый великан снегов. Швыряет снежки размером с бочку — облепленный снегом еле двигается.",
	"ice_wraith": "Дух замёрзшего путника. Парит над тропой и пускает ледяные осколки, которые доворачивают на цель.",
	"frost_knight": "Рыцарь, вмёрзший в собственные латы. Ледяной щит спереди почти не пробить, а удар о землю покрывает всех инеем.",
	"jotun": "Ётун Стужа — древний ледяной великан, хозяин перевала. Дышит морозом, обрушивает ливень сосулек и одевается в ледяную броню.",
	"storm_acolyte": "Послушник Храма шторма. Мечет искры, а иногда пускает разряд, который перескакивает с врага на врага.",
	"temple_guard": "Страж храма с глефой и бронзовым щитом. Спереди крепок, резким выпадом достаёт издалека.",
	"harpy": "Полуптица-полуженщина. Пикирует сверху и осыпает веером острых перьев.",
	"ball_lightning": "Шаровая молния, что живёт в грозовых тучах храма. Летит к тебе и взрывается разрядом — сбей её издалека!",
	"thunder_priest": "Верховный жрец грома. Указывает посохом — и через миг в отмеченное место бьёт молния. Лечит своих.",
	"storm_lord": "Громовник, Владыка Бури — повелитель Храма шторма. Парит над землёй, мечет цепные молнии, поднимает смерчи и копит Перегрузку, от которой спасают только громоотводы.",
	"fire_imp": "Огненный бес лавовых просторов. Шустрый, прыгучий и бросается горящими склянками.",
	"magma_blob": "Капля живой лавы. Разбей — и она расплескается на две маленьких капли.",
	"magma_blob_s": "Маленькая капля лавы. Быстрая, обжигает при касании.",
	"salamander": "Огненная ящерица. Купается в лаве, прыгает на добычу и дышит пламенем.",
	"obsidian_golem": "Великан из чёрного стекла с лавовым сердцем. Швыряет комья лавы и бьёт оземь так, что трясётся всё вокруг.",
	"ash_walker": "Сгоревший путник, оживлённый пламенем. Падая, рассыпается облаком раскалённого пепла — не стой рядом!",
	"fire_cultist": "Культист Тёмного лорда. Бросает огненные шары и призывает метеор в огненный круг.",
	"cerberus": "Трёхголовый страж лавовых врат. Левая голова плюёт огнём, средняя кусает, правая воет и зовёт огненных бесов.",
	"dark_knight": "Рыцарь личной гвардии Тёмного лорда. Чёрные латы спереди почти не пробить, а разбегается он напролом.",
	"warlock": "Колдун тёмного двора. Пускает сгустки тьмы, которые сами находят цель, и проклинает землю под ногами.",
	"shade": "Тень без лица. Растворяется в дыму и появляется прямо у тебя за спиной.",
	"gargoyle": "Каменная горгулья с карнизов зала. Пикирует сверху, а когда каменеет — её не ранить.",
	"executioner": "Палач Тёмного лорда. Забрасывает цепь с крюком, подтягивает к себе и бьёт огромным топором.",
	"dark_lord": "Тёмный Лорд — один из тех, кто держит мир во тьме, и тот, чьи приспешники встретили тебя ещё на Лесной тропе. Рассекает воздух волнами тьмы и гасит свет в зале. Повергнутый, он встаёт снова — на огненных крыльях, а потом отдаёт себя тьме целиком. Говорят, камень в его груди — его истинное сердце.",
}

# Волны (на волнах с боссом выходит только сам босс — без подкрепления):
#   1–5   — Лесная тропа, приспешники Тёмного лорда, на 5-й мини-босс Десятник;
#   6–10  — Окраина деревни, бандиты, на 10-й босс Атаман;
#   11–15 — Джунгли днём, гоблины, на 15-й мини-босс Вождь;
#   16–20 — Джунгли ночью, на 20-й босс Древний Энт;
#   21–25 — Пещеры с факелами, на 25-й мини-босс Паучья королева;
#   26–30 — Царство скелетов, на 30-й босс Король скелетов;
#   31–35 — Драгоценные пещеры, кобольды, на 35-й мини-босс Барон Грызь;
#   36–40 — Кристальные пещеры, на 40-й босс Ирида;
#   41–45 — Колизей днём, ветераны арены, на 45-й мини-босс Гладиатор;
#   46–50 — Колизей ночью, на 50-й босс Колосс;
#   51–55 — Жуткий лес, на 55-й мини-босс Ведьма Полынь;
#   56–60 — Болото, на 60-й босс Трясинный Владыка;
#   61–65 — Ледяная тропа, на 65-й мини-босс Ётун Стужа;
#   66–70 — Храм шторма, на 70-й босс Громовник, Владыка Бури;
#   71–75 — Лавовые просторы, на 75-й мини-босс Цербер;
#   76–80 — Тронный зал Тёмного лорда, на 80-й — сам Тёмный Лорд.
# Солдаты, танки, артиллеристы и пробойщики остались в проекте — для будущей арены.
const WAVES := [
	{"minion": 2},
	{"minion": 2, "imp": 2},
	{"minion": 2, "minion_archer": 1, "imp": 1},
	{"minion": 2, "minion_archer": 2, "minion_shield": 1},
	{"sergeant": 1},
	{"bandit_thug": 3},
	{"bandit_thug": 2, "bandit_shuriken": 2},
	{"bandit_thug": 2, "bandit_kunai": 2, "bandit_torch": 1},
	{"bandit_brute": 1, "bandit_bola": 1, "bandit_shuriken": 1, "bandit_kunai": 1, "bandit_torch": 1},
	{"ataman": 1},
	{"goblin": 3},
	{"goblin": 3, "sneak": 2},
	{"goblin": 2, "bomber": 2, "sneak": 1},
	{"goblin": 3, "shaman": 1, "sneak": 2},
	{"chief": 1},
	{"goblin": 4, "sneak": 2, "brute": 1},
	{"bomber": 3, "shaman": 1, "goblin": 3},
	{"brute": 2, "sneak": 3, "goblin": 2},
	{"brute": 2, "bomber": 2, "shaman": 2, "goblin": 3},
	{"treant": 1},
	{"skeleton": 4},
	{"skeleton": 3, "skel_thrower": 2},
	{"skel_sword": 2, "skeleton": 2, "bat": 2},
	{"skel_sword": 2, "skel_thrower": 2, "spider": 2},
	{"spider_queen": 1},
	{"skel_sword": 3, "bat": 3},
	{"necromancer": 1, "skeleton": 3, "skel_thrower": 2},
	{"spider": 3, "bat": 3, "skel_sword": 2},
	{"necromancer": 2, "skel_sword": 2, "skel_thrower": 2, "bat": 2},
	{"skeleton_king": 1},
	{"kobold_miner": 3, "kobold_bomber": 1},
	{"kobold_miner": 2, "gem_beetle": 2, "kobold_bomber": 1},
	{"cart_rider": 1, "kobold_miner": 2, "gem_shaman": 1, "gem_beetle": 1},
	{"ruby_golem": 1, "kobold_bomber": 2, "gem_shaman": 1, "cart_rider": 1, "kobold_miner": 2},
	{"baron_gryz": 1},
	{"shardling": 3, "prismatic": 1},
	{"crystal_guard": 1, "shardling": 2, "crystal_moth": 2},
	{"mirror_double": 2, "prismatic": 1, "resonator": 1, "shardling": 1},
	{"crystal_guard": 2, "resonator": 1, "crystal_moth": 2, "mirror_double": 1, "prismatic": 1},
	{"irida": 1},
	{"fighter": 3, "thrower": 2},
	{"fighter": 2, "slinger": 2, "retiarius": 1, "thrower": 1},
	{"murmillo": 1, "fighter": 2, "sagittarius": 2},
	{"retiarius": 2, "lion": 2, "slinger": 2, "murmillo": 1},
	{"gladiator": 1},
	{"beastmaster": 1, "lion": 1, "fighter": 2, "sagittarius": 1},
	{"murmillo": 2, "retiarius": 2, "thrower": 2},
	{"sagittarius": 2, "beastmaster": 1, "fighter": 2, "slinger": 2},
	{"murmillo": 2, "lion": 2, "retiarius": 1, "sagittarius": 2, "thrower": 1},
	{"colossus": 1},
	{"ghoul": 3, "crow": 2},
	{"ghoul": 2, "scarecrow": 1, "wisp": 2},
	{"deadwood": 1, "ghoul": 2, "crow": 3},
	{"scarecrow": 2, "deadwood": 1, "wisp": 2, "ghoul": 2},
	{"witch": 1},
	{"bogman": 2, "leech": 3},
	{"frogman": 2, "bogman": 2, "mosquito": 2},
	{"drowned": 1, "frogman": 2, "leech": 2, "wisp": 1},
	{"drowned": 2, "bogman": 2, "mosquito": 2, "frogman": 1},
	{"bog_lord": 1},
	{"snow_wolf": 3, "frost_archer": 1},
	{"snow_wolf": 2, "frost_archer": 2, "ice_wraith": 1},
	{"yeti": 1, "frost_knight": 1, "snow_wolf": 2, "ice_wraith": 1},
	{"frost_knight": 2, "yeti": 1, "frost_archer": 2, "ice_wraith": 2},
	{"jotun": 1},
	{"storm_acolyte": 2, "harpy": 2},
	{"temple_guard": 2, "storm_acolyte": 1, "ball_lightning": 2},
	{"thunder_priest": 1, "temple_guard": 1, "harpy": 2, "storm_acolyte": 2},
	{"temple_guard": 2, "thunder_priest": 2, "ball_lightning": 2, "harpy": 1},
	{"storm_lord": 1},
	{"fire_imp": 3, "magma_blob": 2},
	{"salamander": 2, "fire_imp": 2, "ash_walker": 1},
	{"obsidian_golem": 1, "fire_cultist": 1, "magma_blob": 2, "salamander": 1},
	{"obsidian_golem": 1, "ash_walker": 2, "fire_cultist": 2, "fire_imp": 2, "magma_blob": 1},
	{"cerberus": 1},
	{"dark_knight": 2, "shade": 2},
	{"warlock": 1, "dark_knight": 2, "gargoyle": 2},
	{"executioner": 1, "shade": 2, "warlock": 1, "gargoyle": 1},
	{"executioner": 1, "dark_knight": 2, "warlock": 2, "shade": 2, "gargoyle": 1},
	{"dark_lord": 1},
]

# На какой волне противник появляется впервые
static func first_wave(kind: String) -> int:
	if kind == "totem":
		return 20
	for i in WAVES.size():
		if WAVES[i].has(kind):
			return i + 1
	for k in TYPES:                         # осколок / капля — там же, где и тот, кто раскалывается
		if TYPES[k].get("split", "") == kind:
			return first_wave(k)
	return 0

# Урон для бестиария: что сильнее — выстрел, удар оружием или укус
static func damage_of(kind: String) -> int:
	var t: Dictionary = TYPES[kind]
	var d := 0
	if t.get("range", 800.0) > 0.0:
		d = t["gun"][1]
	d = maxi(d, t.get("melee", 0))
	if t["abilities"].has("swing"):
		d = maxi(d, t.get("swing", 20))
	return d

# Список ботов волны вперемешку (боссы — в конце очереди, после разминки)
static func wave_list(n: int) -> Array:
	var res: Array = []
	var bosses: Array = []
	var w: Dictionary = WAVES[n - 1]
	for kind in w:
		for i in w[kind]:
			if TYPES[kind].get("boss", false):
				bosses.append(kind)
			else:
				res.append(kind)
	res.shuffle()
	return res + bosses

static func is_boss(kind: String) -> bool:
	return TYPES[kind].get("boss", false)

# Создаёт бота. С каждой волной боты чуть прочнее.
static func create(kind: String, wave: int, pos: Vector2, target: Player, map_w: float) -> Player:
	var t: Dictionary = TYPES[kind]
	var p := Player.new()
	p.prefix = "bot"
	p.index = 1
	p.team = 1
	p.is_bot = true
	p.respawn = false
	p.target = target
	p.spawn = pos
	p.facing = 1 if target.global_position.x > pos.x else -1
	p.map_w = map_w
	p.color = t["color"]
	p.team_color = Color(1.0, 0.3, 0.3)
	p.body_size = t["size"]
	p.decor = t["decor"]
	p.eye_color = t.get("eye", Color.BLACK)
	p.max_hp = int(t["hp"] * (1.0 + 0.02 * (wave - 1)))      # с каждой волной чуть прочнее
	p.speed = t["speed"]
	if p.speed <= 0.0:
		p.jump_force = 0.0          # тотем стоит на месте
	var g: Array = t["gun"]
	p.bullet_speed = g[0]
	p.bullet_damage = g[1]
	p.bullet_blast = g[2]
	p.fire_cooldown = g[3]
	p.bullet_size = g[4]
	p.clip_size = t["clip"]
	p.reload_time = t["reload"]
	p.keep_min = t["keep"][0]
	p.keep_max = t["keep"][1]
	p.jumpiness = t["jump"]
	p.melee_dmg = t.get("melee", 0)
	p.bot_abilities = t["abilities"].duplicate()
	p.mortar_count = t.get("mortars", 5)
	p.abilities = ["", "", ""]
	p.ult = "quake" if t["abilities"].has("quake") else ""
	p.bar_lift = {"gladiator": 14.0, "colossus": 32.0, "chief": 26.0, "treant": 70.0, "tank": 6.0,
			"jotun": 30.0, "storm_lord": 40.0, "dark_lord": 40.0}.get(kind, 0.0)
	p.gun_kind = t.get("gun_kind", "")
	p.payload = t.get("payload", "")
	p.shoot_range = t.get("range", 800.0)
	p.front_armor = t.get("front_armor", 0.0)
	p.turn_time = t.get("turn_time", 0.0)
	if t.has("quake_stun"):
		p.set_meta("quake_stun", t["quake_stun"])
	p.flying = t.get("flying", false)
	p.swing_dmg = t.get("swing", 20)
	if SUMMONS.has(kind):
		p.set_meta("summons", SUMMONS[kind])
	p.set_meta("kind", kind)
	p.back_mult = t.get("back_mult", 1.0)
	if t.has("stagger"):
		p.stagger_max = p.max_hp * float(t["stagger"])
	if kind == "mirror_double":
		_mirror_of(p, target)
	p.bullet_style = t.get("bullet_style", "")
	if t.get("raid_brain", false):
		var rb := RaidBrain.new()
		rb.p = p
		rb.kind = kind
		p.add_child(rb)
	if t.get("brain", false):
		var br := DeepBrain.new()
		br.p = p
		br.kind = kind
		p.add_child(br)
	if t.get("far_brain", false):
		var fb := FarBrain.new()
		fb.p = p
		fb.kind = kind
		p.add_child(fb)
	if t.get("fireproof", false):
		p.set_meta("fireproof", true)               # огненные твари: лава и огонь им не страшны
	if t.has("chill_shots"):
		p.set_meta("chill_shots", t["chill_shots"])
	if t.has("burn_shots"):
		p.set_meta("burn_shots", t["burn_shots"])
	if kind == "shade":
		p.modulate = Color(1, 1, 1, 0.82)
	return p

# Зеркальный двойник: внешность и обычная атака того, с кем он сражается
static func _mirror_of(p: Player, target: Player) -> void:
	if target == null or not is_instance_valid(target):
		return
	p.rig_kind = target.rig_kind if target.rig_kind != "" else "grunt"
	p.rig_spec = target.rig_spec.duplicate()
	p.modulate = Color(0.75, 0.95, 1.25, 0.82)
	var melee: bool = target.kit != null and target.kit.hero in ["smith", "samurai", "champion"]
	if melee:
		p.bot_abilities = {"swing": 1.9}
		p.swing_dmg = 12
		p.keep_min = 50.0
		p.keep_max = 100.0
		p.shoot_range = 0.0
	else:
		p.bullet_speed = maxf(600.0, target.bullet_speed)
		p.bullet_damage = maxi(4, int(target.bullet_damage * 0.6))
		p.fire_cooldown = maxf(0.45, target.fire_cooldown * 1.4)
