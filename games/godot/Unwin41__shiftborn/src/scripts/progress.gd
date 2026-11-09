class_name Progress
extends RefCounted
## Saved between runs: the best score and the unlocked achievements, in
## [constant PATH]. [method current] loads it on first use.

const PATH := "user://progress.cfg"
const SECTION := "progress"

static var _current: Progress
## Where [method current] loads and [method save] writes. Tests point it
## elsewhere so they never touch the player's save.
static var path: String = PATH

var best_score: int = 0
var unlocked: Array[StringName] = []


static func current() -> Progress:
	if _current == null:
		_current = Progress.new()
		_current.load_from(path)
	return _current


## Records [param score]; returns true when it beats the best.
func submit_score(score: int) -> bool:
	if score <= best_score:
		return false
	best_score = score
	return true


func unlock(id: StringName) -> void:
	if not id in unlocked:
		unlocked.append(id)


func is_unlocked(id: StringName) -> bool:
	return id in unlocked


func save() -> void:
	var error := save_to(path)
	if error != OK:
		push_warning("Progress: cannot save %s (error %d)" % [path, error])


func save_to(path: String) -> Error:
	var config := ConfigFile.new()
	config.set_value(SECTION, "best_score", best_score)
	config.set_value(SECTION, "unlocked", PackedStringArray(unlocked))
	return config.save(path)


## A missing or broken file keeps the current values.
func load_from(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var config := ConfigFile.new()
	if config.load(path) != OK:
		push_warning("Progress: cannot read %s" % path)
		return
	best_score = maxi(int(config.get_value(SECTION, "best_score", best_score)), 0)
	unlocked.clear()
	for id in PackedStringArray(config.get_value(SECTION, "unlocked", PackedStringArray())):
		unlocked.append(StringName(id))
