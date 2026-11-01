# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Content tiers in src/save/ (docs/ARCHITECTURE.md 14.8, RULES 14.9 and 16): GameData's
## checks of the tiers' levels and Progress.tier(). run.json `tiers` is empty until region
## 5's data lands (E5.1), so these tests give a copy of the real data fixture tiers whose
## levels are the boss levels of regions 1 to 4, standing in for those of regions 5 to 8.

const Fx: GDScript = preload("res://tests/save/fixtures/save_fixtures.gd")

## The last level of each region of today's campaign, in campaign order.
const BOSS_LEVELS: Array[String] = ["r1_l6", "r2_l6", "r3_l6", "r4_l6"]

var root: String = Fx.path("data")


func before_each() -> void:
	Fx.fresh()
	for sub: String in ["stats", "levels", "runs", "cards", "segments"]:
		DirAccess.make_dir_recursive_absolute(root.path_join(sub))
		for file_name: String in DirAccess.get_files_at(Fx.DATA.path_join(sub)):
			if file_name.get_extension() == "json":
				_put(sub + "/" + file_name, FileAccess.get_file_as_string(Fx.DATA.path_join(sub).path_join(file_name)))


func after_each() -> void:
	Fx.clean()


func _put(relative: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(root.path_join(relative), FileAccess.WRITE)
	file.store_string(text)
	file.close()


## Gives the copy's run.json one tier per level, each listing nothing new.
func _set_tiers(levels: Array) -> void:
	var path: String = root.path_join("runs/run.json")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var list: Array = []
	for level: Variant in levels:
		list.append({"level": level, "towers": [], "creatures": [], "bosses": [], "grid": ""})
	data["tiers"] = list
	_put("runs/run.json", JSON.stringify(data))


func _game(levels: Array) -> GameData:
	_set_tiers(levels)
	return GameData.load_from(root)


func _has_problem(game: GameData, part: String) -> bool:
	for problem: String in game.problems:
		if problem.contains(part):
			return true
	return false


# GameData's checks of the tiers' levels (14.8)

func test_tiers_on_the_last_levels_of_regions_in_campaign_order_load() -> void:
	for count: int in BOSS_LEVELS.size() + 1:
		var game: GameData = _game(BOSS_LEVELS.slice(0, count))
		assert_eq(game.problems, PackedStringArray(), "%d tiers" % count)
		assert_not_null(game.run)
		if game.run != null:
			assert_eq(game.run.tiers.size(), count)
	var skipping: GameData = _game(["r2_l6", "r4_l6"])
	assert_eq(skipping.problems, PackedStringArray(), "a tier may skip a region, as long as the order holds")


func test_a_tier_level_that_is_not_the_last_of_a_region_is_a_problem() -> void:
	var cases: Dictionary = {
		"the first level of a region": ["r1_l1"],
		"the fifth level of a region": ["r1_l6", "r2_l5"],
		"a level in no region": ["r9_l6"],
		"a level id that names no file": ["nowhere"],
	}
	for name: String in cases:
		var game: GameData = _game(cases[name])
		assert_true(_has_problem(game, "is not the last level of a campaign region"), "%s: %s" % [name, "\n".join(game.problems)])
		assert_null(game.run, "%s: no run data" % name)


func test_tiers_out_of_campaign_order_are_a_problem() -> void:
	var cases: Dictionary = {
		"two regions swapped": ["r2_l6", "r1_l6"],
		"the same level twice": ["r1_l6", "r1_l6"],
		"the last out of place": ["r1_l6", "r2_l6", "r4_l6", "r3_l6"],
	}
	for name: String in cases:
		var game: GameData = _game(cases[name])
		assert_true(_has_problem(game, "campaign order"), "%s: %s" % [name, "\n".join(game.problems)])
		assert_null(game.run, "%s: no run data" % name)


func test_a_tier_problem_names_its_tier() -> void:
	var game: GameData = _game(["r1_l6", "r2_l3", "r3_l6"])
	assert_eq(game.problems, PackedStringArray(["run.json: tiers[1].level: r2_l3 is not the last level of a campaign region"]))


func test_the_real_data_has_valid_tiers() -> void:
	var game: GameData = GameData.load_from()
	assert_eq(game.problems, PackedStringArray())
	assert_not_null(game.run)
	assert_true(game.run.tiers.size() <= RunData.MAX_TIERS)


# Progress.tier() (RULES 14.9: the number of these boss levels cleared)

func test_the_tier_counts_the_tier_levels_cleared() -> void:
	var game: GameData = _game(BOSS_LEVELS)
	assert_not_null(game.run)
	var progress: Progress = Progress.new()
	assert_eq(progress.tier(game), 0, "nothing cleared")
	for id: StringName in [&"r1_l1", &"r1_l5", &"r2_l1"]:
		progress.record_level(id, 7)
	assert_eq(progress.tier(game), 0, "other levels do not count, even with 3 stars")
	progress.record_twist(&"r1_l6")
	assert_eq(progress.tier(game), 0, "a Twist record alone is no clear")
	progress.record_level(&"r1_l6", 1)
	assert_eq(progress.tier(game), 1, "a Relaxed win counts (star 1 only)")
	progress.record_level(&"r2_l6", 7)
	assert_eq(progress.tier(game), 2, "a Normal win counts")
	progress.record_level(&"r3_l6", 1)
	progress.record_level(&"r4_l6", 3)
	assert_eq(progress.tier(game), 4, "every tier")


func test_the_tier_only_grows() -> void:
	var game: GameData = _game(BOSS_LEVELS)
	var progress: Progress = Progress.new()
	var last: int = 0
	var order: Array[StringName] = [&"r1_l6", &"r1_l6", &"r2_l6", &"r1_l2", &"r3_l6", &"r2_l6", &"r4_l6", &"r4_l6"]
	for i: int in order.size():
		progress.record_level(order[i], [1, 1, 3, 7, 1, 7, 1, 7][i])
		var now: int = progress.tier(game)
		assert_true(now >= last, "step %d: %d after %d" % [i, now, last])
		last = now
	assert_eq(last, 4)
	progress.record_level(&"r1_l6", 0)
	progress.record_level(&"r1_l6", -1)
	assert_eq(progress.tier(game), 4, "recording nothing new takes nothing away")


func test_the_tier_counts_cleared_levels_not_a_prefix() -> void:
	# Contract 14.8 counts how many tier levels are cleared. Play clears them in order,
	# since each region opens after the one before; a tampered progress.json that holds
	# only a later one still gives a count from 0 to the number of tiers.
	var game: GameData = _game(BOSS_LEVELS)
	var progress: Progress = Progress.new()
	progress.record_level(&"r4_l6", 1)
	assert_eq(progress.tier(game), 1)


func test_the_tier_is_never_above_the_tier_count() -> void:
	var progress: Progress = Progress.new()
	for region: int in 4:
		for level: int in 6:
			progress.record_level(StringName("r%d_l%d" % [region + 1, level + 1]), 7)
	for count: int in BOSS_LEVELS.size() + 1:
		var game: GameData = _game(BOSS_LEVELS.slice(0, count))
		assert_eq(progress.tier(game), count, "%d tiers, all cleared" % count)


func test_the_tier_is_0_without_run_data() -> void:
	var progress: Progress = Progress.new()
	progress.record_level(&"r1_l6", 7)
	assert_eq(progress.tier(null), 0, "no game data")
	var empty: GameData = GameData.new()
	assert_eq(progress.tier(empty), 0, "no run data")
	var broken: GameData = _game(["r1_l3"])
	assert_null(broken.run)
	assert_eq(progress.tier(broken), 0, "run data refused")
	var real: GameData = GameData.load_from()
	assert_true(progress.tier(real) <= real.run.tiers.size())
	if real.run.tiers.is_empty():
		assert_eq(progress.tier(real), 0, "today's run.json has no tiers")


func test_the_tier_comes_back_from_progress_json() -> void:
	# Nothing new is saved for the tier: it comes from the level records (RULES 14.9).
	var game: GameData = _game(BOSS_LEVELS)
	var progress: Progress = Progress.new()
	progress.record_level(&"r1_l6", 1)
	progress.record_level(&"r2_l6", 3)
	var store: SaveStore = SaveStore.new(Fx.WORK)
	assert_true(store.save_progress(progress))
	assert_false(JSON.stringify(progress.to_data()).contains("tier"), "progress.json holds no tier")
	var loaded: Progress = SaveStore.new(Fx.WORK).load_progress()
	assert_eq(loaded.tier(game), 2)
