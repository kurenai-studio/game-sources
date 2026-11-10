class_name Catalog
extends RefCounted
## The game's data files, read once: the events (data/events.json), the
## nations (data/nations.json) and the music's beat maps (data/music.json).

static var _events: Dictionary = {}
static var _nations: Array = []
static var _music: Dictionary = {}
static var _series: Array = []


static func _read(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("missing " + path)
		return null
	return JSON.parse_string(f.get_as_text())


static func events() -> Dictionary:
	if _events.is_empty():
		var d: Variant = _read("res://data/events.json")
		_events = d if d is Dictionary else {}
	return _events


static func event(id: String) -> Dictionary:
	return events().get("events", {}).get(id, {})


static func order() -> Array:
	return events().get("order", [])


## The levels, easiest first: EASY (young players: wide beats, low marks, help
## with the jumps), JUNIOR, PRO.
const LEVELS := ["easy", "junior", "pro"]


static func next_level(level: String) -> String:
	return LEVELS[(LEVELS.find(level) + 1) % LEVELS.size()]


static func windows(level: String) -> Array:
	return events().get("windows", {}).get(level, [0.06, 0.1, 0.14])


## The set series (data/series.json), each with only the events that exist.
static func series() -> Array:
	if _series.is_empty():
		var d: Variant = _read("res://data/series.json")
		for s in (d.get("series", []) if d is Dictionary else []):
			var e: Array = s.get("events", []).filter(func(id): return not event(String(id)).is_empty())
			if not e.is_empty():
				var copy: Dictionary = s.duplicate()
				copy["events"] = e
				_series.append(copy)
	return _series


static func a_series(id: String) -> Dictionary:
	for s in series():
		if s.id == id:
			return s
	return {}


static func nations() -> Array:
	if _nations.is_empty():
		var d: Variant = _read("res://data/nations.json")
		_nations = d.get("nations", []) if d is Dictionary else []
	return _nations


static func nation(id: String) -> Dictionary:
	for n in nations():
		if n.id == id:
			return n
	return {}


static func music() -> Dictionary:
	if _music.is_empty():
		var d: Variant = _read("res://data/music.json")
		_music = d if d is Dictionary else {}
	return _music


## A result for showing: 10.84s, 7.42m, 212.5 pts.
static func show_mark(id: String, mark: float) -> String:
	var e := event(id)
	match String(e.get("unit", "")):
		"s":
			return "%.2fs" % mark
		"m":
			return "%.2fm" % mark
		"pts":
			return "%.1f" % mark
	return str(mark)


## Is mark a better than mark b in this event?
static func better(id: String, a: float, b: float) -> bool:
	if String(event(id).get("better", "high")) == "low":
		return a < b
	return a > b
