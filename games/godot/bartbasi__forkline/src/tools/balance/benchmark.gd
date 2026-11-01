# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Time per sim tick and peak live creatures for one level, on this PC (docs/ARCHITECTURE.md 9.4).
##
##   godot --headless --path . --script res://tools/balance/benchmark.gd -- level=r1_l1 build=PATH out=PATH
##   (twist=1 plays the level with its Twist; fixture=1 plays a fixture level on the test catalog, tools/balance/fixtures.gd)
##
## `build` is a JSON file from run.gd: a search result (its best_win.strategy is played) or a
## spread result (its peak_strategy is played). Several builds can be given as build=A,B.
## Each build is played 5 times; the table lists the median of the five means and 99th percentiles.
## Times are microseconds per tick, headless, with events off. This is a dev PC number: the
## Fold5 decides (ARCHITECTURE 9.2).

const Bot: GDScript = preload("res://tools/balance/bot.gd")
const Fixtures: GDScript = preload("res://tools/balance/fixtures.gd")
const REPEATS: int = 5
## Ticks with at least this many creatures on the map count as "busy".
const BUSY: int = 50

var _args: Dictionary = {}


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.split("=", true, 1)
		if parts.size() == 2:
			_args[parts[0]] = parts[1]
	var game: GameData = Fixtures.game() if String(_args.get("fixture", "0")) == "1" else GameData.load_from("res://data")
	if game == null:
		quit(2)
		return
	var level_id: StringName = StringName(String(_args.get("level", "r1_l1")))
	if not game.problems.is_empty() or not game.levels.has(level_id):
		printerr("bad data or level")
		quit(2)
		return
	var ctx: Dictionary = Bot.context(game, level_id, String(_args.get("twist", "0")) == "1")
	if ctx.has("bad"):
		printerr(String(ctx["bad"]))
		quit(2)
		return
	var rows: Array = []
	for path: String in String(_args.get("build", "")).split(",", false):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			printerr("cannot read %s" % path)
			quit(2)
			return
		var data: Dictionary = parsed
		var label: String = path.get_file().get_basename()
		var strat_data: Dictionary = {}
		if data.has("best_win"):
			strat_data = data["best_win"]["strategy"]
		elif data.has("peak_strategy"):
			strat_data = data["peak_strategy"]
		else:
			# A search that found no win has no strategy: the other builds still run.
			printerr("%s has no strategy" % path)
			continue
		rows.append(_measure(ctx, Bot.from_data(strat_data), label))
	if rows.is_empty():
		quit(2)
		return
	var result: Dictionary = {"level": String(level_id), "rows": rows, "busy_at_least": BUSY, "repeats": REPEATS}
	print("RESULT " + JSON.stringify(result))
	var out: String = String(_args.get("out", ""))
	if out != "":
		var file: FileAccess = FileAccess.open(out, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(result, "  "))
			file.close()
	quit(0)


func _measure(ctx: Dictionary, strat: Dictionary, label: String) -> Dictionary:
	var means: Array[int] = []
	var p99s: Array[int] = []
	var busy_means: Array[int] = []
	var busy_p99s: Array[int] = []
	var maxes: Array[int] = []
	var peak: int = 0
	var ticks: int = 0
	var busy_ticks: int = 0
	var won: bool = false
	for r: int in REPEATS:
		var res: Dictionary = Bot.play(ctx, strat, false, true)
		var us: PackedInt32Array = res["step_us"]
		var live: PackedInt32Array = res["step_live"]
		var all: Array[int] = []
		var busy: Array[int] = []
		for i: int in us.size():
			all.append(us[i])
			if live[i] >= BUSY:
				busy.append(us[i])
		peak = int(res["peak"])
		ticks = us.size()
		busy_ticks = busy.size()
		won = bool(res["won"])
		means.append(_mean(all))
		p99s.append(_p99(all))
		busy_means.append(_mean(busy))
		busy_p99s.append(_p99(busy))
		maxes.append(_max(all))
	# The same build with early calls switched off: the length a player who never calls early sees.
	var calm: Dictionary = strat.duplicate(true)
	calm["early"]["on"] = false
	var calm_res: Dictionary = Bot.play(ctx, calm, false)
	return {"label": label, "calm_won": calm_res["won"], "calm_stars": calm_res["stars"], "calm_lives": calm_res["lives"],
		"calm_ticks": calm_res["ticks"], "calm_waves": calm_res["cleared"],
		"won": won, "ticks": ticks, "busy_ticks": busy_ticks, "peak": peak,
		"mean_us": _median(means), "p99_us": _median(p99s), "busy_mean_us": _median(busy_means),
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


func _max(values: Array[int]) -> int:
	return 0 if values.is_empty() else values.max()


func _median(values: Array[int]) -> int:
	var sorted: Array[int] = values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]
