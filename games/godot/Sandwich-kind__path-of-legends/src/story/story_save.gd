class_name StorySave
# ---------- Сохранения Истории: три независимые ячейки ----------
# Каждая ячейка — свой файл user://story_1.json … story_3.json.
# Игра пишет только в выбранную ячейку; другие не трогаются.

const SLOTS := 3
const VERSION := 1

static func path(slot: int) -> String:
	return "user://story_%d.json" % slot

static func exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot))

static func load_slot(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var f := FileAccess.open(path(slot), FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}

static func save_slot(slot: int, data: Dictionary) -> void:
	data["saved_at"] = Time.get_datetime_string_from_system(false, true)
	var f := FileAccess.open(path(slot), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))

static func delete_slot(slot: int) -> void:
	if exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path(slot)))

# Краткие сведения для карточки ячейки
static func summary(slot: int) -> Dictionary:
	var d := load_slot(slot)
	if d.is_empty():
		return {}
	var t := int(d.get("playtime", 0.0))
	return {"name": d.get("name", "Герой"), "level": int(d.get("level", 1)),
			"time": "%d:%02d" % [t / 3600, (t / 60) % 60], "saved": d.get("saved_at", ""),
			"look": d.get("look", {})}

# Новое сохранение: только базовая одежда, никаких вещей и способностей
static func new_game(name: String, look: Dictionary) -> Dictionary:
	var skills := {}
	for k in StoryStats.SKILLS:
		skills[k] = {"lvl": 1, "xp": 0}
	return {
		"version": VERSION, "name": name, "look": look,
		"level": 1, "xp": 0, "playtime": 0.0, "gold": 0,
		"hp": -1, "mana": -1,                                 # -1 — полные
		"inventory": [{"id": "leather_shirt", "n": 1}, {"id": "leather_pants", "n": 1}],
		"equipped": {"chest": "leather_shirt", "legs": "leather_pants"},
		"learned": [],                                        # изученные способности
		"slots": ["", "", ""], "ult": "",                     # что стоит в ячейках способностей
		"skills": skills,
		"quests": StoryQuests.start_state(),
		"world": {"zone": "field", "pos": [], "opened": []},
	}
