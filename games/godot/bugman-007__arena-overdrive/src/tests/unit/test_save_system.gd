extends GutTest

const PATH := "user://test_save.json"
const LEGACY := "user://test_legacy.cfg"
var SaveScript := preload("res://autoload/save_system.gd")
var save: Node


func _clean() -> void:
	for p in [PATH, PATH + ".tmp", PATH + ".corrupt", LEGACY]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func before_each() -> void:
	_clean()
	save = autofree(SaveScript.new())
	save.path = PATH
	save.legacy_path = LEGACY
	save.data = save.load_data()


func after_all() -> void:
	_clean()


func test_defaults_when_missing() -> void:
	assert_eq(save.data["version"], SaveScript.CURRENT_VERSION)
	assert_eq(save.get_coins(), 0)
	assert_true(save.is_unlocked(&"vanguard"))


func test_roundtrip() -> void:
	save.add_coins(120)
	save.set_meta_level(&"power", 2)
	save.add_achievement(&"first_blood")
	assert_eq(save.save_data(), OK)
	var other: Node = autofree(SaveScript.new())
	other.path = PATH
	other.data = other.load_data()
	assert_eq(other.get_coins(), 120)
	assert_eq(other.get_meta_level(&"power"), 2)
	assert_true(other.has_achievement(&"first_blood"))


func test_migrate_v1_to_current() -> void:
	var d: Dictionary = SaveScript.migrate({"version": 1, "high_score": 777})
	assert_eq(d["version"], 3)
	assert_eq(int(d["stats"]["best_score"]), 777)
	assert_eq(d["achievements"], [])
	assert_eq(d["unlocked_characters"], ["vanguard"])


func test_migrate_v2_keeps_progress() -> void:
	var v2 := {"version": 2, "coins": 50, "meta": {"power": 1}, "stats": {"best_score": 10, "best_wave": 3, "total_kills": 5, "runs": 1, "coins_earned": 50}}
	var d: Dictionary = SaveScript.migrate(v2)
	assert_eq(d["version"], 3)
	assert_eq(int(d["coins"]), 50)
	assert_eq(int(d["stats"]["bosses_killed"]), 0)
	assert_eq(int(d["meta"]["power"]), 1)


func test_migration_fills_missing_keys() -> void:
	var d: Dictionary = SaveScript.migrate({"version": 3})
	assert_true(d.has("stats"))
	assert_true((d["stats"] as Dictionary).has("runs"))


func test_legacy_highscore_cfg_is_imported() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "high_score", 4321)
	cfg.save(LEGACY)
	assert_eq(int(save.load_data()["stats"]["best_score"]), 4321)


func test_corrupt_file_recovers_and_backs_up() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	var d: Dictionary = save.load_data()
	assert_eq(d["version"], SaveScript.CURRENT_VERSION)
	assert_true(FileAccess.file_exists(PATH + ".corrupt"))


func test_spend_coins() -> void:
	save.add_coins(100)
	assert_false(save.spend_coins(150))
	assert_true(save.spend_coins(60))
	assert_eq(save.get_coins(), 40)


func test_record_run_updates_lifetime_stats() -> void:
	assert_true(save.record_run({"score": 500, "kills": 20, "wave": 4, "coins": 30, "bosses": 1}))
	assert_false(save.record_run({"score": 100, "kills": 5, "wave": 2, "coins": 0}))
	assert_eq(save.stat("runs"), 2)
	assert_eq(save.stat("total_kills"), 25)
	assert_eq(save.stat("best_score"), 500)
	assert_eq(save.stat("best_wave"), 4)
	assert_eq(save.stat("bosses_killed"), 1)
	assert_eq(save.get_coins(), 30)
	assert_eq(save.stat("coins_earned"), 30)


func test_unlock_and_achievements_are_idempotent() -> void:
	save.unlock_character(&"ranger")
	save.unlock_character(&"ranger")
	assert_eq((save.data["unlocked_characters"] as Array).count("ranger"), 1)
	assert_true(save.add_achievement(&"slayer"))
	assert_false(save.add_achievement(&"slayer"))
