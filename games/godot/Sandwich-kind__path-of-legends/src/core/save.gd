class_name Save
# Сохранение прогресса в файл на устройстве: золото и докуда дошёл на Арене.
# Сохраняется после каждой пройденной волны, чтобы можно было продолжить позже.

const PATH := "user://save.json"

static var data := {}

static func _default() -> Dictionary:
	return {"gold": 0, "arena": {}, "bestiary": {}, "unlocked": [], "heroes": [], "roster": ROSTER,
			"bought": [], "megas": [], "stage_ver": STAGE_VER}

# Версия списка легенд: в начало списка добавлены 2 стартовые легенды,
# поэтому номера героев в старых сохранениях Арены сдвигаются на 2.
const ROSTER := 2
# Версия порядка этапов Арены: во 2-й Колизей переехал на волны 41–50 (этапы 8 и 9),
# а волны 1–10 теперь — Лесная тропа и Окраина деревни
const STAGE_VER := 2

static func load_game() -> void:
	data = _default()
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k in parsed:
			data[k] = parsed[k]
		if int(parsed.get("roster", 1)) < ROSTER:
			for mode in data.get("arena", {}):
				var pr = data["arena"][mode]
				if pr is Dictionary and pr.has("chars"):
					var moved := []
					for c in pr["chars"]:
						moved.append(int(c) + 2)
					pr["chars"] = moved
			data["roster"] = ROSTER
		if int(parsed.get("stage_ver", 1)) < STAGE_VER:
			var moved_s := []
			for st in data.get("unlocked", []):
				var si := int(st)
				moved_s.append(si + 8 if si <= 1 else si)    # открытые Колизеи остаются открытыми
			data["unlocked"] = moved_s
			data["stage_ver"] = STAGE_VER

static func save_game() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))

static func reset() -> void:
	data = _default()
	save_game()

# ---------- Золото ----------
static func gold() -> int:
	return int(data.get("gold", 0))

static func add_gold(n: int) -> void:
	data["gold"] = gold() + n
	save_game()

# ---------- Арена ----------
# mode: "solo" или "coop". Запоминаем, с какой волны продолжать и кем играли.
static func arena_progress(mode: String) -> Dictionary:
	return data.get("arena", {}).get(mode, {})

static func set_arena_progress(mode: String, next_wave: int, chars: Array, lives: int) -> void:
	if not data.has("arena"):
		data["arena"] = {}
	data["arena"][mode] = {"wave": next_wave, "chars": chars, "lives": lives}
	save_game()

static func clear_arena_progress(mode: String) -> void:
	if data.has("arena"):
		data["arena"].erase(mode)
	save_game()

# Награда за пройденную волну: 1-я — 2 монеты, 2-я — 3, 3-я — 4 и так далее
static func wave_reward(wave: int) -> int:
	return wave + 1

# ---------- Бестиарий ----------
# Противник попадает в бестиарий, как только впервые появился на арене
static func see(kind: String) -> void:
	if not data.has("bestiary"):
		data["bestiary"] = {}
	if data["bestiary"].has(kind):
		return
	data["bestiary"][kind] = true
	save_game()

static func seen(kind: String) -> bool:
	return data.get("bestiary", {}).has(kind)

static func see_all() -> void:
	for loc in Bots.LOCATIONS:
		for k in Bots.LOCATIONS[loc]:
			if not data.has("bestiary"):
				data["bestiary"] = {}
			data["bestiary"][k] = true
	save_game()

# ---------- Скрытые карты Дуэли ----------
# Этап Арены пройден полностью (волны 5, 10, 15...) — его арена открывается для Дуэли
static func unlock_stage(stage: int) -> bool:
	if not data.has("unlocked"):
		data["unlocked"] = []
	if stage in data["unlocked"] or float(stage) in data["unlocked"]:
		return false
	data["unlocked"].append(stage)
	save_game()
	return true

static func stage_unlocked(stage: int) -> bool:
	for s in data.get("unlocked", []):
		if int(s) == stage:
			return true
	return false

static func unlock_all_stages() -> void:
	data["unlocked"] = range(17)
	save_game()

# ---------- Легенды за боссов ----------
static func unlock_hero(boss: String) -> bool:
	if not data.has("heroes"):
		data["heroes"] = []
	if boss in data["heroes"]:
		return false
	data["heroes"].append(boss)
	save_game()
	return true

static func hero_unlocked(boss: String) -> bool:
	return boss in data.get("heroes", [])

static func unlock_all_heroes() -> void:
	data["heroes"] = []
	for ch in Characters.LIST:
		if ch.has("unlock"):
			data["heroes"].append(ch["unlock"])         # все легенды за боссов Арены
	for ch in Characters.LIST:
		if ch.has("price") and not (ch["name"] in data.get("bought", [])):
			if not data.has("bought"):
				data["bought"] = []
			data["bought"].append(ch["name"])
	save_game()

# ---------- Лавка: легенды и МЕГА-усиления за монеты ----------
static func owns_hero(name: String) -> bool:
	return name in data.get("bought", [])

static func has_mega(name: String) -> bool:
	return name in data.get("megas", [])

# Покупка: списывает монеты и сохраняет. what — "hero" или "mega".
static func buy(what: String, name: String, price: int) -> bool:
	if gold() < price:
		return false
	var key := "bought" if what == "hero" else "megas"
	if not data.has(key):
		data[key] = []
	if name in data[key]:
		return false
	data["gold"] = gold() - price
	data[key].append(name)
	save_game()
	return true
