class_name Records
extends RefCounted
## The best run so far: longest survived, highest level, most kills, most giants felled, most
## machines broken. Kept in the player's data folder beside the settings.

const PATH := "user://records.cfg"
const KEYS: Array[String] = ["time", "level", "kills", "giants", "machines"]

var best := {"time": 0.0, "level": 0, "kills": 0, "giants": 0, "machines": 0}


## A run's numbers, from its arena.
static func of(arena: Arena) -> Dictionary:
	return {"time": arena.time, "level": arena.level, "kills": arena.kills, "giants": arena.giants_felled, "machines": arena.machines_broken}


## Takes a run's numbers and returns which of them beat the best, keeping those as the new best.
## A number the run doesn't have counts as none of it.
func record(run: Dictionary) -> Array[String]:
	var beaten: Array[String] = []
	for key in KEYS:
		if run.get(key, 0) > best[key]:
			best[key] = run[key]
			beaten.append(key)
	return beaten


func save(path := PATH) -> bool:
	var file := ConfigFile.new()
	for key in KEYS:
		file.set_value("best", key, best[key])
	return file.save(path) == OK


## Back to nothing: no best run yet.
func clear() -> void:
	best = {"time": 0.0, "level": 0, "kills": 0, "giants": 0, "machines": 0}


func load_from(path := PATH) -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	for key in KEYS:
		var saved: Variant = file.get_value("best", key, best[key])
		if typeof(saved) == typeof(best[key]):
			best[key] = saved
