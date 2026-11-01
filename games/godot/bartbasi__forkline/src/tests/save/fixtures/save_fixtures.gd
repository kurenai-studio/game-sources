# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## Shared helpers for tests/save/. Every test writes only inside WORK, a folder under
## user://tests/save/ that each test removes in before_each() and after_each(). WORK is
## named after the process, so two test runs at once never wipe each other's files.

## The seeded player of tests/run/. Runs and dailies here use the real data in data/.
## Its base pool holds gold_purse, an economy card that is not once, so a draft is never
## empty.
const Player: GDScript = preload("res://tests/run/fixtures/run_player.gd")

const TEST_ROOT: String = "user://tests/save"
const DATA: String = "res://data"
static var WORK: String = "%s/work_%d" % [TEST_ROOT, OS.get_process_id()]


## Removes WORK and everything in it, then makes it again, empty. Another run's clean()
## can remove the empty parent folders while WORK is being made, so it tries again.
static func fresh() -> void:
	clean()
	for attempt: int in 20:
		DirAccess.make_dir_recursive_absolute(WORK)
		if DirAccess.dir_exists_absolute(WORK):
			return


## Removes this run's WORK, then the parent folders if no other run still uses them.
## Refuses any path outside user://tests/save.
static func clean() -> void:
	_remove_tree(WORK)
	DirAccess.remove_absolute(TEST_ROOT)               # only succeeds when empty
	DirAccess.remove_absolute("user://tests")


static func _remove_tree(dir_path: String) -> void:
	if not dir_path.begins_with(TEST_ROOT + "/") or dir_path.contains(".."):
		return
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	for sub_dir: String in DirAccess.get_directories_at(dir_path):
		_remove_tree(dir_path.path_join(sub_dir))
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(file_name))
	DirAccess.remove_absolute(dir_path)


static func path(file_name: String) -> String:
	return WORK.path_join(file_name)


static func write_bytes(file_name: String, bytes: PackedByteArray) -> void:
	var file: FileAccess = FileAccess.open(path(file_name), FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


static func write_text(file_name: String, text: String) -> void:
	write_bytes(file_name, text.to_utf8_buffer())


static func read_text(file_name: String) -> String:
	if not FileAccess.file_exists(path(file_name)):
		return ""
	return FileAccess.get_file_as_string(path(file_name))


static func exists(file_name: String) -> bool:
	return FileAccess.file_exists(path(file_name))


## The real data, run files included, so runs and dailies can be started and loaded.
static func game() -> GameData:
	return GameData.load_from(DATA)


## A campaign level battle, played into its first wave so creatures are on the map.
static func battle_mid_wave(game_data: GameData, level_id: StringName, relaxed: bool, ticks: int) -> Battle:
	var battle: Battle = Battle.create(game_data.levels[level_id], game_data.catalog, relaxed, [])
	var spot: Vector2i = battle.level.spots[0]
	battle.place_tower(spot, battle.level.towers[0])
	battle.start_next_wave()
	for i: int in ticks:
		battle.step()
	return battle


static func saved(mode: StringName, battle: Battle) -> SavedGame:
	var game_save: SavedGame = SavedGame.new()
	game_save.mode = mode
	game_save.level_id = battle.level.id if mode == SavedGame.LEVEL else &""
	game_save.battle = battle
	return game_save


## A new run (day "") or daily on the real run data. The pool is the base cards, or
## every card for a daily, as the App passes them (3.4).
static func session(game_data: GameData, run_seed: int, day: String = "", relaxed: bool = false) -> RunSession:
	var pool: Array[StringName] = game_data.run.card_ids() if day != "" else game_data.run.pool({})
	return RunSession.start(run_seed, day, relaxed, pool, game_data.run, game_data.catalog)


## A daily for a day, with its seed from the day.
static func daily(game_data: GameData, day: String) -> RunSession:
	return session(game_data, RunSeeds.daily_seed(day), day)


## A run played by a seeded player until check(session) is true (or the run ends).
static func play_until(session_now: RunSession, player: RefCounted, check: Callable) -> bool:
	for guard: int in 200000:
		if check.call(session_now):
			return true
		if not player.advance(session_now):
			return false
	return false


## A seeded player with plenty of gold and lives, so runs go on for long.
static func player(seed_value: int) -> RefCounted:
	var p: RefCounted = Player.new(seed_value)
	p.rich = true
	return p


## A run on every card, played by a seeded rich player until check(session) is true. In
## an open draft choose(session, offers) picks first; when it returns &"" the player
## picks. Null when the run ends or a pick is refused first. Card effects come only from
## real picks, so the saved run's picks match its battle (5.6).
static func run_with(game_data: GameData, run_seed: int, choose: Callable, check: Callable) -> RunSession:
	var s: RunSession = RunSession.start(run_seed, "", false, game_data.run.card_ids(), game_data.run, game_data.catalog)
	var p: RefCounted = player(run_seed)
	for guard: int in 200000:
		if check.call(s):
			return s
		if s.draft_open():
			var id: StringName = choose.call(s, s.offers())
			if id != &"":
				if s.pick(id) != Battle.DONE:
					return null
				continue
		if not p.advance(s):
			return null
	return null


## A run that has just picked card_id in its first draft, in the build phase after
## wave 1. Tries seeds in order, so it always finds the same run. Null when none offers it.
static func run_after_pick(game_data: GameData, card_id: StringName) -> RunSession:
	for run_seed: int in range(1, 400):
		var s: RunSession = run_with(game_data, run_seed,
			func(_s: RunSession, _offers: Array[StringName]) -> StringName: return &"",
			func(at: RunSession) -> bool: return at.draft_open())
		if s != null and s.offers().has(card_id) and s.pick(card_id) == Battle.DONE:
			return s
	return null


## The saved game of a run or daily.
static func saved_run(session_now: RunSession) -> SavedGame:
	var game_save: SavedGame = saved(SavedGame.DAILY if session_now.daily else SavedGame.RUN, session_now.battle)
	game_save.run = session_now
	return game_save


## A saved game's data after a trip through JSON text, as a file brings it back.
static func through_json(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data))


## Everything that must match after equal play: the battle, the run and the result.
static func run_text(session_now: RunSession) -> String:
	return Player.fingerprint(session_now)


static func battle_text(battle: Battle) -> String:
	return JSON.stringify(battle.to_data())


## Every hostile byte pattern a file can hold, by name. Each must fall back safely.
static func hostile_files(valid_text: String, cap: int) -> Dictionary:
	var cases: Dictionary = {}
	cases["empty"] = PackedByteArray()
	cases["truncated"] = valid_text.left(valid_text.length() / 2).to_ascii_buffer()
	cases["corrupt"] = "{\"format\": 1, \"sound\": tru".to_ascii_buffer()
	cases["garbage"] = PackedByteArray([0xff, 0xfe, 0x00, 0x41, 0x7b, 0x22, 0x10, 0x80])
	var nul_end: PackedByteArray = "{\"format\": 1}".to_ascii_buffer()
	nul_end.append(0)
	cases["nul byte"] = nul_end
	var nul_inside: PackedByteArray = valid_text.to_ascii_buffer()
	nul_inside[nul_inside.size() / 2] = 0
	cases["nul inside"] = nul_inside
	cases["high bytes"] = "{\"format\": 1, \"x\": \"café\"}".to_utf8_buffer()
	cases["huge"] = ("{\"format\": 1, \"pad\": \"" + "a".repeat(cap) + "\"}").to_ascii_buffer()
	cases["deep nesting"] = ("{\"format\": 1, \"levels\": " + "[".repeat(5000) + "]".repeat(5000) + "}").to_ascii_buffer()
	cases["deep objects"] = ("{\"format\": 1, \"sound\": " + "{\"a\":".repeat(3000) + "1" + "}".repeat(3000) + "}").to_ascii_buffer()
	cases["array root"] = "[1, 2, 3]".to_ascii_buffer()
	cases["string root"] = "\"settings\"".to_ascii_buffer()
	cases["number root"] = "1e999".to_ascii_buffer()
	cases["null root"] = "null".to_ascii_buffer()
	cases["nan"] = "{\"format\": NaN}".to_ascii_buffer()
	cases["infinity"] = "{\"format\": 1e999}".to_ascii_buffer()
	cases["negative infinity"] = "{\"format\": -1e999}".to_ascii_buffer()
	cases["format as text"] = "{\"format\": \"1\"}".to_ascii_buffer()
	cases["format fraction"] = "{\"format\": 1.5}".to_ascii_buffer()
	cases["format zero"] = "{\"format\": 0}".to_ascii_buffer()
	cases["object text"] = "{\"format\": \"Object(Node,\\\"script\\\":\\\"res://x.gd\\\")\"}".to_ascii_buffer()
	cases["resource path"] = "{\"format\": 1, \"battle\": \"res://src/sim/battle.gd\", \"sound\": \"res://x.tres\"}".to_ascii_buffer()
	cases["only spaces"] = "    \n\t  ".to_ascii_buffer()
	return cases
