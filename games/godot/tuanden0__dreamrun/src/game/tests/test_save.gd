extends "res://tests/test_case.gd"

const PATH := "user://test_save_unit.json"


func _clean() -> void:
	SaveGame.erase(PATH)


func test_write_then_read_round_trips_with_version_and_time() -> void:
	_clean()
	var before := Time.get_unix_time_from_system()
	check(SaveGame.write({"chapter": "chapter1", "checkpoint": "CheckpointRope", "completed": false}, PATH), "writes")
	var data := SaveGame.read(PATH)
	check(data.get("checkpoint") == "CheckpointRope" and data.get("chapter") == "chapter1" and data.get("completed") == false, "contents come back: %s" % [data])
	check(int(data.get("version", -1)) == SaveGame.VERSION, "carries its version")
	check(float(data.get("saved_at", 0.0)) >= before - 1.0, "carries the time it was saved")
	check(not FileAccess.file_exists(PATH + ".tmp"), "no temporary file is left behind")
	_clean()


func test_writing_again_replaces_the_file() -> void:
	_clean()
	SaveGame.write({"checkpoint": "A"}, PATH)
	SaveGame.write({"checkpoint": "B"}, PATH)
	check(SaveGame.read(PATH).get("checkpoint") == "B", "the second save wins")
	_clean()


## Wrong ways: nothing, rubbish, an empty file, the wrong shape and a version from the future all read as "no save".
func test_missing_corrupt_and_foreign_files_read_as_no_save() -> void:
	_clean()
	check(SaveGame.read(PATH).is_empty(), "no file")
	for body in ["", "not json at all {{{", "[1, 2, 3]", "\"text\"", "{\"checkpoint\": \"A\"}", "{\"version\": 999, \"checkpoint\": \"A\"}", "{\"version\": \"1\", \"checkpoint\": \"A\"}"]:
		var file := FileAccess.open(PATH, FileAccess.WRITE)
		file.store_string(body)
		file.close()
		check(SaveGame.read(PATH).is_empty(), "unusable save %s reads as none, got %s" % [body.left(30), SaveGame.read(PATH)])
	_clean()


## The swap can be interrupted after the temporary file is complete: then that file is the save.
func test_a_finished_temporary_file_is_used_when_the_swap_was_interrupted() -> void:
	_clean()
	SaveGame.write({"checkpoint": "A"}, PATH)
	DirAccess.rename_absolute(PATH, PATH + ".tmp")
	check(not FileAccess.file_exists(PATH), "setup: only the temporary file exists")
	check(SaveGame.read(PATH).get("checkpoint") == "A", "the temporary file is read")
	_clean()


func test_unwritable_location_fails_without_crashing() -> void:
	check(not SaveGame.write({"checkpoint": "A"}, "user://no_such_folder/nested/save.json"), "reports failure")
	check(SaveGame.read("user://no_such_folder/nested/save.json").is_empty(), "and reads as none")


func test_the_test_runner_never_touches_the_real_save() -> void:
	check(SaveGame.default_path() != SaveGame.FILE, "tests use their own save file, path=%s" % SaveGame.default_path())


# ---------------------------------------------------------------- progress in the chapter

func _chapter(path: String) -> Chapter:
	var room := (load("res://levels/chapter1.tscn") as PackedScene).instantiate() as Chapter
	room.change_scenes = false
	(room.get_node("Progress") as Progress).save_path = path
	tree.root.add_child(room)
	return room


func test_lighting_a_checkpoint_saves_it_and_the_next_start_resumes_there() -> void:
	_clean()
	var room := _chapter(PATH)
	var player := room.get_node("Player") as PlayerController
	await frames(20)
	check(SaveGame.read(PATH).get("checkpoint") == "CheckpointStart", "the first checkpoint is saved at the start, saved=%s" % [SaveGame.read(PATH)])
	player.position = (room.get_node("CheckpointDoor1") as Checkpoint).position + Vector2(0, -2)
	await frames(20)
	check(SaveGame.read(PATH).get("checkpoint") == "CheckpointDoor1", "walking into the next one saves it")
	room.queue_free()
	await frames(3)
	# a new run of the same chapter
	var again := _chapter(PATH)
	var restored: Array[StringName] = []
	(again.get_node("Progress") as Progress).restored.connect(func(n: StringName) -> void: restored.append(n))
	var player2 := again.get_node("Player") as PlayerController
	await frames(20)
	check(restored == [&"CheckpointDoor1"], "resumes at the saved checkpoint, restored=%s" % [restored])
	check(player2.position.distance_to((again.get_node("CheckpointDoor1") as Checkpoint).position) < 60.0, "and the player is there, at %s" % player2.position)
	check((again.get_node("CheckpointDoor1") as Checkpoint).is_active, "which lights, so a death comes back to it")
	again.queue_free()
	await frames(3)
	_clean()


func test_a_death_after_resuming_respawns_at_the_resumed_checkpoint() -> void:
	_clean()
	SaveGame.write({"chapter": "chapter1", "checkpoint": "CheckpointLever", "completed": false}, PATH)
	var room := _chapter(PATH)
	var player := room.get_node("Player") as PlayerController
	await frames(30)
	var spot := player.position
	player.die()
	var back := false
	for i in 120:
		await frames(1)
		if not player.is_dead:
			back = true
			break
	await frames(3)
	check(back and player.position.distance_to(spot) < 8.0, "respawned where it resumed: %s, now %s" % [spot, player.position])
	room.queue_free()
	await frames(3)
	_clean()


func test_a_finished_chapter_starts_again_from_the_beginning() -> void:
	_clean()
	SaveGame.write({"chapter": "chapter1", "checkpoint": "CheckpointWall", "completed": true}, PATH)
	var room := _chapter(PATH)
	var player := room.get_node("Player") as PlayerController
	await frames(20)
	check(player.position.x < 200.0, "a completed chapter does not resume, player x=%s" % player.position.x)
	room.queue_free()
	await frames(3)
	_clean()


func test_completing_the_chapter_is_saved() -> void:
	_clean()
	var room := _chapter(PATH)
	await frames(10)
	room.finish()
	await frames(3)
	check(SaveGame.read(PATH).get("completed") == true, "completion is in the save: %s" % [SaveGame.read(PATH)])
	room.queue_free()
	await frames(3)
	_clean()


## Wrong way: a save that names a checkpoint that is not in the chapter, or belongs to another chapter.
func test_a_save_for_something_else_is_ignored() -> void:
	for data in [{"chapter": "chapter1", "checkpoint": "NoSuchThing", "completed": false}, {"chapter": "chapter9", "checkpoint": "CheckpointWall", "completed": false}, {"chapter": "chapter1", "completed": false}]:
		_clean()
		SaveGame.write(data, PATH)
		var room := _chapter(PATH)
		var player := room.get_node("Player") as PlayerController
		await frames(20)
		check(player.position.x < 200.0, "unusable save %s leaves the player at the start, x=%s" % [data, player.position.x])
		room.queue_free()
		await frames(3)
	_clean()


func test_new_game_forgets_the_save_and_starts_at_the_beginning() -> void:
	_clean()
	SaveGame.write({"chapter": "chapter1", "checkpoint": "CheckpointWall", "completed": false}, PATH)
	var room := (load("res://levels/chapter1.tscn") as PackedScene).instantiate() as Chapter
	room.change_scenes = false
	var progress := room.get_node("Progress") as Progress
	progress.save_path = PATH
	progress.new_game = true  # what `--new-game` sets
	tree.root.add_child(room)
	var player := room.get_node("Player") as PlayerController
	await frames(30)
	check(player.position.x < 250.0, "starts at the beginning, x=%s" % player.position.x)
	check(SaveGame.read(PATH).get("checkpoint") == "CheckpointStart", "and the old save is replaced by the new start: %s" % [SaveGame.read(PATH)])
	room.queue_free()
	await frames(3)
	_clean()
