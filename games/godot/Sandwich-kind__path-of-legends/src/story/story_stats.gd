class_name StoryStats
# ---------- Характеристики и навыки героя Истории ----------
# Уровень героя растёт от опыта за победы над врагами: с ним растут
# здоровье и мана. Навыки (владение оружием, магия, стойкость) растут от
# использования: каждый удар мечом приближает следующий уровень «Мечей»,
# а с ним — урон всех ударов мечом.

const SKILLS := ["fist", "sword", "dagger", "blunt", "greatsword", "scythe", "bow", "pistol", "rifle", "throw",
		"magic", "toughness", "spirit"]
const SKILL_NAME := {"fist": "Кулачный бой", "sword": "Мечи", "dagger": "Кинжалы", "blunt": "Дробящее",
		"greatsword": "Двуручное", "scythe": "Косы", "bow": "Луки", "pistol": "Пистолеты", "rifle": "Автоматы",
		"throw": "Метание", "magic": "Магия", "toughness": "Стойкость", "spirit": "Сила духа"}
const SKILL_DESC := {"toughness": "Растёт, когда по тебе бьют оружием. +1 к броне за уровень.",
		"spirit": "Растёт от вражеской магии. +1 к защите от магии за уровень.",
		"magic": "Растёт от применения способностей. Усиливает чары и интеллект."}
const MAX_SKILL := 50

static func skill_next(lvl: int) -> int:
	return 12 + lvl * 8

static func level_next(lvl: int) -> int:
	return 40 + lvl * 35

# Все характеристики героя с учётом уровня, навыков и надетых вещей
static func derive(d: Dictionary) -> Dictionary:
	var lvl := int(d.get("level", 1))
	var s := {"hp": 100.0 + 12.0 * (lvl - 1), "mana": 40.0 + 6.0 * (lvl - 1), "melee": 5.0, "ranged": 5.0,
			"int": 5.0, "armor": 0.0, "mres": 0.0, "crit": 0.03}
	var sk: Dictionary = d.get("skills", {})
	s["armor"] += skill_lvl(d, "toughness") - 1
	s["mres"] += skill_lvl(d, "spirit") - 1
	s["int"] += skill_lvl(d, "magic") - 1
	for slot in d.get("equipped", {}):
		var id: String = d["equipped"][slot]
		var st: Dictionary = Items.get_def(id).get("stats", {})
		for k in st:
			s[k] = s.get(k, 0.0) + float(st[k])
	return s

static func skill_lvl(d: Dictionary, k: String) -> int:
	return int(d.get("skills", {}).get(k, {}).get("lvl", 1))

# Множитель урона от навыка владения и характеристики (melee / ranged / int)
static func dmg_mult(d: Dictionary, skill: String, stat: String) -> float:
	var s := derive(d)
	return (1.0 + 0.08 * (skill_lvl(d, skill) - 1)) * (1.0 + float(s.get(stat, 0.0)) * 0.03)

# Сколько урона пропускает броня (или защита от магии)
static func reduce(value: float) -> float:
	return 100.0 / (100.0 + maxf(value, 0.0) * 4.0)

# Опыт навыку; возвращает true, если навык вырос
static func add_skill_xp(d: Dictionary, k: String, amount: int) -> bool:
	if not d.has("skills"):
		d["skills"] = {}
	var sk: Dictionary = d["skills"].get(k, {"lvl": 1, "xp": 0})
	if int(sk["lvl"]) >= MAX_SKILL:
		return false
	sk["xp"] = int(sk["xp"]) + amount
	var up := false
	while int(sk["xp"]) >= skill_next(int(sk["lvl"])) and int(sk["lvl"]) < MAX_SKILL:
		sk["xp"] = int(sk["xp"]) - skill_next(int(sk["lvl"]))
		sk["lvl"] = int(sk["lvl"]) + 1
		up = true
	d["skills"][k] = sk
	return up

# Опыт героя; возвращает число полученных уровней
static func add_xp(d: Dictionary, amount: int) -> int:
	d["xp"] = int(d.get("xp", 0)) + amount
	var ups := 0
	while int(d["xp"]) >= level_next(int(d["level"])):
		d["xp"] = int(d["xp"]) - level_next(int(d["level"]))
		d["level"] = int(d["level"]) + 1
		ups += 1
	return ups
