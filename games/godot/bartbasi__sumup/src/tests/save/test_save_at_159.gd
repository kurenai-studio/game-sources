extends "res://tests/base_test.gd"
## AT-159, the save and core half: Bart's real save from his phone
## (2026-10-20 build, copied unchanged into tests/save/fixtures/) loads
## exactly as saved, writes back byte for byte the same, and its chains now
## commit. The GameSession half is in test_save_at_159_session.gd.
##
## The fixture files are in tests/, which the Android export excludes, so
## they never ship.

const F := preload("res://tests/save/save_fixtures.gd")

const RUN_FIXTURE: String = "res://tests/save/fixtures/bart_2026_10_20_run.json"
const PROFILE_FIXTURE: String = "res://tests/save/fixtures/bart_2026_10_20_profile.json"
const RUN_MD5: String = "beb18cee83c937b06f34656e43557021"
const PROFILE_MD5: String = "7b6116cf901e6e3ce44cf493780492bf"
const SCORE: String = "9221253119629040934"
const SCORE_AFTER: String = "9223504919442726182"
const INT64_MAX_TEXT: String = "9223372036854775807"

var _dir: String = ""
var _service: SaveService = null
var _config: GameConfig = GameConfig.new()


func before_each() -> void:
	_dir = F.make_temp_dir()
	_config = GameConfig.new()
	F.write_bytes(_dir.path_join("run.json"), _fixture(RUN_FIXTURE))
	F.write_bytes(_dir.path_join("profile.json"), _fixture(PROFILE_FIXTURE))
	_service = SaveService.new(_dir)


func after_each() -> void:
	F.remove_temp_dir(_dir)


static func _fixture(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path)


## The fixture as plain JSON data, read on its own, to compare field by field.
func _file_data(path: String) -> Dictionary:
	return JSON.parse_string(_fixture(path).get_string_from_utf8())


func _list(values: PackedInt64Array) -> Array:
	var result: Array = []
	for value: int in values:
		result.append(value)
	return result


## The file's exponents as ints (the JSON parser gives floats).
func _ints(list: Array) -> Array:
	var result: Array = []
	for value: Variant in list:
		result.append(int(value))
	return result


func test_the_fixtures_are_bart_files_unchanged() -> void:
	assert_eq(FileAccess.get_md5(RUN_FIXTURE), RUN_MD5, "run.json md5")
	assert_eq(FileAccess.get_md5(PROFILE_FIXTURE), PROFILE_MD5, "profile.json md5")


func test_the_run_loads_exactly_as_saved() -> void:
	var file: Dictionary = _file_data(RUN_FIXTURE)
	var state: RunState = _service.load_run(_config)
	assert_true(state != null, "Bart's run loads")
	if state == null:
		return
	assert_eq(_list(state.cells), _ints(file["cells"]), "every cell")
	assert_eq(F.text(state.score), SCORE, "the score, exactly")
	assert_eq(file["score"], SCORE, "as in the file")
	assert_eq(state.run_highest, 56, "run highest tile 2^56")
	assert_eq(state.free_used, 15, "15 free boosters used")
	assert_eq(F.text(state.best_at_start), file["best_at_start"], "the Best Score when the run began")
	var snapshot: Dictionary = file["snapshot"]
	assert_true(state.has_snapshot(), "with its Undo snapshot")
	assert_eq(_list(state.snapshot_cells), _ints(snapshot["cells"]), "every snapshot cell")
	assert_eq(F.text(state.snapshot_points), snapshot["points"], "the snapshot points")
	assert_eq(CoreRules.stars(state.run_highest, _config), 46, "46 stars")
	assert_eq(CoreRules.free_earned(state.run_highest, _config), 15, "15 free boosters earned")
	assert_eq(CoreRules.free_held(state, _config), 0, "all of them used")
	assert_true(state.score.fits_int(), "still just below 2^63 minus 1 before the chain")


func test_the_profile_loads_exactly_as_saved() -> void:
	var settings: Settings = Settings.new()
	var records: Records = Records.new()
	_service.load_profile(settings, records)
	var problems: PackedStringArray = SaveCodec.data_to_profile(_file_data(PROFILE_FIXTURE), Settings.new(), Records.new())
	assert_eq(problems.size(), 0, "fully valid: %s" % ", ".join(problems))
	assert_true(settings.sound_on, "sound on")
	assert_eq(settings.skin_id, &"slate", "Slate")
	assert_eq(F.text(records.best_score), SCORE, "Best Score, exactly")
	assert_eq(records.best_tile, 56, "Best Tile 2^56")


func test_saving_writes_back_byte_for_byte_the_same() -> void:
	var settings: Settings = Settings.new()
	var records: Records = Records.new()
	_service.load_profile(settings, records)
	var state: RunState = _service.load_run(_config)
	assert_true(state != null, "loads")
	assert_true(_service.save_run(state), "the run saves again")
	assert_true(_service.save_profile(settings, records), "the profile saves again")
	assert_eq(F.read_bytes(_dir.path_join("run.json")), _fixture(RUN_FIXTURE), "run.json is the same bytes")
	assert_eq(F.read_bytes(_dir.path_join("profile.json")), _fixture(PROFILE_FIXTURE), "profile.json is the same bytes")
	var again: RunState = SaveService.new(_dir).load_run(_config)
	assert_true(again != null and state.equals(again), "and loads back the same")


func test_the_move_check_and_the_highlight_find_moves() -> void:
	var state: RunState = _service.load_run(_config)
	assert_true(state != null, "loads")
	if state == null:
		return
	assert_true(CoreRules.has_valid_move(state.cells, state.score, _config), "a valid move")
	var pairs: int = 0
	for index: int in state.cells.size():
		var cell: Vector2i = CoreRules.cell_of(index, state.columns)
		var joinable: Array[Vector2i] = CoreRules.joinable_cells(state.cells, state.score, [cell] as Array[Vector2i], _config)
		for other_index: int in state.cells.size():
			var other: Vector2i = CoreRules.cell_of(other_index, state.columns)
			if CoreRules.touching(cell, other) and state.cells[other_index] == state.cells[index]:
				pairs += 1
				assert_true(joinable.has(other), "%s joins %s" % [str(other), str(cell)])
	assert_true(pairs > 0, "there are touching equal tiles (%d ordered pairs)" % pairs)


func test_a_chain_of_two_50s_commits_past_the_old_limit() -> void:
	var records: Records = Records.new()
	_service.load_profile(Settings.new(), records)
	var state: RunState = _service.load_run(_config)
	assert_true(state != null, "loads")
	if state == null:
		return
	# The first touching equal pair in reading order: (1,0) and (2,1), both 2^50.
	var chain: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 1)]
	assert_eq(state.value_at(chain[0]), 50, "(1,0) is 2^50")
	assert_eq(state.value_at(chain[1]), 50, "(2,1) is 2^50")
	var rng: RunRandom = RunRandom.new()
	rng.set_seed(159)
	var result: MoveResult = RunRules.commit_chain(state, records, chain, rng, _config)
	assert_true(result.accepted, "the commit is accepted")
	assert_eq(F.text(state.score), SCORE_AFTER, "the old score plus 2^51, exactly")
	assert_eq(F.text(result.points), "2251799813685248", "2^51 points")
	assert_true(state.score.compare(BigNum.parse(INT64_MAX_TEXT, 19)) > 0, "above 2^63 minus 1")
	assert_eq(state.value_at(Vector2i(2, 1)), 51, "the result is 2^51 on the last tile")
	assert_eq(F.text(records.best_score), SCORE_AFTER, "Best Score follows it live")
	assert_true(_service.save_run(state), "the new run saves")
	assert_true(_service.save_profile(Settings.new(), records), "the new records save")
	var again: RunState = SaveService.new(_dir).load_run(_config)
	assert_true(again != null and state.equals(again), "and reload the same")
	var data: Dictionary = JSON.parse_string(F.read_text(_dir.path_join("run.json")))
	assert_eq(data["score"], SCORE_AFTER, "the file holds the new score as digits")
	var loaded_records: Records = Records.new()
	SaveService.new(_dir).load_profile(Settings.new(), loaded_records)
	assert_eq(F.text(loaded_records.best_score), SCORE_AFTER, "the profile holds the new Best Score")


func test_the_numbers_read_as_designed() -> void:
	var state: RunState = _service.load_run(_config)
	assert_true(state != null, "loads")
	if state == null:
		return
	assert_eq(NumberFormat.score(state.score), "9,221,253,119B", "the score before the chain")
	assert_eq(NumberFormat.score(BigNum.parse(SCORE_AFTER, 19)), "9,223,504,919B", "and after")
	assert_eq(NumberFormat.tile_label(56), "64Q", "the 2^56 tiles")
