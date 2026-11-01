extends "res://tests/base_test.gd"
## AT-159 through the real GameSession: Bart's phone save resumes, a chain of
## two touching 2^50 tiles commits, the score goes past the old 64 bit limit
## exactly, and the saved result round trips. Kept apart from
## test_save_at_159.gd so the save half runs even while GameSession changes.

const F := preload("res://tests/save/save_fixtures.gd")

const RUN_FIXTURE: String = "res://tests/save/fixtures/bart_2026_10_20_run.json"
const PROFILE_FIXTURE: String = "res://tests/save/fixtures/bart_2026_10_20_profile.json"
const SCORE: String = "9221253119629040934"
const SCORE_AFTER: String = "9223504919442726182"

var _dir: String = ""
var _service: SaveService = null
var _config: GameConfig = GameConfig.new()


func before_each() -> void:
	_dir = F.make_temp_dir()
	_config = GameConfig.new()
	F.write_bytes(_dir.path_join("run.json"), FileAccess.get_file_as_bytes(RUN_FIXTURE))
	F.write_bytes(_dir.path_join("profile.json"), FileAccess.get_file_as_bytes(PROFILE_FIXTURE))
	_service = SaveService.new(_dir)


func after_each() -> void:
	F.remove_temp_dir(_dir)


func test_at_159_a_chain_commits_through_the_session() -> void:
	var records: Records = Records.new()
	var settings: Settings = Settings.new()
	_service.load_profile(settings, records)
	var saved: RunState = _service.load_run(_config)
	assert_true(saved != null, "Bart's run loads")
	if saved == null:
		return
	var rng: RunRandom = RunRandom.new()
	rng.set_seed(159)
	var session: GameSession = GameSession.new(_config, rng, records)
	session.resume(saved)
	session.move_shown()    # the view has shown the resumed board
	assert_true(session.is_run_in_progress(), "the run is in play")
	assert_false(session.is_offer_open(), "with a valid move, so no offer")
	assert_eq(F.text(session.state.score), SCORE, "the saved score")
	assert_eq(session.stars(), 46, "46 stars")
	var chain: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 1)]
	assert_true(session.joinable_cells([chain[0]] as Array[Vector2i]).has(chain[1]), "(2,1) is highlighted from (1,0)")
	assert_true(session.begin_drag(), "a drag starts")
	var result: MoveResult = session.commit_chain(chain)
	assert_true(result != null and result.accepted, "the chain commits")
	assert_eq(F.text(session.state.score), SCORE_AFTER, "the old score plus 2^51, exactly")
	assert_eq(F.text(session.records.best_score), SCORE_AFTER, "Best Score follows live")
	assert_true(_service.save_run(session.state), "the run saves")
	assert_true(_service.save_profile(settings, session.records), "the records save")
	var reopened: SaveService = SaveService.new(_dir)
	var again: RunState = reopened.load_run(_config)
	assert_true(again != null and session.state.equals(again), "and reload the same")
	var loaded_records: Records = Records.new()
	reopened.load_profile(Settings.new(), loaded_records)
	assert_eq(F.text(loaded_records.best_score), SCORE_AFTER, "Best Score saved")
	assert_eq(loaded_records.best_tile, 56, "Best Tile still 2^56")
