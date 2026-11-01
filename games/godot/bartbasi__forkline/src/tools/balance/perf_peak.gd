# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## The most crowded moment of one case, for the benchmark's largest wave (docs/ARCHITECTURE.md B5 and 9.4).
##
##   level=ID [twist=1] [seeds=60] [seed0=0] [targets=1] [wave=N] out=PATH [save=DIR]     a campaign level (or its Twist)
##       (seed0=S seeds=1 wave=N plays again one play of an earlier result: its "seed" is 7700 + S)
##   run=PACK wave=N card=ID [first=1 seeds=5] [strategy=ID] out=PATH [save=DIR]   a run pack's wave N with a risk card (every card in the pool)
##
##   godot --headless --path . --script res://tools/balance/perf_peak.gd -- level=r3_l3 seeds=60 out=PATH
##   godot --headless --path . --script res://tools/balance/perf_peak.gd -- fixture=1 level=r8_fx2 seeds=20 out=PATH save=DIR
##   godot --headless --path . --script res://tools/balance/perf_peak.gd -- fixture=1 tier=2 run=b6_grumble_hill wave=16 card=crowded_night out=PATH
##
## B6: fixture=1 plays the test catalog and the fixture levels and run tiers (tools/balance/fixtures.gd). tier=N (run=) plays a run of that
## content tier (RULES 14.9): its pool and its saved game carry the tier. A tier 0 run is the run it always was.
##   godot --headless --path . --script res://tools/balance/perf_peak.gd -- run=b6_grumble_hill wave=16 card=crowded_night out=PATH
##
## A bot plays to the build phase just before the target wave (for a run: with the risk card already taken for it). Then the
## target wave starts, and the next wave is called early as soon as the game lets a player, so two waves share the map.
## The tail ends when both are cleared. The play with the most live creatures at once is kept (a weaker defense gives a
## bigger crowd), and its tail is played again 5 times with the time of every tick measured, headless, events off: the
## median of the five means and 99th percentiles, for all ticks and for "busy" ticks (50 or more creatures).
## With save=DIR, the build phase before the target wave is written as a saved game through SaveStore, read back through a new
## store and checked against the battle, then copied to DIR/game_level.json or DIR/game_run.json (ARCHITECTURE 9.4).
## A campaign level tries the largest single wave and the largest pair of waves (targets=K: the K biggest of each), and keeps the
## most crowded.
## Times are a dev PC number: the Fold5 decides (ARCHITECTURE 9.2).

const Bot: GDScript = preload("res://tools/balance/bot.gd")
const RunBot: GDScript = preload("res://tools/balance/run_bot.gd")
const Fixtures: GDScript = preload("res://tools/balance/fixtures.gd")
const STYLES: Array[StringName] = [&"casual", &"typical", &"typical"]
const REPEATS: int = 5
const BUSY: int = 50
const TAIL_CAP: int = 40000
const SAVE_ROOT: String = "user://tests/perf_saves/"

var _args: Dictionary = {}
var _game: GameData = null
var _tier: int = 0


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.split("=", true, 1)
		if parts.size() == 2:
			_args[parts[0]] = parts[1]
	var game: GameData = Fixtures.game() if String(_args.get("fixture", "0")) == "1" else GameData.load_from("res://data")
	_tier = int(_args.get("tier", "0"))
	RunBot.habits(_tier, _args)
	if game == null or not game.problems.is_empty() or game.run == null or _tier < 0 or _tier > game.run.tiers.size():
		printerr("data problems")
		quit(2)
		return
	_game = game
	var result: Dictionary = {}
	if _args.has("level"):
		result = _level_case(game)
	elif _args.has("run"):
		result = _run_case(game)
	else:
		printerr("usage: level=ID or run=PACK wave=N card=ID")
		quit(2)
		return
	if result.has("bad"):
		printerr(String(result["bad"]))
		quit(2)
		return
	print("RESULT " + JSON.stringify(result))
	var out: String = String(_args.get("out", ""))
	if out != "":
		var file: FileAccess = FileAccess.open(out, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(result, "  "))
			file.close()
	quit(0)


# A campaign level.

func _level_case(game: GameData) -> Dictionary:
	var level_id: StringName = StringName(String(_args["level"]))
	var twist: bool = String(_args.get("twist", "0")) == "1"
	if not game.levels.has(level_id):
		return {"bad": "unknown level"}
	var ctx: Dictionary = Bot.context(game, level_id, twist)
	if ctx.has("bad"):
		return ctx
	var sizes: Array[int] = Bot.wave_sizes(ctx)
	# The targets: the K biggest waves and the K biggest pairs of waves (a wave and the next), K = targets= (default 1).
	var count: int = int(_args.get("targets", "1"))
	var by_single: Array = range(sizes.size())
	by_single.sort_custom(func(a: int, b: int) -> bool: return sizes[a] > sizes[b] or (sizes[a] == sizes[b] and a < b))
	var by_pair: Array = range(sizes.size())
	by_pair.sort_custom(func(a: int, b: int) -> bool:
		var pa: int = sizes[a] + (sizes[a + 1] if a + 1 < sizes.size() else 0)
		var pb: int = sizes[b] + (sizes[b + 1] if b + 1 < sizes.size() else 0)
		return pa > pb or (pa == pb and a < b))
	var targets: Array[int] = []
	for list: Array in [by_single, by_pair]:
		for k: int in mini(count, list.size()):
			if not targets.has(int(list[k])):
				targets.append(int(list[k]))
	var seeds: int = int(_args.get("seeds", "60"))
	var seed0: int = int(_args.get("seed0", "0"))
	if _args.has("wave"):
		targets = [int(_args["wave"]) - 1]
	var best: Dictionary = {}
	for target: int in targets:
		var found: Dictionary = {"peak": -1}
		for s: int in range(seed0, seed0 + seeds):
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.seed = 7700 + s
			var strat: Dictionary = Bot.random_strategy(ctx, rng, STYLES[s % STYLES.size()], ctx["offered"])
			var b: Battle = _play_to(ctx, strat, target)
			if b == null:
				continue
			var peak: int = _tail_peak(b, null, target)
			if peak > int(found["peak"]):
				found = {"peak": peak, "seed": 7700 + s, "state": b.to_data()}
		if found["peak"] < 0:
			continue
		if best.is_empty() or int(found["peak"]) > int(best["peak"]):
			found["target"] = target
			best = found
	if best.is_empty():
		return {"bad": "%s: no seed reached the target wave" % level_id}
	var timing: Dictionary = _timing(best["state"], game, null, int(best["target"]))
	var result: Dictionary = {"kind": "level", "case": "%s%s" % [level_id, " Twist" if twist else ""], "level": String(level_id), "twist": twist,
		"wave": int(best["target"]) + 1, "wave_size": sizes[int(best["target"])], "next_wave_size": sizes[int(best["target"]) + 1] if int(best["target"]) + 1 < sizes.size() else 0,
		"seed": best["seed"], "peak": best["peak"], "tried_waves": targets.map(func(t: int) -> int: return t + 1)}
	result.merge(timing)
	if _args.has("save"):
		var battle: Battle = Battle.from_data(best["state"], game.catalog)
		var saved: SavedGame = SavedGame.new()
		saved.mode = SavedGame.LEVEL
		saved.level_id = level_id
		saved.twist = twist
		saved.battle = battle
		var written: Dictionary = _write_save(game, saved, String(_args["save"]))
		if written.has("bad"):
			return written
		result["save"] = written
	return result


## Plays a seeded random strategy to the build phase before wave index `target` (as tests/render/make_perf_save.gd does).
func _play_to(ctx: Dictionary, strat: Dictionary, target: int) -> Battle:
	var b: Battle = Battle.create(ctx["level"], ctx["catalog"], false, ctx["twist"])
	b.record_events = false
	for gate: Vector2i in strat["gates"]:
		b.place_gate(gate)
	var seq: Array = strat["seq"]
	var towers: Array = strat["towers"]
	var steps: Array[int] = []
	steps.resize(towers.size())
	steps.fill(0)
	var cursor: Array[int] = [0]
	var spent: Array[int] = [0]
	var wave_buy: bool = bool(strat["wave_buy"])
	while b.phase == Battle.Phase.BUILD and b.tick < Bot.TICK_CAP:
		Bot._buy(b, seq, towers, steps, cursor, spent)
		if b.waves_started == target:
			return b
		if b.start_next_wave() != Battle.DONE:
			return null
		while b.phase == Battle.Phase.WAVE and b.tick < Bot.TICK_CAP:
			if wave_buy and cursor[0] < seq.size() and b.tick % 4 == 0:
				Bot._buy(b, seq, towers, steps, cursor, spent)
			b.step()
	return null


# A run pack wave with a risk card.

func _run_case(game: GameData) -> Dictionary:
	var pack_id: String = String(_args["run"])
	var wave: int = int(_args.get("wave", "0"))
	var card: StringName = StringName(String(_args.get("card", "")))
	var found_pack: bool = false
	for item: Dictionary in game.run.packs:
		if String(item["id"]) == pack_id:
			found_pack = true
	if not found_pack or wave < 2 or wave > 17 or game.run.card(card).is_empty():
		return {"bad": "need run=PACK wave=2..17 card=ID"}
	var pool: Array[StringName] = game.run.card_ids(_tier)
	var first: int = int(_args.get("first", "1"))
	var seeds: int = int(_args.get("seeds", "5"))
	var best: Dictionary = {"peak": -1}
	var played: int = 0
	var reached: int = 0
	for i: int in range(first, first + seeds):
		var run_seed: int = (i * 2654435761) % 4294967296
		for strat: Dictionary in RunBot.strategies():
			if _args.has("strategy") and String(strat["id"]) != String(_args["strategy"]):
				continue
			played += 1
			var res: Dictionary = RunBot.play(game, run_seed, "", false, pool, strat,
				{"pack": pack_id, "stop_before": wave, "force_risk": {"card": String(card), "k": wave - 2}, "return_state": true, "tier": _tier})
			if res.has("bad") or not bool(res.get("stopped", false)) or not bool(res.get("forced_done", false)):
				continue
			reached += 1
			var battle: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(res["end_battle"])), game.catalog)
			var session: RunSession = RunSession.from_data(JSON.parse_string(JSON.stringify(res["end_run"])), battle, game.run) if battle != null else null
			if session == null:
				return {"bad": "a stopped run did not load (seed %d, %s)" % [run_seed, strat["id"]]}
			var peak: int = _tail_peak(battle, session, wave - 1)
			if peak > int(best["peak"]):
				best = {"peak": peak, "seed": run_seed, "i": i, "strategy": String(strat["id"]), "battle": res["end_battle"], "run": res["end_run"]}
	if best["peak"] < 0:
		return {"bad": "no play reached wave %d with the card (%d played)" % [wave, played]}
	var battle2: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(best["battle"])), game.catalog)
	var session2: RunSession = RunSession.from_data(JSON.parse_string(JSON.stringify(best["run"])), battle2, game.run)
	var timing: Dictionary = _timing(best["battle"], game, best["run"], wave - 1)
	var info: Dictionary = {"kind": "run", "case": "%s wave %d %s" % [pack_id, wave, card], "pack": pack_id, "wave": wave, "card": String(card),
		"seed": best["seed"], "i": best["i"], "strategy": best["strategy"], "peak": best["peak"], "plays": played, "plays_reached": reached,
		"towers": battle2.towers.size(), "lives": battle2.lives, "gold": battle2.gold}
	info.merge(timing)
	if _args.has("save"):
		var saved: SavedGame = SavedGame.new()
		saved.mode = SavedGame.RUN
		saved.battle = battle2
		saved.run = session2
		var written: Dictionary = _write_save(game, saved, String(_args["save"]))
		if written.has("bad"):
			return written
		info["save"] = written
	return info


# The tail: the target wave and the next one, called early.

## Starts the next wave, calls the one after early as soon as it is allowed, and plays until both are cleared. The most
## creatures on the map at once. `session` is the run around the battle, or null for a campaign level. Plays a copy.
func _tail_peak(b: Battle, session: RunSession, target: int) -> int:
	var copy: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(b.to_data())), b.catalog)
	copy.record_events = false
	var run_copy: RunSession = null
	if session != null:
		run_copy = RunSession.from_data(JSON.parse_string(JSON.stringify(session.to_data())), copy, _game.run)
		if run_copy == null:
			return -1
	return int(_play_tail(copy, run_copy, target, {})["peak"])


## One play of the tail from the build phase before wave index `target`. `times`, when not empty, collects the microseconds of
## every step and the live creatures at it.
func _play_tail(b: Battle, session: RunSession, target: int, times: Dictionary) -> Dictionary:
	var peak: int = 0
	var opened: StringName = session.start_next_wave() if session != null else b.start_next_wave()
	if opened != Battle.DONE:
		return {"peak": -1}
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < TAIL_CAP:
		guard += 1
		if b.waves_started == target + 1 and b.waves_started < b.wave_count():
			if session != null:
				session.start_next_wave()
			else:
				b.start_next_wave()
		var t0: int = Time.get_ticks_usec()
		b.step()
		var us: int = Time.get_ticks_usec() - t0
		var live: int = b.enemies.size()
		peak = maxi(peak, live)
		if not times.is_empty():
			(times["us"] as Array).append(us)
			(times["live"] as Array).append(live)
		if (b.waves_started >= target + 2 or b.waves_started >= b.wave_count()) and b.running.is_empty():
			break
	return {"peak": peak}


# Timing.

## Plays the tail REPEATS times from the saved state and gives the median mean and 99th percentile of the step time.
func _timing(state: Dictionary, game: GameData, run_data: Variant, target: int) -> Dictionary:
	var means: Array[int] = []
	var p99s: Array[int] = []
	var busy_means: Array[int] = []
	var busy_p99s: Array[int] = []
	var maxes: Array[int] = []
	var ticks: int = 0
	var busy_ticks: int = 0
	for r: int in REPEATS:
		var battle: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(state)), game.catalog)
		battle.record_events = false
		var session: RunSession = null
		if run_data != null:
			session = RunSession.from_data(JSON.parse_string(JSON.stringify(run_data)), battle, game.run)
		var times: Dictionary = {"us": [], "live": []}
		_play_tail(battle, session, target, times)
		var us: Array = times["us"]
		var live: Array = times["live"]
		var all: Array[int] = []
		var busy: Array[int] = []
		for i: int in us.size():
			all.append(us[i])
			if live[i] >= BUSY:
				busy.append(us[i])
		ticks = all.size()
		busy_ticks = busy.size()
		means.append(_mean(all))
		p99s.append(_p99(all))
		busy_means.append(_mean(busy))
		busy_p99s.append(_p99(busy))
		maxes.append(0 if all.is_empty() else all.max())
	return {"ticks": ticks, "busy_ticks": busy_ticks, "mean_us": _median(means), "p99_us": _median(p99s), "busy_mean_us": _median(busy_means),
		"busy_p99_us": _median(busy_p99s), "max_us": _median(maxes)}


func _mean(values: Array[int]) -> int:
	if values.is_empty():
		return 0
	var total: int = 0
	for v: int in values:
		total += v
	return total / values.size()


func _p99(values: Array[int]) -> int:
	if values.is_empty():
		return 0
	var sorted: Array[int] = values.duplicate()
	sorted.sort()
	return sorted[mini(sorted.size() - 1, sorted.size() * 99 / 100)]


func _median(values: Array[int]) -> int:
	var sorted: Array[int] = values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]


# The saved game.

## Writes `saved` through SaveStore into a folder under user://, reads it back through a new store, checks it against the
## battle, and copies the file to `out_dir`. {"bad"} on any failure, else {"file", "bytes", "mode"}.
func _write_save(game: GameData, saved: SavedGame, out_dir: String) -> Dictionary:
	var dir: String = SAVE_ROOT + "%d" % Time.get_ticks_usec()
	var store: SaveStore = SaveStore.new(dir)
	if not saved.can_save():
		return {"bad": "the state cannot be saved"}
	if not store.save_game(saved):
		return {"bad": "SaveStore refused the game"}
	var back: Array[SavedGame] = SaveStore.new(dir).load_games(game)
	if back.size() != 1 or back[0].mode != saved.mode or back[0].battle.phase != Battle.Phase.BUILD \
			or back[0].battle.waves_started != saved.battle.waves_started \
			or JSON.stringify(back[0].battle.to_data()) != JSON.stringify(saved.battle.to_data()):
		return {"bad": "the save did not load back the same"}
	if saved.run != null and (back[0].run == null or JSON.stringify(back[0].run.to_data()) != JSON.stringify(saved.run.to_data())):
		return {"bad": "the run did not load back the same"}
	var name: String = "game_level.json" if saved.mode == SavedGame.LEVEL else "game_run.json"
	var text: String = FileAccess.get_file_as_string(dir + "/" + name)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var file: FileAccess = FileAccess.open(out_dir.path_join(name), FileAccess.WRITE)
	if file == null:
		return {"bad": "cannot write to %s" % out_dir}
	file.store_string(text)
	file.close()
	return {"file": out_dir.path_join(name), "bytes": text.length(), "mode": String(saved.mode)}
