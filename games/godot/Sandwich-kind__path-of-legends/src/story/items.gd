class_name Items
# ---------- Справочник предметов Истории ----------
# kind: armor (броня и украшения), melee, ranged, ammo, scroll, potion, key
# slot (броня): head, chest, legs, boots, hands, ring, amulet, cape
# sub (оружие): sword, dagger, blunt, greatsword, scythe | bow, pistol, rifle, throw
# stats — прибавки к характеристикам: hp, mana, armor, mres, melee, ranged, int, crit
# rarity: common, uncommon, rare, epic (цвет рамки)
# look — как предмет выглядит на герое (цвета для модели)

const RARITY := {
	"common": Color(0.75, 0.75, 0.75), "uncommon": Color(0.45, 0.9, 0.4),
	"rare": Color(0.35, 0.6, 1.0), "epic": Color(0.8, 0.45, 1.0),
}
const RARITY_NAME := {"common": "Обычный", "uncommon": "Необычный", "rare": "Редкий", "epic": "Эпический"}

const ARMOR_SLOTS := ["head", "chest", "legs", "boots", "hands", "cape", "ring", "amulet"]
const SLOT_NAME := {"head": "Голова", "chest": "Тело", "legs": "Ноги", "boots": "Обувь", "hands": "Руки",
		"cape": "Плащ", "ring": "Кольцо", "amulet": "Амулет"}
const MELEE_SUBS := ["sword", "dagger", "blunt", "greatsword", "scythe"]
const RANGED_SUBS := ["bow", "pistol", "rifle", "throw"]
const SUB_NAME := {"sword": "Мечи", "dagger": "Кинжалы", "blunt": "Дробящее", "greatsword": "Двуручные",
		"scythe": "Косы", "bow": "Луки", "pistol": "Пистолеты", "rifle": "Автоматы", "throw": "Метательное",
		"fist": "Кулаки"}
const STAT_NAME := {"hp": "Здоровье", "mana": "Мана", "armor": "Броня", "mres": "Защита от магии",
		"melee": "Сила удара", "ranged": "Меткость", "int": "Интеллект", "crit": "Шанс крита"}

const DB := {
	# ----- стартовая одежда -----
	"leather_shirt": {"name": "Кожаная рубаха", "kind": "armor", "slot": "chest", "rarity": "common",
			"stats": {"armor": 1}, "desc": "Простая рубаха из грубой кожи. Всё, что у тебя было с собой.",
			"look": {"shirt": Color(0.66, 0.47, 0.30)}},
	"leather_pants": {"name": "Кожаные штаны", "kind": "armor", "slot": "legs", "rarity": "common",
			"stats": {"armor": 1}, "desc": "Потёртые штаны из кожи.",
			"look": {"pants": Color(0.34, 0.26, 0.20)}},
	# ----- броня из сундука -----
	"iron_helm": {"name": "Железный шлем", "kind": "armor", "slot": "head", "rarity": "common",
			"stats": {"armor": 4}, "desc": "Шлем с наносником. Тяжёлый, но надёжный.",
			"look": {"helm": "iron", "helm_color": Color(0.62, 0.64, 0.70)}},
	"chainmail": {"name": "Кольчуга стража", "kind": "armor", "slot": "chest", "rarity": "uncommon",
			"stats": {"armor": 8, "hp": 10}, "desc": "Кольчужная рубаха поверх стёганки. Держит удары мечей.",
			"look": {"shirt": Color(0.42, 0.30, 0.22), "armor_plate": Color(0.60, 0.62, 0.68), "chain": true}},
	"guard_greaves": {"name": "Поножи стража", "kind": "armor", "slot": "legs", "rarity": "common",
			"stats": {"armor": 4}, "desc": "Штаны с железными щитками на коленях.",
			"look": {"pants": Color(0.30, 0.30, 0.36), "knee": Color(0.62, 0.64, 0.70)}},
	"leather_boots": {"name": "Походные сапоги", "kind": "armor", "slot": "boots", "rarity": "common",
			"stats": {"armor": 2, "crit": 0.01}, "desc": "Мягкие сапоги — шаг тише, удар точнее.",
			"look": {"boots": Color(0.32, 0.20, 0.12)}},
	"leather_gloves": {"name": "Перчатки лучника", "kind": "armor", "slot": "hands", "rarity": "uncommon",
			"stats": {"armor": 1, "ranged": 2}, "desc": "Защищают пальцы от тетивы.",
			"look": {"gloves": Color(0.45, 0.30, 0.18)}},
	"traveler_cape": {"name": "Плащ странника", "kind": "armor", "slot": "cape", "rarity": "common",
			"stats": {"mres": 2}, "desc": "Плотный плащ от ветра и чужих чар.",
			"look": {"cape": Color(0.25, 0.35, 0.55)}},
	"copper_ring": {"name": "Медное кольцо", "kind": "armor", "slot": "ring", "rarity": "uncommon",
			"stats": {"mana": 10, "int": 1}, "desc": "На кольце выцарапана руна. От него тепло.", "look": {}},
	"fang_amulet": {"name": "Амулет с клыком", "kind": "armor", "slot": "amulet", "rarity": "rare",
			"stats": {"hp": 15, "melee": 1, "mres": 2}, "desc": "Клык неведомого зверя на кожаном шнурке.", "look": {}},
	# ----- оружие -----
	"short_sword": {"name": "Короткий меч", "kind": "melee", "sub": "sword", "rarity": "common",
			"dmg": 14, "cd": 0.42, "reach": 120.0, "stats": {}, "desc": "Надёжный клинок новичка.",
			"look": {"weapon": "sword"}},
	"rogue_dagger": {"name": "Кинжал разбойника", "kind": "melee", "sub": "dagger", "rarity": "uncommon",
			"dmg": 8, "cd": 0.24, "reach": 85.0, "stats": {"crit": 0.05}, "desc": "Быстрые уколы, часто в уязвимое место.",
			"look": {"weapon": "dagger"}},
	"hunting_bow": {"name": "Охотничий лук", "kind": "ranged", "sub": "bow", "rarity": "common",
			"dmg": 12, "cd": 0.55, "speed": 1200.0, "ammo": "arrows", "stats": {}, "desc": "Стреляет стрелами. Без стрел — бесполезен.",
			"look": {"back": "bow"}},
	"sling": {"name": "Праща", "kind": "ranged", "sub": "throw", "rarity": "common",
			"dmg": 7, "cd": 0.45, "speed": 950.0, "ammo": "stones", "stats": {}, "desc": "Мечет камни. Камней вокруг всегда много.",
			"look": {"back": "sling"}},
	# ----- снаряды -----
	"arrows": {"name": "Стрелы", "kind": "ammo", "rarity": "common", "stack": true, "desc": "Для луков."},
	"stones": {"name": "Камни для пращи", "kind": "ammo", "rarity": "common", "stack": true, "desc": "Для пращи."},
	# ----- свитки способностей -----
	"scroll_fireball": {"name": "Свиток «Огненный шар»", "kind": "scroll", "teach": "fireball", "rarity": "rare",
			"desc": "Прочитай, чтобы выучить способность «Огненный шар»."},
	"scroll_dash": {"name": "Свиток «Рывок»", "kind": "scroll", "teach": "dash", "rarity": "uncommon",
			"desc": "Прочитай, чтобы выучить способность «Рывок»."},
	"scroll_heal": {"name": "Свиток «Исцеление»", "kind": "scroll", "teach": "heal", "rarity": "uncommon",
			"desc": "Прочитай, чтобы выучить способность «Исцеление»."},
	"scroll_rage": {"name": "Свиток «Ярость предков»", "kind": "scroll", "teach": "rage", "rarity": "epic",
			"desc": "Древний свиток. Учит сверхспособности «Ярость предков»."},
	# ----- зелья -----
	"potion_hp": {"name": "Малое зелье лечения", "kind": "potion", "rarity": "common", "stack": true,
			"heal": 40, "desc": "Восстанавливает 40 здоровья."},
	"potion_mana": {"name": "Малое зелье маны", "kind": "potion", "rarity": "common", "stack": true,
			"mana": 30, "desc": "Восстанавливает 30 маны."},
	# ----- особые (квестовые) -----
	"old_key": {"name": "Старый ключ", "kind": "key", "rarity": "rare",
			"desc": "Ржавый ключ с биркой «Погреб». Где-то здесь должна быть дверь."},
}

static func get_def(id: String) -> Dictionary:
	return DB.get(id, {})

static func item_name(id: String) -> String:
	return DB.get(id, {}).get("name", id)

static func is_stack(id: String) -> bool:
	return DB.get(id, {}).get("stack", false)

# Вкладка инвентаря, в которой лежит предмет
static func tab_of(id: String) -> String:
	var k: String = DB.get(id, {}).get("kind", "")
	match k:
		"armor":
			return "armor"
		"melee":
			return "melee"
		"ranged", "ammo":
			return "ranged"
		"key":
			return "special"
	return "items"
