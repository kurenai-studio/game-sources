## Headless runner: godot --headless --path game --script res://tests/run_all.gd
## Exit 1 on any failed check or any test script that does not load.
extends SceneTree

const TEST_DIR := "res://tests"


func _initialize() -> void:
	_run_all()


func _run_all() -> void:
	# the real save in user:// must never steer a test (a saved checkpoint would move the player), nor be overwritten by one
	OS.set_environment("DREAMRUN_SAVE", "user://test_run_save.json")
	SaveGame.erase()
	var failed := 0
	var ran := 0
	for file in DirAccess.get_files_at(TEST_DIR):
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		var only := OS.get_environment("TEST_ONLY")  # e.g. TEST_ONLY=room_bugs runs just that file
		if only != "" and not file.contains(only):
			continue
		var script := load("%s/%s" % [TEST_DIR, file]) as GDScript
		if script == null:
			printerr("FAIL %s: script did not load" % file)
			failed += 1
			continue
		var test: Object = script.new()
		test.tree = self
		for method in test.get_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			test.failures.clear()
			await test.call(name)
			ran += 1
			for message in test.failures:
				printerr("FAIL %s::%s: %s" % [file, name, message])
				failed += 1
	SaveGame.erase()
	print("tests: %d run, %d failed" % [ran, failed])
	quit(1 if failed > 0 else 0)
