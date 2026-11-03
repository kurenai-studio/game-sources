class_name Achievements
extends RefCounted
## Achievement definitions and a pure evaluator over a stats snapshot.

const DEFS: Array[Dictionary] = [
	{"id": &"first_blood", "stat": "total_kills", "target": 1},
	{"id": &"slayer", "stat": "total_kills", "target": 500},
	{"id": &"survivor", "stat": "wave", "target": 5},
	{"id": &"veteran", "stat": "wave", "target": 10},
	{"id": &"boss_slayer", "stat": "bosses_killed", "target": 1},
	{"id": &"combo_master", "stat": "max_combo", "target": 25},
	{"id": &"ascended", "stat": "level", "target": 10},
	{"id": &"tycoon", "stat": "coins_earned", "target": 1000},
	{"id": &"untouchable", "stat": "flawless_waves", "target": 1},
	{"id": &"collector", "stat": "characters_unlocked", "target": 3},
]


static func name_key(id: StringName) -> String:
	return "ACH_%s" % String(id).to_upper()


static func desc_key(id: StringName) -> String:
	return "ACH_%s_DESC" % String(id).to_upper()


static func evaluate(snapshot: Dictionary, unlocked: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for def in DEFS:
		var id: StringName = def["id"]
		if unlocked.has(id) or unlocked.has(String(id)):
			continue
		if int(snapshot.get(def["stat"], 0)) >= int(def["target"]):
			out.append(id)
	return out


static func progress(id: StringName, snapshot: Dictionary) -> float:
	for def in DEFS:
		if def["id"] == id:
			return clampf(float(snapshot.get(def["stat"], 0)) / float(def["target"]), 0.0, 1.0)
	return 0.0
