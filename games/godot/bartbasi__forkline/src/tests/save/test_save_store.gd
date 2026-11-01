# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## SaveStore with settings and progress: round trips, atomic writes, the loading
## order with .tmp and .bak, locked files and newer formats (docs/ARCHITECTURE.md 5.1 to 5.5).

const Fx: GDScript = preload("res://tests/save/fixtures/save_fixtures.gd")

var store: SaveStore = null


func before_each() -> void:
	Fx.fresh()
	store = SaveStore.new(Fx.WORK)


func after_each() -> void:
	store = null
	Fx.clean()


func _settings(sound: bool) -> Settings:
	var settings: Settings = Settings.new()
	settings.sound_on = sound
	return settings


func _progress(stars_on_first: int) -> Progress:
	var progress: Progress = Progress.new()
	progress.record_level(&"r1_l1", stars_on_first)
	return progress


func test_missing_files_give_defaults() -> void:
	assert_true(store.load_settings().sound_on)
	assert_eq(store.load_progress().levels.size(), 0)
	assert_eq(store.load_games(Fx.game()).size(), 0)


func test_settings_and_progress_round_trip() -> void:
	assert_true(store.save_settings(_settings(false)))
	var progress: Progress = _progress(5)
	progress.record_twist(&"r1_l1")
	progress.mark_seen(&"pip")
	progress.bump(&"runs_won", 3)
	assert_true(store.save_progress(progress))
	assert_eq(Fx.read_text("settings.json"), "{\"format\":1,\"music\":true,\"sound\":false}")
	var again: SaveStore = SaveStore.new(Fx.WORK)
	assert_false(again.load_settings().sound_on)
	var loaded: Progress = again.load_progress()
	assert_eq(JSON.stringify(loaded.to_data()), JSON.stringify(progress.to_data()))
	assert_false(Fx.exists("settings.json.tmp"))
	assert_false(Fx.exists("progress.json.tmp"))


func test_settings_file_from_before_music_loads_and_saves_music() -> void:
	Fx.write_text("settings.json", "{\"format\":1,\"sound\":false}")
	var old: Settings = store.load_settings()
	assert_false(old.sound_on)
	assert_true(old.music_on, "a file without music loads with music on")
	old.music_on = false
	assert_true(store.save_settings(old))
	assert_eq(Fx.read_text("settings.json"), "{\"format\":1,\"music\":false,\"sound\":false}")
	var again: Settings = SaveStore.new(Fx.WORK).load_settings()
	assert_eq([again.sound_on, again.music_on], [false, false])


func test_hostile_music_in_the_file_falls_back_to_on() -> void:
	for value: String in ["\"false\"", "0", "null", "[false]", "{\"on\":false}", "1e308"]:
		Fx.write_text("settings.json", "{\"format\":1,\"sound\":false,\"music\":%s}" % value)
		var loaded: Settings = SaveStore.new(Fx.WORK).load_settings()
		assert_true(loaded.music_on, value)
		assert_false(loaded.sound_on, "sound still read with music %s" % value)


func test_second_write_keeps_the_first_as_backup() -> void:
	assert_true(store.save_settings(_settings(false)))
	assert_false(Fx.exists("settings.json.bak"))
	assert_true(store.save_settings(_settings(true)))
	assert_eq(Fx.read_text("settings.json.bak"), "{\"format\":1,\"music\":true,\"sound\":false}")
	assert_eq(Fx.read_text("settings.json"), "{\"format\":1,\"music\":true,\"sound\":true}")


func test_same_text_is_not_written_again() -> void:
	assert_true(store.save_settings(_settings(false)))
	assert_true(store.save_settings(_settings(false)))
	assert_false(Fx.exists("settings.json.bak"), "the second write was skipped")


func test_file_changed_by_someone_else_is_not_kept_as_backup() -> void:
	assert_true(store.save_settings(_settings(false)))
	Fx.write_text("settings.json", "{\"format\": 1, \"sound\": \"broken\"}")
	assert_true(store.save_settings(_settings(true)))
	assert_false(Fx.exists("settings.json.bak"), "only text this store wrote or loaded as valid becomes the backup")


func test_tmp_wins_and_moves_into_place() -> void:
	Fx.write_text("progress.json", JSON.stringify(_progress(1).to_data()))
	var newest: String = JSON.stringify(_progress(7).to_data())
	Fx.write_text("progress.json.tmp", newest)
	assert_eq(store.load_progress().levels[&"r1_l1"], 7)
	assert_false(Fx.exists("progress.json.tmp"))
	assert_eq(Fx.read_text("progress.json"), newest)
	# The store now knows that text, so the next write keeps it as the backup.
	assert_true(store.save_progress(_progress(3)))
	assert_eq(Fx.read_text("progress.json.bak"), newest)


func test_bad_tmp_is_deleted_and_the_file_is_used() -> void:
	var good: String = JSON.stringify(_progress(3).to_data())
	Fx.write_text("progress.json", good)
	Fx.write_text("progress.json.tmp", good.left(good.length() - 6))
	assert_eq(store.load_progress().levels[&"r1_l1"], 3)
	assert_false(Fx.exists("progress.json.tmp"))
	assert_eq(Fx.read_text("progress.json"), good)


func test_tmp_without_known_format_is_deleted() -> void:
	Fx.write_text("settings.json", "{\"format\":1,\"sound\":false}")
	Fx.write_text("settings.json.tmp", "{\"sound\":true}")
	assert_false(store.load_settings().sound_on)
	assert_false(Fx.exists("settings.json.tmp"))


func test_bak_is_used_when_the_file_is_bad_or_gone() -> void:
	Fx.write_text("progress.json.bak", JSON.stringify(_progress(1).to_data()))
	Fx.write_text("progress.json", "{\"format\": 1, \"levels\": {\"r1_l1\": 7")
	assert_eq(store.load_progress().levels[&"r1_l1"], 1)
	DirAccess.remove_absolute(Fx.path("progress.json"))
	assert_eq(SaveStore.new(Fx.WORK).load_progress().levels[&"r1_l1"], 1)


func test_bak_after_two_writes_and_a_corrupted_file() -> void:
	assert_true(store.save_progress(_progress(1)))
	assert_true(store.save_progress(_progress(3)))
	Fx.write_bytes("progress.json", PackedByteArray([0xff, 0x00, 0x13]))
	var loaded: Progress = SaveStore.new(Fx.WORK).load_progress()
	assert_eq(loaded.levels[&"r1_l1"], 1, "one save behind, from the .bak")


func test_newest_valid_copy_wins_in_order() -> void:
	Fx.write_text("settings.json.bak", "{\"format\":1,\"sound\":true}")
	Fx.write_text("settings.json", "{\"format\":1,\"sound\":false}")
	assert_false(store.load_settings().sound_on, "the file beats the .bak")
	Fx.write_text("settings.json.tmp", "{\"format\":1,\"sound\":true}")
	assert_true(SaveStore.new(Fx.WORK).load_settings().sound_on, "the .tmp beats the file")


func test_good_file_with_bad_fields_keeps_the_good_ones() -> void:
	Fx.write_text("progress.json", "{\"format\": 1, \"levels\": {\"r1_l1\": 3, \"r1_l2\": 99}, \"seen\": 5, \"counters\": {\"runs_won\": 2}}")
	var loaded: Progress = store.load_progress()
	assert_eq(loaded.levels, {&"r1_l1": 3} as Dictionary[StringName, int])
	assert_eq(loaded.seen.size(), 0)
	assert_eq(loaded.counters[&"runs_won"], 2)


func test_locked_file_is_never_written_renamed_or_deleted() -> void:
	# A folder where the file should be: it exists but cannot be opened.
	DirAccess.make_dir_recursive_absolute(Fx.path("settings.json/inner"))
	Fx.write_text("settings.json.bak", "{\"format\":1,\"sound\":false}")
	Fx.write_text("progress.json.tmp", "{\"format\":1}")
	DirAccess.make_dir_recursive_absolute(Fx.path("progress.json.bak/inner"))
	assert_true(store.load_settings().sound_on, "defaults in memory")
	assert_true(store.is_locked(SaveStore.SETTINGS_FILE))
	assert_false(store.save_settings(_settings(false)))
	assert_false(Fx.exists("settings.json.tmp"))
	assert_eq(Fx.read_text("settings.json.bak"), "{\"format\":1,\"sound\":false}")
	assert_true(DirAccess.dir_exists_absolute(Fx.path("settings.json/inner")))
	assert_eq(store.load_progress().levels.size(), 0)
	assert_false(store.save_progress(_progress(7)))
	assert_eq(Fx.read_text("progress.json.tmp"), "{\"format\":1}", "a locked file's .tmp is left alone")
	assert_false(Fx.exists("progress.json"))


func test_newer_format_is_left_alone() -> void:
	var newer: String = "{\"format\": 2, \"sound\": false, \"volume\": 30}"
	Fx.write_text("settings.json", newer)
	assert_true(store.load_settings().sound_on, "defaults in memory")
	assert_true(store.is_locked(SaveStore.SETTINGS_FILE))
	assert_false(store.save_settings(_settings(false)))
	assert_eq(Fx.read_text("settings.json"), newer)
	assert_false(Fx.exists("settings.json.tmp"))
	assert_false(Fx.exists("settings.json.bak"))
	# A newer .bak behind a bad file is respected too.
	Fx.write_text("progress.json", "garbage")
	Fx.write_text("progress.json.bak", "{\"format\": 7}")
	store.load_progress()
	assert_false(store.save_progress(_progress(1)))
	assert_eq(Fx.read_text("progress.json"), "garbage")


func test_folder_at_the_tmp_blocks_the_save() -> void:
	assert_true(store.save_progress(_progress(1)))
	# A folder at the .tmp exists but cannot be opened, so the file is locked.
	DirAccess.make_dir_recursive_absolute(Fx.path("progress.json.tmp/inner"))
	assert_false(store.save_progress(_progress(3)))
	assert_eq(SaveStore.new(Fx.WORK).load_progress().levels.size(), 0, "a folder at the .tmp locks the file")


func test_failed_rename_while_the_file_is_held_open() -> void:
	if OS.get_name() != "Windows":
		return # Android and Linux rename over an open file in one step.
	assert_true(store.save_progress(_progress(1)))
	var old: String = Fx.read_text("progress.json")
	var hold: FileAccess = FileAccess.open(Fx.path("progress.json"), FileAccess.READ)
	assert_not_null(hold)
	assert_false(store.save_progress(_progress(7)), "the rename fails while the target is held")
	assert_eq(Fx.read_text("progress.json"), old, "the old save is intact")
	var newest: String = Fx.read_text("progress.json.tmp")
	assert_eq(newest, JSON.stringify(_progress(7).to_data()), "the .tmp holds the newest save")
	# Still held at the next launch: the .tmp is used though it cannot move into place.
	assert_eq(SaveStore.new(Fx.WORK).load_progress().levels[&"r1_l1"], 7)
	hold.close()
	hold = null
	# The next write tries again and succeeds.
	assert_true(store.save_progress(_progress(5)))
	assert_false(Fx.exists("progress.json.tmp"))
	assert_eq(SaveStore.new(Fx.WORK).load_progress().levels[&"r1_l1"], 5)


func test_over_cap_text_is_never_written() -> void:
	var progress: Progress = Progress.new()
	for i: int in Progress.MAX_ENTRIES:
		var id: StringName = StringName("a%s" % str(i).lpad(31, "0"))
		progress.record_level(id, 7)
		progress.record_twist(id)
		progress.mark_seen(id)
	assert_true(store.save_progress(progress), "the largest real progress fits")
	assert_eq(SaveStore.new(Fx.WORK).load_progress().levels.size(), Progress.MAX_ENTRIES)

