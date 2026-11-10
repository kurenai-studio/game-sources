class_name StorySettings
# ---------- Настройки игры (user://settings.json) ----------
# touch_panel — экранные кнопки на тёмной полосе под игрой (иначе — прямо на экране)
# touch_move  — движение на телефоне: "stick" (виртуальный стик) или "dpad" (крестовина-кнопки)
# dpad_size   — размер крестовины в процентах (60–160)

const PATH := "user://settings.json"
const DEFAULTS := {"damage_numbers": true, "touch_on_pc": false, "screen_shake": true, "music": 80, "sfx": 80,
		"touch_panel": false, "touch_move": "stick", "touch_alpha": 45, "dpad_size": 100}

static var _cache := {}

static func load_all() -> Dictionary:
	if not _cache.is_empty():
		return _cache.duplicate()
	var s := DEFAULTS.duplicate()
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				s.merge(parsed, true)
	_cache = s
	return s.duplicate()

static func get_value(key: String):
	return load_all().get(key, DEFAULTS.get(key))

static func set_value(key: String, v) -> void:
	var s := load_all()
	s[key] = v
	_cache = s
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(s, "\t"))
	if key == "touch_on_pc":
		Config.SHOW_TOUCH_ON_PC = bool(v)

static func apply() -> void:
	Config.SHOW_TOUCH_ON_PC = bool(get_value("touch_on_pc")) or Config.SHOW_TOUCH_ON_PC
