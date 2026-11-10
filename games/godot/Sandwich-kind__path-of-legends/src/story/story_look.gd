class_name StoryLook
# ---------- Внешность героя Истории ----------
# look — что выбрано в редакторе персонажа (пол, телосложение, кожа, глаза,
# причёска, цвет волос, борода, шрам). spec() собирает из внешности и надетых
# вещей описание модели для BotRig: одежда, шлем, перчатки, оружие в руке и за спиной.

const SKINS := [Color(0.96, 0.80, 0.66), Color(0.93, 0.74, 0.58), Color(0.82, 0.62, 0.45),
		Color(0.66, 0.46, 0.31), Color(0.50, 0.34, 0.22), Color(0.36, 0.24, 0.16)]
const EYES := [Color(0.16, 0.14, 0.14), Color(0.35, 0.22, 0.12), Color(0.25, 0.45, 0.80),
		Color(0.30, 0.60, 0.35), Color(0.55, 0.55, 0.60), Color(0.70, 0.50, 0.15)]
const HAIR_COLORS := [Color(0.10, 0.08, 0.08), Color(0.32, 0.20, 0.11), Color(0.55, 0.36, 0.18),
		Color(0.80, 0.40, 0.16), Color(0.90, 0.78, 0.45), Color(0.80, 0.80, 0.82), Color(0.30, 0.40, 0.75)]
const HAIRS := ["short", "long", "tail", "mohawk", "bald"]
const HAIR_NAME := {"short": "Короткие", "long": "Длинные", "tail": "Хвост", "mohawk": "Ирокез", "bald": "Лысый"}
const BUILDS := ["thin", "normal", "strong"]
const BUILD_NAME := {"thin": "Худощавое", "normal": "Обычное", "strong": "Крепкое"}
const BEARDS := ["none", "stubble", "short", "full"]
const BEARD_NAME := {"none": "Нет", "stubble": "Щетина", "short": "Короткая", "full": "Густая"}
const MARKS := ["none", "scar", "paint"]
const MARK_NAME := {"none": "Нет", "scar": "Шрам", "paint": "Боевая краска"}

const NAMES_M := ["Арвен", "Борислав", "Ярен", "Торвальд", "Мирон", "Ставр", "Ратибор", "Эйрик"]
const NAMES_F := ["Велена", "Ирса", "Мирава", "Альда", "Йорунн", "Снежана", "Лада", "Эвелин"]

static func default_look() -> Dictionary:
	return {"gender": "m", "build": "normal", "skin": 1, "eyes": 1, "hair": "short", "hair_color": 1,
			"beard": "none", "mark": "none"}

static func random_name(gender: String) -> String:
	var list: Array = NAMES_F if gender == "f" else NAMES_M
	return list[randi() % list.size()]

static func _col(list: Array, i) -> Color:
	return list[clampi(int(i), 0, list.size() - 1)]

# Описание модели для BotRig
static func spec(look: Dictionary, equipped: Dictionary) -> Dictionary:
	var female: bool = look.get("gender", "m") == "f"
	var build: String = look.get("build", "normal")
	var s := {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 11], "hat": "story", "weapon": "none"}
	match build:
		"thin":
			s["torso"] = [10, 11]
			s["arm"] = [3, 11]
			s["leg"] = [4, 12]
		"strong":
			s["torso"] = [15, 11]
			s["arm"] = [5, 11]
			s["leg"] = [6, 11]
	if female:
		var t: Array = s["torso"]
		s["torso"] = [t[0] - 1, t[1]]
		s["head"] = [9, 9]
		s["leg"] = [s["leg"][0], s["leg"][1] + 1]
		s["female"] = true
	s["skin"] = _col(SKINS, look.get("skin", 1))
	s["eye"] = _col(EYES, look.get("eyes", 0))
	s["hair"] = look.get("hair", "short")
	s["hair_color"] = _col(HAIR_COLORS, look.get("hair_color", 1))
	s["beard"] = "none" if female else look.get("beard", "none")
	s["mark"] = look.get("mark", "none")
	# без одежды — простое бельё
	s["shirt"] = s["skin"]
	s["bare_chest_story"] = true
	s["pants"] = Color(0.75, 0.70, 0.60)
	for slot in equipped:
		var lk: Dictionary = Items.get_def(String(equipped[slot])).get("look", {})
		for k in lk:
			s[k] = lk[k]
		if slot == "chest":
			s.erase("bare_chest_story")
	if s.has("weapon") and s["weapon"] == "":
		s["weapon"] = "none"
	return s
