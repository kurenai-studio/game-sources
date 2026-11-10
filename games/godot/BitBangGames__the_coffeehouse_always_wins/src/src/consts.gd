extends Node

const SCREEN_SIZE: Vector2i = Vector2i(0b101000000, 0b11001000)
const SPEED: int = 0b10000000
const MAX_CUPS_BASE: int = 0b100
const MAX_ROUND: int = 0b1000

const BEANS_AMOUNT: int = 0b10
const INGRS_AMOUNT: int = 0b100
const INVENTORY_SIZE: int = BEANS_AMOUNT + INGRS_AMOUNT
const SELECTOR_BASE_POS: Vector2i = Vector2i(0b1100, 0b1100)

const SAVE_PATH: String = "user://save.res"
const SETTINGS_PATH: String = "user://settings.conf"

enum State {
	TITLE_STATE,
	GAME_STATE,
	INVENTORY_STATE,
	DIALOGUE_STATE,
	BREWING_STATE,
	BREWED_STATE,
	END_STATE,
}

enum Item {
	NONE,

	LIGHT_ROAST, # +32
	MEDIUM_ROAST, # +16
	DARK_ROAST, # +8
	DECAF, # +0
	UNROASTED, # +min

	MILK, # -2
	CREAM, # -8
	HALF_AND_HALF, # -4
	SUGAR, # -12
	SWEETENER, # -6
	HONEY, # -16
	ALMOND_MILK, # +2
	SOY_MILK, # +- 8 (random)
	TEA, # -24
	CHOCOLATE_MILK, # -(4*round)
	BANANA, # +1 cup for rest of run
}

const ITEM_DESCS: PackedStringArray = [
	"",

	"Light Roast (+32)",
	"Medium Roast (+16)",
	"Dark Roast (+8)",
	"Decaf (+0)",
	"Unroasted (+min)",

	"Milk (-2)",
	"Cream (-8)",
	"Half & Half (-4)",
	"Sugar (-12)",
	"Sweetener (-6)",
	"Honey (-16)",
	"Almond Milk (+2)",
	"Soy Milk (+ or - 8)",
	"Tea (-24)",
	"Choc Milk (-4*round)",
	"Banana (+1 cup)",
]

const BEAN_BASE_DECK: PackedByteArray = [
	Item.LIGHT_ROAST,
	Item.LIGHT_ROAST,
	Item.LIGHT_ROAST,
	Item.LIGHT_ROAST,
	Item.LIGHT_ROAST,
	Item.LIGHT_ROAST,
	Item.LIGHT_ROAST,
	Item.LIGHT_ROAST,
	Item.MEDIUM_ROAST,
	Item.MEDIUM_ROAST,
	Item.MEDIUM_ROAST,
	Item.MEDIUM_ROAST,
	Item.MEDIUM_ROAST,
	Item.MEDIUM_ROAST,
	Item.MEDIUM_ROAST,
	Item.MEDIUM_ROAST,
	Item.MEDIUM_ROAST,
	Item.MEDIUM_ROAST,
	Item.MEDIUM_ROAST,
	Item.MEDIUM_ROAST,
	Item.DARK_ROAST,
	Item.DARK_ROAST,
	Item.DARK_ROAST,
	Item.DARK_ROAST,
	Item.DARK_ROAST,
	Item.DARK_ROAST,
	Item.DARK_ROAST,
	Item.DARK_ROAST,
	Item.DECAF,
	Item.DECAF,
	Item.DECAF,
	Item.UNROASTED,
]

const INGR_BASE_DECK: PackedByteArray = [
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.MILK,
	Item.CREAM,
	Item.CREAM,
	Item.CREAM,
	Item.CREAM,
	Item.CREAM,
	Item.CREAM,
	Item.CREAM,
	Item.CREAM,
	Item.HALF_AND_HALF,
	Item.HALF_AND_HALF,
	Item.HALF_AND_HALF,
	Item.HALF_AND_HALF,
	Item.HALF_AND_HALF,
	Item.HALF_AND_HALF,
	Item.HALF_AND_HALF,
	Item.HALF_AND_HALF,
	Item.HALF_AND_HALF,
	Item.HALF_AND_HALF,
	Item.HALF_AND_HALF,
	Item.HALF_AND_HALF,
	Item.SUGAR,
	Item.SUGAR,
	Item.SUGAR,
	Item.SUGAR,
	Item.SWEETENER,
	Item.SWEETENER,
	Item.SWEETENER,
	Item.SWEETENER,
	Item.SWEETENER,
	Item.SWEETENER,
	Item.HONEY,
	Item.HONEY,
	Item.HONEY,
	Item.ALMOND_MILK,
	Item.ALMOND_MILK,
	Item.ALMOND_MILK,
	Item.ALMOND_MILK,
	Item.ALMOND_MILK,
	Item.ALMOND_MILK,
	Item.SOY_MILK,
	Item.SOY_MILK,
	Item.SOY_MILK,
	Item.SOY_MILK,
	Item.SOY_MILK,
	Item.TEA,
	Item.TEA,
	Item.CHOCOLATE_MILK,
	Item.BANANA,
]

const MANAGERS_NOTES: Array[PackedStringArray] = [
	[
		"Welcome to the Sundollars Coffee team! It's great to have you on board.",
		"We've been providing endless joy and caffeine to the American public for over 50 years.",
		"Since you're new here, just kick back and make yourself at home.",
		"But not too much.",
		"If you miss your half-hour goal even once, you're fired. I'm serious.",
		"And judging by your resume, good luck finding anyone else.",
		"Have fun!",
	],

	[
		"Here at Sundollars, we take a very Goldilocksian approach to serving customers.",
		"Their caffeine levels have to be juuuuuuuust right.",
		"If it's too little or too much, it could ruin our reputation.",
		"And their health, I guess.",
		"Feel free to use everything we have in the bean bag and minifridge.",
		"And help yourself to a drink every once in a while.",
		"You're gonna need it if you're going to say \"Have the best day EVER!\" to each customer.",
		"And you are. Your contract mandates it.",
	],

	[
		"Your shift for today will last from 10-2.",
		"Expect your other shifts to be at the same time.",
		"Each half-hour, you'll have a caffeine quota to meet.",
		"You only got 4 cups at a time, so make use of them.",
		"There might be a way to get more? I'll have to check.",
		"But rest assured you won't be working overtime.",
		"But rest assured you won't be working overtime. Yet.",
	],

	[
		"You might be confused at some of our ingredients. I don't blame you.",
		"Like, who puts tea in coffee? And a banana?",
		"Are we just trying to meet some arbitrary restriction imposed by a higher power?",
		"But I think that's the reason Sundollars has endured so long.",
		"We dare our customers to expect the unexpected.",
		"Put a little kick in their diet, if you know what I mean.",
		"...",
		"No, our coffee is NOT drugged. Put your phone down.",
	],

	[
		"One time, a coffee bean accidentally fell into my shoe.",
		"I would've taken it out, but I was at work and didn't want to make a scene.",
		"So I just left it in and forgot about it.",
		"It might still be in there. It's hard to tell.",
		"I guess there's a lesson to be learned?",
		"Sometimes you should hold on to your ingredients instead of using them right away.",
		"Just not in your shoe.",
		"That's gross.",
		"I'm gross.",
	],

	[
		"We've got 2 working coffee machines. Ideally, they should work very differently.",
		"The drip coffee maker doubles a drink's caffeine level, while the espresso maker halves it.",
		"And believe me, that is exactly how it works. I've done rigorous tests.",
		"Customers have complained that we don't serve iced coffee, which is understandable.",
		"Honestly, we sorta just forgot about it until it was too late.",
		"If anyone asks, just tell them to put ice in regular coffee. It's better than nothing.",
	],

	[
		"If you want to brew a cup just for yourself, go ahead. I won't stop you.",
		"But I must warn you of a side effect.",
		"When you drink a cup, the day might seem to go as normal.",
		"But once in a while, you wake up to find that no time has passed at all.",
		"Seems like it only works once, though.",
		"I have no idea why this happens, but it sure does SAVE you a lot of time and energy.",
		"...I have no idea why I'm writing SAVE like this either.",
		"Maybe I should LOAD up on some decaf.",
	],

	[
		"You may notice you're the only one working behind the counter.",
		"Before you go up to me and complain, just put yourself in my shoes.",
		"A one-bedroom apartment, lined with empty pizza boxes and coffee cups.",
		"A one-bedroom apartment, lined with empty pizza boxes and coffee cups. And the divorce papers.",
		"In the real world you can only trust yourself. Everything, everyone else is expendable.",
		"Oh, I'm sorry, am I bumming you out? Did I perhaps catch you off guard?",
		"At least you're gonna have a loving wife someday.",
		"(note to self: do NOT send this to the employees again you drunk piece of shit)"
	],
]

const TUTORIAL: PackedStringArray = [
	"Today's my first shift at the world-famous Sundollars Coffee. I couldn't be more nervous.",
	"Fortunately, I got very specific instructions.",
	"I can take coffee beans from the bean bag on the left, and ingredients from the minifridge on the right.",
	"Then I can use either the drip coffee maker or espresso machine up front, and pick items to brew.",
	"Each of these items will either increase or decrease my \"caffeine score\".",
	"I need to make at least a certain amount, but less than double that same amount. It's a delicate balance.",
	"They let me drink the coffee myself too, so I can make a \"save point\". Whatever that means.",
	"Failing all else, the manager left a note to help me. He'll probably leave a different one each shift.",
	"It's a lot to remember, but I need this job. Those student loans ain't gonna pay themselves."
]

const SFX_JSON: Dictionary = {
	"sfx_applause": "res://sfx/sfx_applause.wav",
	"sfx_bonk": "res://sfx/sfx_bonk.wav",
	"sfx_brew": "res://sfx/sfx_brew.wav",
	"sfx_ding": "res://sfx/sfx_ding.wav",
	"sfx_drink": "res://sfx/sfx_drink.wav",
	"sfx_lose": "res://sfx/sfx_lose.wav",
	"sfx_select": "res://sfx/sfx_select.wav",
	"sfx_talking": "res://sfx/sfx_talking.wav",
}

const MUSIC_JSON: Dictionary = {
	"mus_coffeehouse": {
		"path": "res://mus/mus_coffeehouse.ogg",
		"loop": 3.75
	},
}
