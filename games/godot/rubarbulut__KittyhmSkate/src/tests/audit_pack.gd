extends SceneTree
## Run with --main-pack against the actual release PCK, using an editor runner.
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	for path in ["res://main.tscn","res://scripts/game.gd","res://scripts/level.gd","res://scripts/beat_clock.gd","res://scripts/calibration.gd","res://assets/fonts/Silkscreen-Regular.ttf"]:
		check(ResourceLoader.exists(path),"Missing runtime resource: "+path)
	for name in ["alley_shift","rooftop_radio","midnight_overdrive","warmup","perfect","good","land","bump","hold","clear","calibration"]:
		check(ResourceLoader.exists("res://assets/audio/"+name+".wav"),"Missing audio: "+name)
	for path in ["res://tests/web_qa.gd","res://tests/play_tour.gd","res://tools/fetch_templates.py","res://JAM_READINESS.md","res://.qa/progress-roundtrip.cfg"]:
		check(not ResourceLoader.exists(path) and not FileAccess.file_exists(path),"QA/development material leaked into game: "+path)
	check(FileAccess.file_exists("res://LICENSE") and FileAccess.file_exists("res://assets/fonts/OFL.txt"),"Release must include licenses")
	print("PASS: packed runtime resources, all music, licenses and QA exclusion" if failures == 0 else "FAILED pack audit")
	quit(0 if failures == 0 else 1)
