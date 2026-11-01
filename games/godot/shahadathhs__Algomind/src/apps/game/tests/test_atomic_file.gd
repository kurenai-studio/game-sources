extends GutTest
## The shared safe-write helper: it replaces files, keeps a backup on request, and refuses to
## leave a bad file in place.

const PATH := "user://test_atomic.json"


func before_each() -> void:
	_remove()


func after_each() -> void:
	_remove()


func _remove() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(PATH + suffix)


func test_a_value_round_trips() -> void:
	assert_true(AtomicFile.write_json(PATH, {"a": 1, "b": ["x"]}))
	var read: Variant = AtomicFile.read_json(PATH)
	assert_eq(read["b"], ["x"])
	assert_false(FileAccess.file_exists(PATH + ".tmp"), "no temporary file is left behind")


func test_writing_again_replaces_the_file() -> void:
	AtomicFile.write_json(PATH, {"v": 1})
	assert_true(AtomicFile.write_json(PATH, {"v": 2}))
	assert_eq(AtomicFile.read_json(PATH)["v"], 2.0)


func test_a_backup_keeps_the_previous_good_copy() -> void:
	AtomicFile.write_json(PATH, {"v": 1}, true)
	AtomicFile.write_json(PATH, {"v": 2}, true)
	assert_eq(AtomicFile.read_json(PATH + ".bak")["v"], 1.0)
	assert_eq(AtomicFile.read_json(PATH)["v"], 2.0)


func test_no_backup_is_made_unless_asked() -> void:
	AtomicFile.write_json(PATH, {"v": 1})
	AtomicFile.write_json(PATH, {"v": 2})
	assert_false(FileAccess.file_exists(PATH + ".bak"))


func test_reading_a_missing_or_damaged_file_gives_null_without_an_error() -> void:
	assert_null(AtomicFile.read_json(PATH))
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	assert_null(AtomicFile.read_json(PATH))
