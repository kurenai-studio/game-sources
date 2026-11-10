class_name Looks
extends RefCounted
## Everything a hot dog can wear, for the dressing room: the choices on each
## row and their names. (The pictures are in assets/art/dogs and face.)

const CHOICES := {
	"nation": ["ngc", "usa", "ger", "den", "kor", "jpn", "gbr", "eng", "sco", "wal", "nir", "irl", "aus", "mex", "bra",
		"fra", "chi", "cze", "jam"],
	"sausage": ["frank", "brat", "red", "banger", "cumberland", "lorne", "glamorgan", "chorizo", "bacon", "corn", "tako"],
	"bun": ["soft", "poppy", "sesame", "floury", "farl", "crusty", "baguette", "white", "tube", "flat", "bolillo", "none"],
	"band": ["red", "white", "blue", "navy", "yellow", "green", "black", "gold", "pink", "teal", "orange", "purple", "sky", "lime"],
	"eyes": ["look", "front", "wide", "sleepy"],
	"hair": ["none", "flattop", "curly", "spikes"],
	"specs": ["none", "shades", "neon", "round"],
	"tache": ["none", "tache", "handlebar"],
}
const TOPPINGS := ["mustard", "ketchup", "brown_sauce", "brown_mustard", "relish", "pickle", "tomato", "crispy_onion",
	"onion", "remoulade", "avocado", "mayo", "cheese", "potato_sticks", "corn_peas", "jalapeno", "beans",
	"potato_cubes", "nori", "sauerkraut", "leek", "egg"]
const ROWS := [["NATION", "nation"], ["SAUSAGE", "sausage"], ["BUN", "bun"], ["BAND", "band"], ["STRIPE", "stripe"],
	["EYES", "eyes"], ["HAIR", "hair"], ["SHADES", "specs"], ["TACHE", "tache"]]
const NAMES := {
	"ngc": "Night Giraffe", "frank": "Frankfurter", "brat": "Bratwurst", "red": "Red Pølse", "banger": "Banger",
	"chorizo": "Chorizo", "bacon": "Bacon-wrapped", "corn": "Corn Dog", "tako": "Octopus Wiener", "soft": "Soft Bun",
	"poppy": "Poppy Seed", "sesame": "Sesame", "crusty": "Brötchen", "baguette": "Baguette", "white": "White Bread",
	"tube": "Rohlík Roll", "flat": "Flatbread", "bolillo": "Bolillo", "none": "None", "cumberland": "Cumberland",
	"lorne": "Square Lorne", "glamorgan": "Glamorgan", "floury": "Floury Bap", "farl": "Soda Farl", "look": "Keen", "front": "Friendly",
	"wide": "Wide-eyed", "sleepy": "Sleepy", "flattop": "Flat Top", "curly": "80s Perm", "spikes": "Spikes",
	"shades": "Wayfarers", "neon": "Neon Shades", "round": "Round Specs", "tache": "Moustache", "handlebar": "Handlebar",
}

const TOPPING_NAMES := {
	"none": "None", "mustard": "Mustard", "ketchup": "Ketchup", "brown_sauce": "Brown Sauce",
	"brown_mustard": "Brown Mustard", "relish": "Relish", "pickle": "Pickle", "tomato": "Tomato",
	"crispy_onion": "Crispy Onions", "onion": "Onions", "remoulade": "Remoulade", "avocado": "Avocado",
	"mayo": "Mayo", "cheese": "Cheese", "potato_sticks": "Potato Sticks", "corn_peas": "Corn & Peas",
	"jalapeno": "Jalapeños", "beans": "Beans", "potato_cubes": "Potato Cubes", "nori": "Nori",
	"sauerkraut": "Sauerkraut", "leek": "A Leek", "egg": "Fried Egg",
}
