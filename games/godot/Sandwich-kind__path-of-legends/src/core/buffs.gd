class_name Buffs
# Баффы, которые подбираются на Арене. Каждый действует сам по себе.
# Если подобрать такой же бафф, пока прежний ещё действует, он становится МЕГА.
#   «Откат» — способности восстанавливаются в 2,5 раза быстрее (МЕГА — в 5 раз).
#   «МЕГА-усиление» — пока действует, способности и ульта — МЕГА-версии.
#       Подобрать ещё раз — «Двойное МЕГА-усиление»: дольше, и способности
#       вдобавок восстанавливаются на 30% быстрее.

const DURATION := 12.0
const MEGA_DURATION := 15.0

const TYPES := {
	"rapid":    {"name": "Шквал",  "letter": "Ш", "color": Color(1.0, 0.75, 0.2),
			"desc": "стрельба вдвое быстрее, без перезарядки"},
	"cooldown": {"name": "Откат",  "letter": "О", "color": Color(0.35, 0.85, 1.0),
			"desc": "способности восстанавливаются в 2,5 раза быстрее (МЕГА — в 5 раз)"},
	"boost":    {"name": "МЕГА-усиление", "mega_name": "Двойное МЕГА-усиление", "letter": "М",
			"color": Color(0.95, 0.45, 1.0), "dur": 10.0, "mega_dur": 16.0,
			"desc": "способности и ульта — МЕГА-версии"},
	"damage":   {"name": "Сила",   "letter": "С", "color": Color(1.0, 0.3, 0.3),
			"desc": "урон ×1.5"},
	"armor":    {"name": "Броня",  "letter": "Б", "color": Color(0.75, 0.75, 0.85),
			"desc": "входящий урон −50%"},
	"speed":    {"name": "Ветер",  "letter": "В", "color": Color(0.45, 1.0, 0.55),
			"desc": "бег быстрее, прыжок выше"},
}

const CD_SPEED := 2.5             # «Откат»: во сколько раз быстрее восстанавливаются способности
const CD_SPEED_MEGA := 5.0        # МЕГА-«Откат»
const BOOST_CD := 1.3             # «Двойное МЕГА-усиление»: ещё и откат быстрее

# Название баффа (МЕГА-версия — со своим названием или с приставкой «МЕГА-»)
static func title(type: String, mega: bool) -> String:
	var t: Dictionary = TYPES[type]
	if not mega:
		return t["name"]
	return t.get("mega_name", "МЕГА-" + String(t["name"]))

static func duration(type: String, mega: bool) -> float:
	var t: Dictionary = TYPES[type]
	return float(t.get("mega_dur", MEGA_DURATION)) if mega else float(t.get("dur", DURATION))

static func random_type(except := "") -> String:
	var keys := TYPES.keys()
	keys.erase(except)
	return keys.pick_random()
