class_name GameSettings
extends RefCounted
## Player preferences and best score, stored in user://settings.cfg.

const PATH := "user://settings.cfg"
const LEGACY_BEST_PATH := "user://best.save"

var sound := true
var music := true
var reduced_effects := false
var best := 0
var persist := true


func load_file() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		sound = cfg.get_value("audio", "sound", true)
		music = cfg.get_value("audio", "music", true)
		reduced_effects = cfg.get_value("video", "reduced_effects", false)
		best = cfg.get_value("score", "best", 0)
	elif FileAccess.file_exists(LEGACY_BEST_PATH):
		# 1.0.0 stored only the best score, as a raw 32-bit integer.
		var f := FileAccess.open(LEGACY_BEST_PATH, FileAccess.READ)
		if f:
			best = f.get_32()


func save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sound", sound)
	cfg.set_value("audio", "music", music)
	cfg.set_value("video", "reduced_effects", reduced_effects)
	cfg.set_value("score", "best", best)
	cfg.save(PATH)
