extends Node

signal run_started
signal run_ended

const SAVE_PATH := "user://shadow_survivors.save"

var high_score: int = 0
var best_wave: int = 0
var score: int = 0
var kills: int = 0
var wave: int = 1
var survival_time: float = 0.0
var run_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_save()

func start_run() -> void:
	score = 0
	kills = 0
	wave = 1
	survival_time = 0.0
	run_active = true
	run_started.emit()

func _process(delta: float) -> void:
	if run_active and not get_tree().paused:
		survival_time += delta
		score += int(delta * 2.0)

func add_kill(points: int) -> void:
	kills += 1
	score += points

func finish_run() -> void:
	if not run_active:
		return
	run_active = false
	high_score = maxi(high_score, score)
	best_wave = maxi(best_wave, wave)
	save_data()
	run_ended.emit()

func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var({"high_score": high_score, "best_wave": best_wave})

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data: Variant = file.get_var()
		if data is Dictionary:
			high_score = int(data.get("high_score", 0))
			best_wave = int(data.get("best_wave", 0))

func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]

