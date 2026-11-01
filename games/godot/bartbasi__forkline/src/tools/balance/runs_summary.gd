# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Turns the JSON files of one run_runs.sh run into the markdown tables of the run and daily report,
## so no number in the report is typed by hand.
##
##   godot --headless --path . --script res://tools/balance/runs_summary.gd -- dir=C:/path/docs/balance/raw/2026-10-24-b2
##   ... part=det|rates|search|length|waves|boss|maps|towers|cards|daily|risk|whatif   (default: all)
##   ... tier=N fixture=1   (B6) the runs in the folder were played at content tier N (runs.gd tier=N), on the fixture data when fixture=1.
##       The bosses, packs and maps counted are those of the tier and below, so every bar of RULES 14.8 and 15 reads at that tier.
##
## B4 parts: bars (every bar of RULES 14.8 and 15 with pass or fail), boss (per band 6 pack), fair (segments, stacks, packs),
## forced (the forced stack and pack files), air (E6.2: the anti-air check, from air/*.json of run_e67.sh AIR), cardbar (the card experiment against its bar), riskfair (the risk replay),
## lengthb4 (run length groups), detb4 (same seed, same run, refused saves), dailyb4, whatifb4, flags (the phase B job lines) and
## allstacks (the job lines that force every stack that fits onto seeds 1 to 200: phase C).
##
## It prints markdown to the console. It reads only files runs.gd wrote.

const Fixtures: GDScript = preload("res://tools/balance/fixtures.gd")
const BUILD_SECONDS: int = 15
const CONFIGS: Array[String] = ["base_r0", "base_r1", "all_r0", "all_r1"]
const CONFIG_NAMES: Dictionary = {"base_r0": "Normal, no unlocks", "base_r1": "Relaxed, no unlocks", "all_r0": "Normal, all cards", "all_r1": "Relaxed, all cards"}

var _dir: String = ""
var _game: GameData = null
var _tier: int = 0                                # tier=N (B6): the content tier of the folder's runs; its packs, bosses and segments only
var _fixture: bool = false                        # fixture=1 (B6): the folder was played on the test catalog and fixture tiers
var _rates: Dictionary = {}                       # config to its rows
var _cards: Array = []


func _initialize() -> void:
	var part: String = "all"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("dir="):
			_dir = argument.trim_prefix("dir=")
		if argument.begins_with("part="):
			part = argument.trim_prefix("part=")
		if argument.begins_with("tier="):
			_tier = int(argument.trim_prefix("tier="))
		if argument == "fixture=1":
			_fixture = true
	_game = Fixtures.game() if _fixture else GameData.load_from("res://data")
	if _tier > 0 or _fixture:
		print("Tier %d%s.\n" % [_tier, " (fixture data)" if _fixture else ""])
	for config: String in CONFIGS:
		_rates[config] = _load_rows("rates_%s_" % config)
	if _rates["base_r0"].size() > 0:
		_cards = _first_file("rates_base_r0_").get("cards", [])
	var parts: Dictionary = {"det": _det, "rates": _rates_tables, "search": _search_tables, "length": _length_tables,
		"waves": _wave_tables, "boss": _boss_tables, "maps": _map_tables, "towers": _tower_tables, "cards": _card_tables,
		"daily": _daily_tables, "risk": _risk_tables, "cardvalue": _cardvalue_tables, "whatif": _whatif_tables, "ironshell": _ironshell_tables, "lives": _lives_tables}
	var b4: Dictionary = {"bars": _bars, "boss": _boss_b4, "fair": _fair_b4, "forced": _forced_b4, "cardbar": _cardbar_b4, "riskfair": _riskfair_b4,
		"lengthb4": _length_b4, "detb4": _det_b4, "dailyb4": _daily_b4, "whatifb4": _whatif_b4, "flags": _flags_b4, "allstacks": _allstacks_b4, "fullstacks": _fullstacks_b5, "perf": _perf_b5, "air": _air_e6}
	if part == "b4":
		for part_name: String in ["bars", "boss", "fair", "forced", "cardbar", "riskfair", "lengthb4", "detb4", "dailyb4", "whatifb4", "perf", "fullstacks", "flags"]:
			(b4[part_name] as Callable).call()
	elif b4.has(part):
		(b4[part] as Callable).call()
	else:
		for part_name: String in parts.keys():
			if part == "all" or part == part_name:
				(parts[part_name] as Callable).call()
	quit(0)


# Reading.

func _files(prefix: String) -> Array[String]:
	var out: Array[String] = []
	var dir: DirAccess = DirAccess.open(_dir)
	if dir == null:
		return out
	for file: String in dir.get_files():
		if file.begins_with(prefix) and file.ends_with(".json"):
			out.append(file)
	out.sort()
	return out


func _read(file: String) -> Dictionary:
	if not FileAccess.file_exists(_dir.path_join(file)):
		return {}
	var text: String = FileAccess.get_file_as_string(_dir.path_join(file))
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _first_file(prefix: String) -> Dictionary:
	var files: Array[String] = _files(prefix)
	if files.is_empty():
		return {}
	return _read(files[0])


func _load_rows(prefix: String) -> Array:
	var rows: Array = []
	for file: String in _files(prefix):
		rows.append_array(_read(file).get("rows", []))
	return rows


# Small helpers.

func _head(columns: Array) -> void:
	print("| " + " | ".join(PackedStringArray(columns.map(func(c: Variant) -> String: return str(c)))) + " |")
	print("|" + "---|".repeat(columns.size()))


func _row(cells: Array) -> void:
	print("| " + " | ".join(PackedStringArray(cells.map(func(c: Variant) -> String: return str(c)))) + " |")


func _pct(part: int, whole: int) -> String:
	if whole <= 0:
		return "-"
	return "%.1f%%" % (100.0 * part / whole)


func _rate(part: int, whole: int) -> String:
	if whole <= 0:
		return "-"
	return "%s (%d/%d)" % [_pct(part, whole), part, whole]


func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for v: Variant in values:
		total += float(v)
	return total / values.size()


## Percentile q (0 to 1) of numbers, by nearest rank.
func _quant(values: Array, q: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted: Array = values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(ceil(q * sorted.size())) - 1, 0, sorted.size() - 1)])


func _minutes(row: Dictionary) -> float:
	return (float(row["ticks"]) / 20.0 + BUILD_SECONDS * int(row["builds"])) / 60.0


func _wave_minutes(row: Dictionary) -> float:
	return float(row["ticks"]) / 20.0 / 60.0


func _won(rows: Array) -> int:
	var n: int = 0
	for r: Dictionary in rows:
		if bool(r["won"]):
			n += 1
	return n


## Rows filtered by a callable on the row.
func _where(rows: Array, test: Callable) -> Array:
	return rows.filter(test)


func _plan(run_seed: int) -> Dictionary:
	return MapAssembler.plan(run_seed, _game.run, _tier)


## The bosses of the tier and below, in enemies.json order (the four of regions 1 to 4 at tier 0).
func _bosses() -> Array[String]:
	var out: Array[String] = []
	for id: StringName in _game.run.boss_ids(_tier):
		out.append(String(id))
	return out


## The flags that put a job line back on this tier and data.
func _job_flags() -> String:
	return (" tier=%d" % _tier if _tier > 0 else "") + (" fixture=1" if _fixture else "")


## A job line with those flags put in before its `out=`.
func _flag_line(line: String) -> String:
	return line.replace(" out=", _job_flags() + " out=")


# Determinism.

func _det() -> void:
	print("\n### Same seed, same run\n")
	var first: Dictionary = _read("det.json")
	var again: Dictionary = _read("det_again.json")
	if first.is_empty():
		print("(no det.json)")
		return
	var rows: Array = first["rows"]
	var dailies: Array = first["daily_rows"]
	_head(["Check", "Runs (seeds 1 to 50)", "Dailies (first 50 days)"])
	for item: Array in [
		["Same seed gives the same map and waves, built twice", "map_equal", ""],
		["Same seed and picks, played twice: equal result, battle state and run state", "again_equal", "again_equal"],
		["Save and load in the middle of a wave: equal to the play with no save", "wave_restore_equal", "wave_restore_equal"],
		["Save and load with a draft open: same offers, equal to the play with no save", "draft_restore_equal", "draft_restore_equal"]]:
		var key_a: String = item[1]
		var key_b: String = item[2]
		var good_a: int = 0
		for r: Dictionary in rows:
			if bool(r.get(key_a, false)):
				good_a += 1
		var good_b: int = 0
		for r: Dictionary in dailies:
			if key_b != "" and bool(r.get(key_b, false)):
				good_b += 1
		_row([item[0], "%d of %d" % [good_a, rows.size()], ("%d of %d" % [good_b, dailies.size()]) if key_b != "" else "-"])
	var wave_done: int = 0
	var draft_done: int = 0
	for r: Dictionary in rows:
		wave_done += 1 if bool(r["wave_restored"]) else 0
		draft_done += 1 if bool(r["draft_restored"]) else 0
	var wave_done_d: int = 0
	var draft_done_d: int = 0
	for r: Dictionary in dailies:
		wave_done_d += 1 if bool(r["wave_restored"]) else 0
		draft_done_d += 1 if bool(r["draft_restored"]) else 0
	_row(["Saves that really happened in the middle of a wave", "%d of %d" % [wave_done, rows.size()], "%d of %d" % [wave_done_d, dailies.size()]])
	_row(["Saves that really happened with a draft open", "%d of %d" % [draft_done, rows.size()], "%d of %d" % [draft_done_d, dailies.size()]])
	print("\nFailures: %s. Chain hash of the first process %s, of a second process %s: %s.\n" % [
		str(first["failures"]), "%d" % int(first["chain_hash"]), ("%d" % int(again["chain_hash"])) if again.has("chain_hash") else "missing",
		"equal" if again.has("chain_hash") and int(again["chain_hash"]) == int(first["chain_hash"]) else "NOT EQUAL"])
	var wins: int = 0
	for r: Dictionary in rows:
		wins += 1 if bool(r["won"]) else 0
	print("The plays used all 16 named strategies in turn, Normal and Relaxed, both pools; %d of the %d runs were wins, so the checks cover wins and losses.\n" % [wins, rows.size()])


# Win rates.

func _rates_tables() -> void:
	print("\n### Win rates by strategy (named strategies, %d seeds each)\n" % _seed_count("base_r0"))
	var ids: Array = []
	for r: Dictionary in _rates["base_r0"]:
		if not ids.has(r["strategy"]):
			ids.append(r["strategy"])
	var head: Array = ["Strategy"]
	for config: String in CONFIGS:
		head.append(CONFIG_NAMES[config])
	_head(head)
	for id: String in ids:
		var cells: Array = [id]
		for config: String in CONFIGS:
			var rows: Array = _where(_rates[config], func(r: Dictionary) -> bool: return r["strategy"] == id)
			cells.append(_rate(_won(rows), rows.size()))
		_row(cells)
	var all_cells: Array = ["**All 16**"]
	for config: String in CONFIGS:
		all_cells.append(_rate(_won(_rates[config]), _rates[config].size()))
	_row(all_cells)
	print("\nBy kind of strategy (the same plays, grouped):\n")
	_head(head)
	for group: Array in [["pick towers", "towers_"], ["pick economy", "economy_"], ["pick risk", "risk_"], ["pick random", "random_"]]:
		var cells: Array = [group[0]]
		for config: String in CONFIGS:
			var rows: Array = _where(_rates[config], func(r: Dictionary) -> bool: return String(r["strategy"]).begins_with(String(group[1])))
			cells.append(_rate(_won(rows), rows.size()))
		_row(cells)
	for group: Array in [["build wide", "_wide"], ["build tall", "_tall"]]:
		var cells2: Array = [group[0]]
		for config: String in CONFIGS:
			var rows2: Array = _where(_rates[config], func(r: Dictionary) -> bool: return String(r["strategy"]).contains(String(group[1])))
			cells2.append(_rate(_won(rows2), rows2.size()))
		_row(cells2)
	for group: Array in [["no early calls", false], ["early calls", true]]:
		var cells3: Array = [group[0]]
		for config: String in CONFIGS:
			var rows3: Array = _where(_rates[config], func(r: Dictionary) -> bool: return String(r["strategy"]).ends_with("_early") == bool(group[1]))
			cells3.append(_rate(_won(rows3), rows3.size()))
		_row(cells3)
	print("\nWhere the named strategies' runs end (Normal, no unlocks): waves cleared by lost runs\n")
	_head(["Waves cleared", "Runs lost there", "Share of all runs"])
	var lost: Dictionary = {}
	var total: int = 0
	for r: Dictionary in _rates["base_r0"]:
		total += 1
		if not bool(r["won"]):
			lost[int(r["cleared"])] = int(lost.get(int(r["cleared"]), 0)) + 1
	var keys: Array = lost.keys()
	keys.sort()
	for k: int in keys:
		_row(["%d (lost in wave %d)" % [k, k + 1], lost[k], _pct(int(lost[k]), total)])


func _seed_count(config: String) -> int:
	var seen: Dictionary = {}
	for r: Dictionary in _rates[config]:
		seen[int(r["i"])] = true
	return seen.size()


# The search.

func _search_tables() -> void:
	print("\n### Random strategy search (100 random strategies on each of seeds 1 to 50)\n")
	_head(["Setting", "Seeds with a winning strategy", "Strategies that win, of all tried", "Best lives (median over won seeds)", "Seeds with no win: waves cleared by the best"])
	for config: String in ["base_r0", "all_r0", "base_r1"]:
		var rows: Array = _load_rows("search_%s_" % config)
		if rows.is_empty():
			continue
		var won: int = 0
		var wins: int = 0
		var tried: int = 0
		var lives: Array = []
		var misses: Array = []
		for r: Dictionary in rows:
			tried += int(r["tried"])
			wins += int(r["wins"])
			if bool(r["best_won"]):
				won += 1
				lives.append(int(r["best_lives"]))
			else:
				misses.append("%d (seed %d, %s)" % [int(r["best_cleared"]), int(r["i"]), r["boss"]])
		_row([CONFIG_NAMES[config], _rate(won, rows.size()), _rate(wins, tried), "%d" % _quant(lives, 0.5), ", ".join(PackedStringArray(misses)) if misses.size() > 0 else "none"])
	print()


# Length.

func _length_tables() -> void:
	print("\n### Run length at 1x (wave time plus 15 s for each build phase)\n")
	_head(["Setting", "Plays", "Wins", "Won runs: mean min", "10th / 50th / 90th percentile", "Wave time only, mean min", "Share of won runs in 15 to 20 min", "Share in 12 to 15"])
	for config: String in CONFIGS:
		var rows: Array = _where(_rates[config], func(r: Dictionary) -> bool: return bool(r["won"]))
		var mins: Array = rows.map(func(r: Dictionary) -> float: return _minutes(r))
		var waves_only: Array = rows.map(func(r: Dictionary) -> float: return _wave_minutes(r))
		var inside: int = mins.filter(func(m: float) -> bool: return m >= 15.0 and m <= 20.0).size()
		var near: int = mins.filter(func(m: float) -> bool: return m >= 12.0 and m < 15.0).size()
		_row([CONFIG_NAMES[config], _rates[config].size(), rows.size(), "%.1f" % _mean(mins),
			"%.1f / %.1f / %.1f" % [_quant(mins, 0.1), _quant(mins, 0.5), _quant(mins, 0.9)], "%.1f" % _mean(waves_only), _pct(inside, rows.size()), _pct(near, rows.size())])
	print("\nWon runs by strategy kind (Normal, no unlocks), minutes:\n")
	_head(["Kind", "Won runs", "Mean min", "Build phases (mean)", "Early calls (mean)", "Wave time only, mean min"])
	for group: Array in [["no early calls", false], ["early calls", true]]:
		var rows2: Array = _where(_rates["base_r0"], func(r: Dictionary) -> bool: return bool(r["won"]) and String(r["strategy"]).ends_with("_early") == bool(group[1]))
		_row([group[0], rows2.size(), "%.1f" % _mean(rows2.map(func(r: Dictionary) -> float: return _minutes(r))),
			"%.1f" % _mean(rows2.map(func(r: Dictionary) -> float: return float(r["builds"]))),
			"%.1f" % _mean(rows2.map(func(r: Dictionary) -> float: return float(r["early"]))),
			"%.1f" % _mean(rows2.map(func(r: Dictionary) -> float: return _wave_minutes(r)))])
	print("\nWave time of won runs (Normal, no unlocks) by wave band, seconds per wave (no early calls):\n")
	_head(["Band", "Waves", "Mean seconds per wave"])
	var sums: Array = []
	var counts: Array = []
	for b: int in 6:
		sums.append(0.0)
		counts.append(0)
	for r: Dictionary in _rates["base_r0"]:
		if bool(r["won"]) and int(r["early"]) == 0:
			for w: int in mini(18, (r["wave_ticks"] as Array).size()):
				sums[w / 3] += float(r["wave_ticks"][w]) / 20.0
				counts[w / 3] += 1
	for b: int in 6:
		_row([b + 1, "%d to %d" % [b * 3 + 1, b * 3 + 3], "%.1f" % (float(sums[b]) / maxi(int(counts[b]), 1))])


# Waves: lives, gold, towers.

func _wave_tables() -> void:
	print("\n### Wave by wave (Normal, no unlocks, the named strategies without early calls)\n")
	var rows: Array = _where(_rates["base_r0"], func(r: Dictionary) -> bool: return int(r["early"]) == 0)
	_head(["Wave", "Plays that started it", "Lives lost in it (mean)", "Lost the run in it", "Gold unspent when it starts (median / mean)", "Share with nothing left to buy", "Income before it (median)", "Towers (mean)", "Tier sum (mean)", "Peak creatures (median / max)"])
	for w: int in 18:
		var reached: Array = _where(rows, func(r: Dictionary) -> bool: return (r["lives_at"] as Array).size() > w)
		if reached.is_empty():
			continue
		var lost: Array = []
		var gold: Array = []
		var idle: int = 0
		var towers: Array = []
		var tiers: Array = []
		var income: Array = []
		var peaks: Array = []
		var died: int = 0
		for r: Dictionary in reached:
			var next_lives: int = 0
			if (r["lives_pre"] as Array).size() > w + 1:
				next_lives = int(r["lives_pre"][w + 1])
			else:
				next_lives = int(r["lives"])
			lost.append(int(r["lives_at"][w]) - next_lives)
			if not bool(r["won"]) and int(r["reached"]) == w + 1:
				died += 1
			gold.append(int(r["gold_at"][w]))
			idle += int(r["idle_at"][w])
			towers.append(int(r["towers_at"][w]))
			tiers.append(int(r["tiers_at"][w]))
			if w > 0 and (r["gold_pre"] as Array).size() > w:
				income.append(int(r["gold_pre"][w]) - int(r["gold_at"][w - 1]))
			peaks.append(int(r["peak_at"][w]))
		_row([w + 1, reached.size(), "%.2f" % _mean(lost), _pct(died, reached.size()), "%d / %.0f" % [_quant(gold, 0.5), _mean(gold)], _pct(idle, reached.size()),
			"%d" % _quant(income, 0.5) if not income.is_empty() else "-", "%.1f" % _mean(towers), "%.1f" % _mean(tiers), "%d / %d" % [_quant(peaks, 0.5), _quant(peaks, 1.0)]])
	print("\nIncome before a wave is the gold at the start of its build phase less the gold left unspent at the start of the wave before, so it holds the clear bonus, bounties, early call bonuses and gold cards of the wave before.\n")
	print("\nThe same, won runs only: gold unspent when waves 10, 14, 16, 17 and 18 start, and the gold left at the end\n")
	_head(["Setting", "Won runs", "Wave 10", "Wave 14", "Wave 16", "Wave 17", "Wave 18", "End of run", "Nothing to buy at wave 18 start"])
	for config: String in CONFIGS:
		var won: Array = _where(_rates[config], func(r: Dictionary) -> bool: return bool(r["won"]) and int(r["early"]) == 0)
		if won.is_empty():
			continue
		var cells: Array = [CONFIG_NAMES[config], won.size()]
		for w: int in [9, 13, 15, 16, 17]:
			cells.append("%d" % _quant(won.map(func(r: Dictionary) -> int: return int(r["gold_at"][w])), 0.5))
		cells.append("%d" % _quant(won.map(func(r: Dictionary) -> int: return int(r["end_gold"])), 0.5))
		var idle18: int = 0
		for r: Dictionary in won:
			idle18 += int(r["idle_at"][17])
		cells.append(_pct(idle18, won.size()))
		_row(cells)
	print("\n(median gold unspent at the start of that wave, after the bot's purchases)\n")
	print("\nHow full the board is when the boss wave starts (runs that reached wave 18, Normal, no unlocks, no early calls):\n")
	_head(["Spots on the map", "Plays", "Towers built (mean)", "Every spot built", "Every tower at tier 3", "Gold unspent (median)"])
	var by_spots: Dictionary = {}
	for r: Dictionary in _where(rows, func(r: Dictionary) -> bool: return int(r["reached"]) >= 18):
		var spots: int = _spots_of(r)
		if not by_spots.has(spots):
			by_spots[spots] = []
		(by_spots[spots] as Array).append(r)
	var spot_keys: Array = by_spots.keys()
	spot_keys.sort()
	for spots: int in spot_keys:
		var list: Array = by_spots[spots]
		var full: int = 0
		var maxed: int = 0
		for r: Dictionary in list:
			if int(r["towers_at"][17]) >= spots:
				full += 1
			if int(r["tiers_at"][17]) >= 3 * int(r["towers_at"][17]):
				maxed += 1
		_row([spots, list.size(), "%.1f" % _mean(list.map(func(r: Dictionary) -> float: return float(r["towers_at"][17]))), _pct(full, list.size()), _pct(maxed, list.size()),
			"%d" % _quant(list.map(func(r: Dictionary) -> int: return int(r["gold_at"][17])), 0.5)])


var _spot_cache: Dictionary = {}


## Build spots on a play's map, from its stack.
func _spots_of(row: Dictionary) -> int:
	var key: String = String(row["stack"])
	if _spot_cache.has(key):
		return int(_spot_cache[key])
	var parts: PackedStringArray = key.split("|")
	var packs: Array[StringName] = []
	var plan: Dictionary = _plan(int(row["seed"]))
	packs.assign(plan["packs"])
	var level: LevelData = MapAssembler.build(_game.run, _game.catalog, StringName(parts[0]), StringName(parts[1]), StringName(parts[2]), packs)
	_spot_cache[key] = level.spots.size() if level != null else 0
	return int(_spot_cache[key])


# The boss wave.

func _boss_tables() -> void:
	print("
### The boss wave (wave 18)
")
	_head(["Setting", "Runs that started wave 18", "Won", "Lives when it starts (median)", "Won runs: lives lost in it (median)", "Won runs: boss reached the base", "Lost runs: boss health left at its lowest (median, of full)"])
	for config: String in CONFIGS:
		var rows: Array = _where(_rates[config], func(r: Dictionary) -> bool: return int(r["reached"]) >= 18)
		if rows.is_empty():
			continue
		_row(_boss_row(CONFIG_NAMES[config], rows))
	print("
By boss (Normal, no unlocks, the named strategies):
")
	_head(["Boss", "Runs that started wave 18", "Won", "Lives when it starts (median)", "Won runs: lives lost in it (median)", "Won runs: boss reached the base", "Lost runs: boss health left at its lowest (median, of full)", "Lost runs: boss reached the base"])
	for boss: String in _bosses():
		var rows2: Array = _where(_rates["base_r0"], func(r: Dictionary) -> bool: return r["boss"] == boss and int(r["reached"]) >= 18)
		if rows2.is_empty():
			continue
		var lost2: Array = _where(rows2, func(r: Dictionary) -> bool: return not bool(r["won"]))
		var reached: int = lost2.filter(func(r: Dictionary) -> bool: return int(r["boss_steps"]) == 0).size()
		var cells: Array = _boss_row(boss, rows2)
		cells.append(_rate(reached, lost2.size()))
		_row(cells)
	print("
A lost run's boss health is the lowest fraction of the boss's health seen (sampled every 5 ticks); a won run may have killed the boss or only outlived it: the reached the base column counts the wins where the boss got to the base and took its 20 lives. An empty cell means the boss was never seen on the map.
")


func _boss_row(label: String, rows: Array) -> Array:
	var lost: Array = _where(rows, func(r: Dictionary) -> bool: return not bool(r["won"]))
	var won: Array = _where(rows, func(r: Dictionary) -> bool: return bool(r["won"]))
	var left: Array = lost.filter(func(r: Dictionary) -> bool: return int(r["boss_min"]) >= 0).map(func(r: Dictionary) -> int: return int(r["boss_min"]))
	var lost_in: Array = won.map(func(r: Dictionary) -> int: return int(r["lives_at"][17]) - int(r["lives"]))
	var leaked: int = won.filter(func(r: Dictionary) -> bool: return int(r["boss_steps"]) == 0).size()
	return [label, rows.size(), _rate(won.size(), rows.size()), "%d" % _quant(rows.map(func(r: Dictionary) -> int: return int(r["lives_at"][17])), 0.5),
		("%d" % _quant(lost_in, 0.5)) if not lost_in.is_empty() else "-", _rate(leaked, won.size()), ("%.0f%%" % (_quant(left, 0.5) / 10.0)) if not left.is_empty() else "-"]


# Maps, bosses and packs.

func _map_tables() -> void:
	print("\n### Win rate by boss, map segment and stack (Normal, no unlocks, the named strategies)\n")
	var rows: Array = _rates["base_r0"]
	_head(["Boss", "Seeds", "Plays", "Won", "Mean waves cleared", "Lost by wave 6", "Lost in wave 18"])
	for boss: String in _bosses():
		var list: Array = _where(rows, func(r: Dictionary) -> bool: return r["boss"] == boss)
		_row(_map_row(boss, list))
	for kind: Array in [["Top segment", 0], ["Middle segment", 1], ["Bottom segment", 2]]:
		print("\n%s:\n" % kind[0])
		_head([kind[0], "Seeds", "Plays", "Won", "Mean waves cleared", "Lost by wave 6", "Lost in wave 18"])
		var names: Array = []
		for r: Dictionary in rows:
			var piece: String = String(r["stack"]).split("|")[int(kind[1])]
			if not names.has(piece):
				names.append(piece)
		names.sort()
		for piece: String in names:
			var list2: Array = _where(rows, func(r: Dictionary) -> bool: return String(r["stack"]).split("|")[int(kind[1])] == piece)
			_row(_map_row(piece, list2))
	print("\nEvery stack with at least 4 seeds:\n")
	_head(["Stack (top, middle, bottom)", "Seeds", "Plays", "Won", "Mean waves cleared", "Lost by wave 6", "Lost in wave 18"])
	var stacks: Array = []
	for r: Dictionary in rows:
		if not stacks.has(r["stack"]):
			stacks.append(r["stack"])
	stacks.sort()
	for stack: String in stacks:
		var list3: Array = _where(rows, func(r: Dictionary) -> bool: return r["stack"] == stack)
		if _distinct_seeds(list3) >= 4:
			_row(_map_row(stack.replace("|", ", "), list3))
	print("\n### Packs: how often a run that reaches a pack's first wave fails to clear its last (Normal, no unlocks, the named strategies)\n")
	for band: int in range(1, 7):
		print("\nBand %d (waves %d to %d):\n" % [band, band * 3 - 2, band * 3])
		_head(["Pack", "Runs that reached it", "Lost inside it", "Mean lives lost in its waves (no early calls)"])
		var ids: Array = []
		for p: Dictionary in _game.run.packs_of(band, &"", _tier):
			ids.append(String(p["id"]))
		for id: String in ids:
			var reached: int = 0
			var lost: int = 0
			var lives_lost: Array = []
			for r: Dictionary in rows:
				var packs: Array = _plan(int(r["seed"]))["packs"]
				if String(packs[band - 1]) != id:
					continue
				var first_wave: int = band * 3 - 3
				if int(r["reached"]) <= first_wave:
					continue
				reached += 1
				if not bool(r["won"]) and int(r["reached"]) <= band * 3:
					lost += 1
				if int(r["early"]) == 0:
					var sum: int = 0
					var complete: bool = true
					for w: int in range(first_wave, band * 3):
						if (r["lives_at"] as Array).size() <= w:
							complete = false
							break
						sum += int(r["lives_at"][w]) - (int(r["lives_pre"][w + 1]) if (r["lives_pre"] as Array).size() > w + 1 else int(r["lives"]))
					if complete:
						lives_lost.append(sum)
			_row([id, reached, _rate(lost, reached), "%.2f" % _mean(lives_lost) if not lives_lost.is_empty() else "-"])


func _distinct_seeds(rows: Array) -> int:
	var seen: Dictionary = {}
	for r: Dictionary in rows:
		seen[int(r["i"])] = true
	return seen.size()


func _map_row(label: String, list: Array) -> Array:
	var early: int = 0
	var boss_lost: int = 0
	for r: Dictionary in list:
		if not bool(r["won"]) and int(r["reached"]) <= 6:
			early += 1
		if not bool(r["won"]) and int(r["reached"]) >= 18:
			boss_lost += 1
	return [label, _distinct_seeds(list), list.size(), _rate(_won(list), list.size()), "%.1f" % _mean(list.map(func(r: Dictionary) -> float: return float(r["cleared"]))), _pct(early, list.size()), _pct(boss_lost, list.size())]


# Towers in won runs.

func _tower_tables() -> void:
	print("\n### Towers and paths standing at the end of won runs\n")
	for config: String in ["base_r0", "all_r0"]:
		var won: Array = _where(_rates[config], func(r: Dictionary) -> bool: return bool(r["won"]))
		print("\n%s (%d won runs):\n" % [CONFIG_NAMES[config], won.size()])
		_head(["Tower or path", "Won runs with at least one", "Mean built"])
		var keys: Array = []
		for r: Dictionary in won:
			for k: String in (r["mix"] as Dictionary).keys():
				if not keys.has(k):
					keys.append(k)
		keys.sort()
		for k: String in keys:
			var has: int = 0
			var total: int = 0
			for r: Dictionary in won:
				var n: int = int((r["mix"] as Dictionary).get(k, 0))
				total += n
				has += 1 if n > 0 else 0
			_row([k, _pct(has, won.size()), "%.2f" % (float(total) / won.size())])


# Cards.

func _card_tables() -> void:
	print("\n### Cards: offered, picked and win rate\n")
	for config: String in ["base_r0", "all_r0"]:
		var rows: Array = _rates[config]
		if rows.is_empty():
			continue
		var base_rate: float = float(_won(rows)) / rows.size()
		var random_rows: Array = _where(rows, func(r: Dictionary) -> bool: return String(r["strategy"]).begins_with("random_"))
		print("\n%s. Win rate of all plays %s. The last two columns use only the four random-pick strategies, where the pick does not depend on the card: the win rate of runs that picked the card against runs that were offered it and did not pick it.\n" % [CONFIG_NAMES[config], _pct(_won(rows), rows.size())])
		_head(["Card", "Times offered", "Times picked", "Pick rate", "Win rate of runs that picked it", "Random picks: picked", "Random picks: offered, not picked"])
		for c: int in _cards.size():
			var offered: int = 0
			var picked: int = 0
			var picked_runs: int = 0
			var picked_wins: int = 0
			for r: Dictionary in rows:
				var seen: bool = false
				for list: Array in r["offered"]:
					if _has(list, c):
						offered += 1
						seen = true
				if _has(r["picks"], c):
					picked_runs += 1
					picked_wins += 1 if bool(r["won"]) else 0
				picked += _count(r["picks"], c)
			var in_picked: int = 0
			var in_picked_won: int = 0
			var out_picked: int = 0
			var out_picked_won: int = 0
			for r: Dictionary in random_rows:
				var was_offered: bool = false
				for list2: Array in r["offered"]:
					was_offered = was_offered or _has(list2, c)
				if not was_offered:
					continue
				if _has(r["picks"], c):
					in_picked += 1
					in_picked_won += 1 if bool(r["won"]) else 0
				else:
					out_picked += 1
					out_picked_won += 1 if bool(r["won"]) else 0
			if offered == 0:
				continue
			_row([_cards[c], offered, picked, _pct(picked, offered), _rate(picked_wins, picked_runs), _rate(in_picked_won, in_picked), _rate(out_picked_won, out_picked)])
		print()


## JSON numbers read back as floats, so card indexes are compared as ints.
func _has(list: Array, c: int) -> bool:
	return _count(list, c) > 0


func _count(list: Array, c: int) -> int:
	var n: int = 0
	for v: Variant in list:
		if int(v) == c:
			n += 1
	return n


# What each card is worth, from the saved-draft experiment.

func _cardvalue_tables() -> void:
	for pool: String in ["base", "all"]:
		var rows: Array = _load_rows_named("cardvalue_%s_" % pool)
		if rows.is_empty():
			continue
		print("
### What each card is worth, %s (%d drafts, each offered card taken in turn and the run played on)
" % ["no unlocks" if pool == "base" else "all cards", rows.size()])
		print("Each draft was saved before the pick. Each of its 3 offered cards was then taken and the same random-picking strategy played the run to its end. A card's gain is its outcome less the average outcome of the 3 cards offered in that draft, so it needs no correction for how strong the run was at that draft. Win gain is in points of win rate. Lives gain is in lives left at the end (0 for a loss). The three right columns split the win gain by draft: picks 1 to 6, 7 to 12, 13 to 17.
")
		_head(["Card", "Times offered", "Win gain (points)", "Lives gain", "Waves cleared gain", "Win gain, picks 1 to 6", "Picks 7 to 12", "Picks 13 to 17"])
		var stats: Dictionary = {}
		for r: Dictionary in rows:
			var outcomes: Array = r["outcomes"]
			var win_mean: float = 0.0
			var lives_mean: float = 0.0
			var cleared_mean: float = 0.0
			for o: Dictionary in outcomes:
				win_mean += 1.0 if bool(o["won"]) else 0.0
				lives_mean += float(o["lives"])
				cleared_mean += float(o["cleared"])
			win_mean /= outcomes.size()
			lives_mean /= outcomes.size()
			cleared_mean /= outcomes.size()
			var stage: int = 0 if int(r["k"]) < 6 else (1 if int(r["k"]) < 12 else 2)
			for o: Dictionary in outcomes:
				var id: String = o["card"]
				if not stats.has(id):
					stats[id] = {"n": 0, "win": 0.0, "lives": 0.0, "cleared": 0.0, "sn": [0, 0, 0], "sw": [0.0, 0.0, 0.0]}
				var item: Dictionary = stats[id]
				item["n"] = int(item["n"]) + 1
				var gain: float = (1.0 if bool(o["won"]) else 0.0) - win_mean
				item["win"] = float(item["win"]) + gain
				item["lives"] = float(item["lives"]) + float(o["lives"]) - lives_mean
				item["cleared"] = float(item["cleared"]) + float(o["cleared"]) - cleared_mean
				item["sn"][stage] = int(item["sn"][stage]) + 1
				item["sw"][stage] = float(item["sw"][stage]) + gain
		var ids: Array = stats.keys()
		ids.sort_custom(func(a: String, b: String) -> bool: return float(stats[a]["win"]) / int(stats[a]["n"]) > float(stats[b]["win"]) / int(stats[b]["n"]))
		for id: String in ids:
			var item2: Dictionary = stats[id]
			var n: int = int(item2["n"])
			var cells: Array = [id, n, "%+.1f" % (100.0 * float(item2["win"]) / n), "%+.1f" % (float(item2["lives"]) / n), "%+.2f" % (float(item2["cleared"]) / n)]
			for stage: int in 3:
				var sn: int = int(item2["sn"][stage])
				cells.append(("%+.1f (n %d)" % [100.0 * float(item2["sw"][stage]) / sn, sn]) if sn > 0 else "-")
			_row(cells)
		print()


func _load_rows_named(prefix: String) -> Array:
	return _load_rows(prefix)


# The daily.

func _daily_tables() -> void:
	print("\n### The daily: the next 400 days (2026-10-25 to 2027-11-28)\n")
	var days: Array = _load_rows("daily_")
	if days.is_empty():
		print("(no daily files)")
		return
	var named: int = 0
	var extra_tried: int = 0
	var extra_won: int = 0
	var unwon: Array = []
	for d: Dictionary in days:
		var won_named: bool = false
		for p: Dictionary in d["plays"]:
			won_named = won_named or bool(p["won"])
		if won_named:
			named += 1
		elif d.has("extra"):
			extra_tried += 1
			if bool(d["extra"]["won"]):
				extra_won += 1
			else:
				unwon.append(d)
		else:
			unwon.append(d)
	_head(["Measure", "Days"])
	_row(["Days played", days.size()])
	_row(["Won by at least one of the 16 named strategies", _rate(named, days.size())])
	_row(["Not won by a named strategy, won by one of 100 random strategies", _rate(extra_won, days.size() - named)])
	_row(["Won by some strategy in all", _rate(named + extra_won, days.size())])
	_row(["Not won by any strategy tried", _rate(unwon.size(), days.size())])
	print("\nPer strategy, share of the %d days won:\n" % days.size())
	_head(["Strategy", "Days won"])
	var ids: Array = []
	for p: Dictionary in days[0]["plays"]:
		ids.append(p["strategy"])
	for id: String in ids:
		var won: int = 0
		for d: Dictionary in days:
			for p: Dictionary in d["plays"]:
				if p["strategy"] == id and bool(p["won"]):
					won += 1
		_row([id, _rate(won, days.size())])
	var every: Array = []
	for d: Dictionary in days:
		for p: Dictionary in d["plays"]:
			every.append(p)
	_row(["**All 16**", _rate(_won(every), every.size())])
	print("\nBy boss:\n")
	_head(["Boss", "Days", "Won by a named strategy", "Won by any tried", "Share of the 16 plays that won"])
	for boss: String in _bosses():
		var list: Array = _where(days, func(d: Dictionary) -> bool: return d["boss"] == boss)
		var any_named: int = 0
		var any_all: int = 0
		var plays: Array = []
		for d: Dictionary in list:
			var won_named: bool = false
			for p: Dictionary in d["plays"]:
				won_named = won_named or bool(p["won"])
				plays.append(p)
			any_named += 1 if won_named else 0
			any_all += 1 if (won_named or (d.has("extra") and bool(d["extra"]["won"]))) else 0
		_row([boss, list.size(), _rate(any_named, list.size()), _rate(any_all, list.size()), _pct(_won(plays), plays.size())])
	print("\nDays no strategy won (%d):\n" % unwon.size())
	if not unwon.is_empty():
		_head(["Day", "Seed", "Stack", "Boss", "Most waves cleared by a named strategy", "Best random strategy: waves cleared (of 100 tried)"])
		for d: Dictionary in unwon:
			var best: int = 0
			for p: Dictionary in d["plays"]:
				best = maxi(best, int(p["cleared"]))
			_row([d["day"], int(d["seed"]), String(d["stack"]).replace("|", ", "), d["boss"], best, str(int(d["extra"]["cleared"])) if d.has("extra") else "-"])
	var deep_rows: Array = []
	for file: String in _files("deep_"):
		deep_rows.append_array(_read(file)["rows"])
	if not deep_rows.is_empty():
		print("\nThe unwon days again, with more random strategies each (400 for all ten, then 1500 for the four that stayed unwon):\n")
		_head(["Day", "Stack", "Boss", "Strategies tried", "Won", "Most waves cleared", "Lives left if won"])
		var by_day: Dictionary = {}
		for line: Dictionary in deep_rows:
			if not by_day.has(line["day"]) or int(line["found"]["tried"]) >= int(by_day[line["day"]]["found"]["tried"]):
				by_day[line["day"]] = line
		var keys: Array = by_day.keys()
		keys.sort()
		for day: String in keys:
			var f: Dictionary = by_day[day]["found"]
			_row([day, String(by_day[day]["stack"]).replace("|", ", "), by_day[day]["boss"], int(f["tried"]), "yes" if bool(f["won"]) else "no", int(f["cleared"]), int(f["lives"]) if bool(f["won"]) else "-"])
	print("\nLongest run of days in a row that some strategy won: %d. Longest run of days that none won: %d.\n" % _streaks(days))


func _streaks(days: Array) -> Array:
	var best_won: int = 0
	var best_lost: int = 0
	var run_won: int = 0
	var run_lost: int = 0
	for d: Dictionary in days:
		var any: bool = d.has("extra") and bool(d["extra"]["won"])
		for p: Dictionary in d["plays"]:
			any = any or bool(p["won"])
		if any:
			run_won += 1
			run_lost = 0
		else:
			run_lost += 1
			run_won = 0
		best_won = maxi(best_won, run_won)
		best_lost = maxi(best_lost, run_lost)
	return [best_won, best_lost]


# The risk cards.

func _risk_tables() -> void:
	print("\n### Risk cards: creatures on the map at once\n")
	var static_data: Dictionary = _read("static.json")
	if not static_data.is_empty():
		print("What a pack wave spawns with each risk card (`RunPacks.spawn_total`, a Puffball counts with its Puffs, the 120 bound of RULES 14.3 applies to every pack wave with any one card):\n")
		var cards: Array = ["none", "crowded_night", "thick_hides", "hurry_night", "gateless_night", "flock", "moonlit_wager", "crasher_escort", "pip_parade"]
		_head(["Card", "Largest wave (creatures)", "Where", "Packs waves at 80 or more", "Over 120"])
		for card: String in cards:
			var best: int = 0
			var where: String = ""
			var big: int = 0
			var over: int = 0
			for line: Dictionary in static_data["spawn"]:
				var n: int = int(line[card])
				if n > best:
					best = n
					where = "%s wave %d" % [line["pack"], int(line["wave"])]
				big += 1 if n >= 80 else 0
				over += 1 if n > 120 else 0
			_row([card, best, where, big, over])
	for file: String in _files("risk_"):
		var data: Dictionary = _read(file)
		var rows: Array = data["rows"]
		print("\nPlayed peaks. Baseline play: `%s` on seeds %d to %d (%d plays; Normal, every card). Before each wave from 2 to 17 the battle was saved, then that wave was played again with each risk card on it, on the same towers, with no more buying. Peak is the most creatures on the map at once during that wave and any wave it overlapped.\n" % [data["strategy"], int(data["first"]), int(data["first"]) + int(data["count"]) - 1, int(data["count"])])
		_head(["Card", "Waves played", "Peak: median", "Peak: 90th percentile", "Peak: most", "Where (seed index, wave)", "Peak, waves 12 to 17: median / most", "Lives lost (mean)", "Gold gained (mean)", "Runs lost in the wave"])
		for card: String in ["none", "crowded_night", "thick_hides", "hurry_night", "gateless_night", "flock", "moonlit_wager", "crasher_escort", "pip_parade"]:
			var list: Array = _where(rows, func(r: Dictionary) -> bool: return r["card"] == card and not r.has("bad_branch"))
			if list.is_empty():
				continue
			var peaks: Array = list.map(func(r: Dictionary) -> int: return int(r["peak"]))
			var late: Array = _where(list, func(r: Dictionary) -> bool: return int(r["wave"]) >= 11).map(func(r: Dictionary) -> int: return int(r["peak"]))
			var worst: Dictionary = list[0]
			for r: Dictionary in list:
				if int(r["peak"]) > int(worst["peak"]):
					worst = r
			var lost: int = list.filter(func(r: Dictionary) -> bool: return bool(r["lost"])).size()
			_row([card, list.size(), "%d" % _quant(peaks, 0.5), "%d" % _quant(peaks, 0.9), peaks.max(), "(%d, %d)" % [int(worst["i"]), int(worst["wave"]) + 1],
				("%d / %d" % [_quant(late, 0.5), late.max()]) if not late.is_empty() else "-",
				"%.2f" % _mean(list.map(func(r: Dictionary) -> float: return float(r["lives_lost"]))), "%.0f" % _mean(list.map(func(r: Dictionary) -> float: return float(r["gold_gain"]))), _pct(lost, list.size())])
	print()


# What-ifs: other RunData numbers (tweak=...).

func _whatif_tables() -> void:
	var files: Array[String] = _files("whatif_")
	if files.is_empty():
		return
	print("\n### What-ifs on run numbers\n")
	_head(["What-if", "Setting", "Plays", "Won", "Won runs: mean min", "Reached wave 18", "Won of those"])
	var base: Dictionary = _read("rates_base_r0_1.json")
	if not base.is_empty():
		var base_rows: Array = base["rows"]
		var base_won: Array = _where(base_rows, func(r: Dictionary) -> bool: return bool(r["won"]))
		var base_boss: Array = _where(base_rows, func(r: Dictionary) -> bool: return int(r["reached"]) >= 18)
		_row(["none (the report's numbers, same seeds)", "Normal, base", base_rows.size(), _rate(base_won.size(), base_rows.size()), "%.1f" % _mean(base_won.map(func(r: Dictionary) -> float: return _minutes(r))),
			_rate(base_boss.size(), base_rows.size()), _rate(base_won.size(), base_boss.size())])
	for file: String in files:
		var data: Dictionary = _read(file)
		var rows: Array = data["rows"]
		var won: Array = _where(rows, func(r: Dictionary) -> bool: return bool(r["won"]))
		var boss: Array = _where(rows, func(r: Dictionary) -> bool: return int(r["reached"]) >= 18)
		_row([data.get("tweak", "-"), "%s, %s" % ["Relaxed" if bool(data["relaxed"]) else "Normal", data["pool"]], rows.size(), _rate(won.size(), rows.size()),
			"%.1f" % _mean(won.map(func(r: Dictionary) -> float: return _minutes(r))) if not won.is_empty() else "-", _rate(boss.size(), rows.size()), _rate(won.size(), boss.size())])
	print()


# Ironshell at armor 10 (commit c015b05) against armor 6 (the commit measured).

func _ironshell_tables() -> void:
	if _files("ironshell_").is_empty():
		return
	print("
### Ironshell runs again at armor 10 (commit c015b05), same seeds and strategies
")
	_head(["Setting", "Plays", "Won at armor 6", "Won at armor 10", "Started wave 18 (armor 10)", "Won of those, armor 6", "Won of those, armor 10"])
	for config: String in CONFIGS:
		var fresh: Array = _read("ironshell_%s.json" % config).get("rows", [])
		if fresh.is_empty():
			continue
		var old: Array = _where(_rates[config], func(r: Dictionary) -> bool: return r["boss"] == "ironshell")
		var old_boss: Array = _where(old, func(r: Dictionary) -> bool: return int(r["reached"]) >= 18)
		var new_boss: Array = _where(fresh, func(r: Dictionary) -> bool: return int(r["reached"]) >= 18)
		_row([CONFIG_NAMES[config], fresh.size(), _rate(_won(old), old.size()), _rate(_won(fresh), fresh.size()), new_boss.size(), _rate(_won(old_boss), old_boss.size()), _rate(_won(new_boss), new_boss.size())])
	var old_days: Array = []
	for d: Dictionary in _load_rows("daily_"):
		if d["boss"] == "ironshell":
			old_days.append(d)
	var new_days: Array = _load_rows("ironshell_daily_")
	if not new_days.is_empty():
		print("
The daily, Ironshell days (%d days):
" % new_days.size())
		_head(["Armor", "Days won by a named strategy", "Days won by any (named, then up to 100 random)", "Plays won, of 16 a day"])
		for item: Array in [["6", old_days], ["10", new_days]]:
			var named: int = 0
			var any: int = 0
			var plays: Array = []
			for d: Dictionary in item[1]:
				var w: bool = false
				for p: Dictionary in d["plays"]:
					w = w or bool(p["won"])
					plays.append(p)
				named += 1 if w else 0
				any += 1 if (w or (d.has("extra") and bool(d["extra"]["won"]))) else 0
			_row([item[0], _rate(named, item[1].size()), _rate(any, item[1].size()), _pct(_won(plays), plays.size())])
	print()


# Lives and Tea Break.

func _lives_tables() -> void:
	print("
### Lives decide the boss wave (Normal, the named strategies)
")
	for config: String in ["base_r0", "all_r0"]:
		var rows: Array = _where(_rates[config], func(r: Dictionary) -> bool: return int(r["reached"]) >= 18)
		print("
%s: runs that started wave 18, by lives when it started:
" % CONFIG_NAMES[config])
		_head(["Lives at the start of wave 18", "Runs", "Won", "Of the wins, boss reached the base"])
		for band: Array in [[0, 10], [11, 20], [21, 25], [26, 30], [31, 1000]]:
			var list: Array = _where(rows, func(r: Dictionary) -> bool: return int(r["lives_at"][17]) >= int(band[0]) and int(r["lives_at"][17]) <= int(band[1]))
			var won: Array = _where(list, func(r: Dictionary) -> bool: return bool(r["won"]))
			var leaked: int = won.filter(func(r: Dictionary) -> bool: return int(r["boss_steps"]) == 0).size()
			_row(["%d to %d" % [band[0], band[1]] if int(band[1]) < 1000 else "%d or more" % band[0], list.size(), _rate(won.size(), list.size()), _rate(leaked, won.size())])
	print("
By the Tea Break cards a run picked (all plays, Normal):
")
	_head(["Setting", "Tea Breaks picked", "Plays", "Won"])
	var tea: int = _cards.find("tea_break")
	for config: String in ["base_r0", "all_r0"]:
		for n: int in 7:
			var list2: Array = _where(_rates[config], func(r: Dictionary) -> bool: return _count(r["picks"], tea) == n if n < 6 else _count(r["picks"], tea) >= 6)
			if not list2.is_empty():
				_row([CONFIG_NAMES[config], str(n) if n < 6 else "6 or more", list2.size(), _rate(_won(list2), list2.size())])
# B4: the bars of RULES 14.8 and 15 (docs/balance/runs-2026-10-25.md).

var _plan_cache: Dictionary = {}


func _plan_of(run_seed: int) -> Dictionary:
	if not _plan_cache.has(run_seed):
		_plan_cache[run_seed] = _plan(run_seed)
	return _plan_cache[run_seed]


## True when the play ended lost with `wave` or fewer waves started. A play stopped on purpose (stop=N) is not lost.
func _lost_by(r: Dictionary, wave: int) -> bool:
	return not bool(r["won"]) and not bool(r.get("stopped", false)) and int(r["reached"]) <= wave


## The band 6 pack of a play: the forced one, or the seed's own.
func _boss_pack_of(r: Dictionary) -> String:
	if r.has("pack"):
		return String(r["pack"])
	return String(_plan_of(int(r["seed"]))["packs"][5])


## The pack of a play in a band.
func _pack_in_band(r: Dictionary, band: int) -> String:
	if r.has("pack"):
		for p: Dictionary in _game.run.packs:
			if String(p["id"]) == String(r["pack"]) and int(p["band"]) == band:
				return String(r["pack"])
	return String(_plan_of(int(r["seed"]))["packs"][band - 1])


## Strategy id to [wins, plays].
func _strategy_rates(rows: Array) -> Dictionary:
	var out: Dictionary = {}
	for r: Dictionary in rows:
		var id: String = String(r["strategy"])
		if not out.has(id):
			out[id] = [0, 0]
		out[id][1] = int(out[id][1]) + 1
		if bool(r["won"]):
			out[id][0] = int(out[id][0]) + 1
	return out


## [id, wins, plays] of the best strategy.
func _best_strategy(rows: Array) -> Array:
	var rates: Dictionary = _strategy_rates(rows)
	var best: Array = ["", 0, 1]
	var best_rate: float = -1.0
	for id: String in rates.keys():
		var rate: float = float(rates[id][0]) / float(rates[id][1])
		if rate > best_rate:
			best_rate = rate
			best = [id, rates[id][0], rates[id][1]]
	return best


func _rows_of_seeds(rows: Array, first: int, last: int) -> Array:
	return rows.filter(func(r: Dictionary) -> bool: return int(r["i"]) >= first and int(r["i"]) <= last)


## The boss pack table: pack id to {"plays", "started", "won", "boss"}.
func _boss_pack_stats(rows: Array) -> Dictionary:
	var out: Dictionary = {}
	for p: Dictionary in _game.run.packs_of(6, &"", _tier):
		out[String(p["id"])] = {"plays": 0, "started": 0, "won": 0, "boss": String(p["boss"])}
	for r: Dictionary in rows:
		var id: String = _boss_pack_of(r)
		if not out.has(id):
			continue
		out[id]["plays"] = int(out[id]["plays"]) + 1
		if int(r["reached"]) >= 18:
			out[id]["started"] = int(out[id]["started"]) + 1
			if bool(r["won"]):
				out[id]["won"] = int(out[id]["won"]) + 1
	return out


func _boss_b4() -> void:
	print("\n### The boss: each band 6 pack (Normal, base cards, the 16 named strategies, seeds 1 to 200)\n")
	var rows: Array = _rates["base_r0"]
	var stats: Dictionary = _boss_pack_stats(rows)
	_head(["Pack", "Boss", "Seeds", "Plays", "Started wave 18", "Won of those", "Bar 50% to 75%"])
	var ids: Array = stats.keys()
	ids.sort()
	for id: String in ids:
		var item: Dictionary = stats[id]
		var seeds: Dictionary = {}
		for r: Dictionary in rows:
			if _boss_pack_of(r) == id:
				seeds[int(r["i"])] = true
		var share: float = 100.0 * float(item["won"]) / maxf(float(item["started"]), 1.0)
		_row([id, item["boss"], seeds.size(), item["plays"], item["started"], _rate(int(item["won"]), int(item["started"])), "met" if share >= 50.0 and share <= 75.0 else "NOT MET"])
	print("\nBy boss:\n")
	_head(["Boss", "Plays", "Started wave 18", "Won of those"])
	for boss: String in _bosses():
		var plays: int = 0
		var started: int = 0
		var won: int = 0
		for id: String in ids:
			if stats[id]["boss"] == boss:
				plays += int(stats[id]["plays"])
				started += int(stats[id]["started"])
				won += int(stats[id]["won"])
		_row([boss, plays, started, _rate(won, started)])
	var by_strategy: Dictionary = {}
	for r: Dictionary in rows:
		if int(r["reached"]) >= 18:
			var id2: String = String(r["strategy"])
			if not by_strategy.has(id2):
				by_strategy[id2] = [0, 0]
			by_strategy[id2][1] = int(by_strategy[id2][1]) + 1
			by_strategy[id2][0] = int(by_strategy[id2][0]) + (1 if bool(r["won"]) else 0)
	print("\nBy strategy, the runs that started wave 18:\n")
	_head(["Strategy", "Started wave 18", "Won of those"])
	for id3: String in by_strategy.keys():
		_row([id3, by_strategy[id3][1], _rate(int(by_strategy[id3][0]), int(by_strategy[id3][1]))])
	print()


## Fair maps: each segment against all maps, each stack of 4 or more seeds by wave 6, and each pack of bands 1 to 5.
func _fair_b4() -> void:
	var rows: Array = _rates["base_r0"]
	var overall: float = float(_won(rows)) / maxf(float(rows.size()), 1.0)
	print("\n### Fair maps: each segment against all runs (Normal, base cards, seeds 1 to 200; all runs win %.1f%%)\n" % (100.0 * overall))
	_head(["Segment", "Seeds", "Plays", "Won", "Times all runs", "Bar 0.75"])
	for kind: Array in [["top", 0], ["middle", 1], ["bottom", 2]]:
		var names: Array = []
		for r: Dictionary in rows:
			var piece: String = String(r["stack"]).split("|")[int(kind[1])]
			if not names.has(piece):
				names.append(piece)
		names.sort()
		for piece: String in names:
			var list: Array = _where(rows, func(r: Dictionary) -> bool: return String(r["stack"]).split("|")[int(kind[1])] == piece)
			var rate: float = float(_won(list)) / float(list.size())
			_row([piece, _distinct_seeds(list), list.size(), _pct(_won(list), list.size()), "%.3f" % (rate / overall), "met" if rate / overall >= 0.75 else "NOT MET"])
	print("\n### Fair maps: stacks that 4 or more seeds use, lost by wave 6 (bar: at most 10%)\n")
	_head(["Stack (top, middle, bottom)", "Seeds", "Plays", "Won", "Lost by wave 6", "Bar 10%"])
	var stacks: Array = []
	for r: Dictionary in rows:
		if not stacks.has(r["stack"]):
			stacks.append(r["stack"])
	stacks.sort()
	var failing: int = 0
	var checked: int = 0
	for stack: String in stacks:
		var list2: Array = _where(rows, func(r: Dictionary) -> bool: return r["stack"] == stack)
		var seeds: int = _distinct_seeds(list2)
		var early: int = list2.filter(func(r: Dictionary) -> bool: return _lost_by(r, 6)).size()
		var share: float = 100.0 * early / list2.size()
		if seeds >= 4:
			checked += 1
			if share > 10.0:
				failing += 1
		_row([stack.replace("|", ", "), seeds, list2.size(), _pct(_won(list2), list2.size()), _pct(early, list2.size()), ("met" if share <= 10.0 else "NOT MET") if seeds >= 4 else "(under 4 seeds)"])
	var early_all: int = rows.filter(func(r: Dictionary) -> bool: return _lost_by(r, 6)).size()
	print("\n%d stacks drawn, %d with 4 or more seeds, %d of those above 10%%. All runs: %s lost by wave 6.\n" % [stacks.size(), checked, failing, _pct(early_all, rows.size())])
	print("\n### Fair packs: bands 1 to 5, the share of runs that reach a pack's first wave and are lost inside it (bar: at most 10%)\n")
	_head(["Pack", "Seeds", "Runs that reached it", "Lost inside it", "Mean lives lost inside (no early calls)", "Bar 10%"])
	for band: int in range(1, 6):
		for pack: Dictionary in _game.run.packs_of(band, &"", _tier):
			var info: Dictionary = _pack_stats(rows, band, String(pack["id"]))
			var share2: float = 100.0 * int(info["lost"]) / maxf(float(info["reached"]), 1.0)
			_row([pack["id"], info["seeds"], info["reached"], _pct(int(info["lost"]), int(info["reached"])), ("%.2f" % _mean(info["lives"])) if not (info["lives"] as Array).is_empty() else "-", "met" if share2 <= 10.0 else "NOT MET"])
	print()


## For a pack of a band: seeds that drew it, runs that reached its first wave, runs lost inside it, lives lost in its waves.
func _pack_stats(rows: Array, band: int, id: String) -> Dictionary:
	var seeds: Dictionary = {}
	var reached: int = 0
	var lost: int = 0
	var lives_lost: Array = []
	var first_wave: int = band * 3 - 3
	for r: Dictionary in rows:
		if _pack_in_band(r, band) != id:
			continue
		seeds[int(r["i"])] = true
		if int(r["reached"]) <= first_wave:
			continue
		reached += 1
		if not bool(r["won"]) and not bool(r.get("stopped", false)) and int(r["reached"]) <= band * 3:
			lost += 1
		if int(r["early"]) == 0 and not bool(r.get("stopped", false)):
			var sum: int = 0
			var complete: bool = true
			for w: int in range(first_wave, band * 3):
				if (r["lives_at"] as Array).size() <= w:
					complete = false
					break
				sum += int(r["lives_at"][w]) - (int(r["lives_pre"][w + 1]) if (r["lives_pre"] as Array).size() > w + 1 else int(r["lives"]))
			if complete:
				lives_lost.append(sum)
	return {"seeds": seeds.size(), "reached": reached, "lost": lost, "lives": lives_lost}


## The forced stack and pack files: every stack or pack that failed a check, played on seeds 1 to 200.
func _forced_b4() -> void:
	var stack_rows: Array = _load_rows("force_stack_")
	if not stack_rows.is_empty():
		print("\n### Forced stacks: each failing stack on every seed from 1 to 200 (16 strategies a seed, stopped when wave 6 was cleared)\n")
		_head(["Stack", "Seeds", "Plays", "Lost by wave 6", "Natural: seeds, plays, lost by wave 6", "Bar 10%"])
		var stacks: Array = []
		for r: Dictionary in stack_rows:
			if not stacks.has(r["stack"]):
				stacks.append(r["stack"])
		stacks.sort()
		for stack: String in stacks:
			var list: Array = _where(stack_rows, func(r: Dictionary) -> bool: return r["stack"] == stack)
			var early: int = list.filter(func(r: Dictionary) -> bool: return _lost_by(r, 6)).size()
			var natural: Array = _where(_rates["base_r0"], func(r: Dictionary) -> bool: return r["stack"] == stack)
			var natural_early: int = natural.filter(func(r: Dictionary) -> bool: return _lost_by(r, 6)).size()
			_row([stack.replace("|", ", "), _distinct_seeds(list), list.size(), _pct(early, list.size()),
				"%d, %d, %s" % [_distinct_seeds(natural), natural.size(), _pct(natural_early, natural.size())], "met" if 100.0 * early / list.size() <= 10.0 else "NOT MET (a wall)"])
	var pack_rows: Array = _load_rows("force_pack_")
	if not pack_rows.is_empty():
		print("\n### Forced packs: each failing pack on every seed from 1 to 200 (16 strategies a seed)\n")
		_head(["Pack", "Seeds", "Plays", "Runs that reached its first wave", "Lost inside it", "Started wave 18, won of those (band 6)", "Natural: runs that reached it, lost inside", "Bar"])
		var ids: Array = []
		for r: Dictionary in pack_rows:
			if not ids.has(r["pack"]):
				ids.append(r["pack"])
		ids.sort()
		for id: String in ids:
			var list2: Array = _where(pack_rows, func(r: Dictionary) -> bool: return r["pack"] == id)
			var band: int = 0
			for p: Dictionary in _game.run.packs:
				if String(p["id"]) == id:
					band = int(p["band"])
			var info: Dictionary = _pack_stats(list2, band, id)
			var natural_info: Dictionary = _pack_stats(_rates["base_r0"], band, id)
			if band == 6:
				var boss: Dictionary = _boss_pack_stats(list2)[id]
				var share: float = 100.0 * int(boss["won"]) / maxf(float(boss["started"]), 1.0)
				var nat: Dictionary = _boss_pack_stats(_rates["base_r0"])[id]
				_row([id, _distinct_seeds(list2), list2.size(), "-", "-", "%d, %s" % [boss["started"], _rate(int(boss["won"]), int(boss["started"]))],
					"%d started, %s" % [nat["started"], _pct(int(nat["won"]), int(nat["started"]))], "met (50% to 75%)" if share >= 50.0 and share <= 75.0 else "NOT MET"])
			else:
				var share2: float = 100.0 * int(info["lost"]) / maxf(float(info["reached"]), 1.0)
				_row([id, _distinct_seeds(list2), list2.size(), info["reached"], _pct(int(info["lost"]), int(info["reached"])), "-",
					"%d, %s" % [natural_info["reached"], _pct(int(natural_info["lost"]), int(natural_info["reached"]))], "met (10%)" if share2 <= 10.0 else "NOT MET (a wall)"])
	print()


## Card id to the list of its gains (1 or 0 less the draft's mean) in a pool's card experiment.
func _card_gains(rows: Array) -> Dictionary:
	var gains: Dictionary = {}
	for r: Dictionary in rows:
		var outcomes: Array = r["outcomes"]
		var mean: float = 0.0
		for o: Dictionary in outcomes:
			mean += 1.0 if bool(o["won"]) else 0.0
		mean /= outcomes.size()
		for o: Dictionary in outcomes:
			var id: String = o["card"]
			if not gains.has(id):
				gains[id] = []
			(gains[id] as Array).append((1.0 if bool(o["won"]) else 0.0) - mean)
	return gains


func _se(list: Array) -> float:
	var m: float = _mean(list)
	var variance: float = 0.0
	for g: float in list:
		variance += (g - m) * (g - m)
	return sqrt(variance / maxf(float(list.size() - 1), 1.0) / list.size())


## The card experiment against its bar: no perk, gate, economy or risk card above +5 points.
func _cardbar_b4() -> void:
	for pool: String in ["base", "all"]:
		var rows: Array = _load_rows("cardvalue_%s_" % pool)
		if rows.is_empty():
			continue
		var gains: Dictionary = _card_gains(rows)
		print("\n### The card experiment, %s: %d drafts, seeds 1 to 200\n" % ["base cards" if pool == "base" else "every card", rows.size()])
		print("Win gain is in points of win rate against the average of the 3 offered cards; SE is the standard error of that mean. Tower cards are reported and not held to the 5 point bar. A gain over +5 but within one SE of it is read as noise (TUNING_RUNS 9.6).\n")
		_head(["Card", "Kind", "Offered", "Win gain (points)", "SE", "Bar +5"])
		var ids: Array = gains.keys()
		ids.sort_custom(func(a: String, b: String) -> bool: return _mean(gains[a]) > _mean(gains[b]))
		for id: String in ids:
			var list: Array = gains[id]
			var m: float = _mean(list)
			var kind: String = String(_game.run.card(StringName(id)).get("kind", ""))
			var gain: float = m * 100.0
			var verdict: String = "met"
			if kind == "tower":
				verdict = "reported (tower card)"
			elif gain > 5.0:
				verdict = "over by the number, within one SE: noise" if gain - 5.0 <= 100.0 * _se(list) else "NOT MET"
			_row([id, kind, list.size(), "%+.1f" % (100.0 * m), "%.1f" % (100.0 * _se(list)), verdict])
	print()


const RISK_CARDS: Array[String] = ["crowded_night", "thick_hides", "hurry_night", "gateless_night", "flock", "moonlit_wager", "crasher_escort", "pip_parade"]


## Per risk card, extra lives and gold against the same wave with no card: {"early": [lives, gold, pairs], "late": [...]}, the sums.
func _risk_pairs(rows: Array) -> Dictionary:
	var none: Dictionary = {}
	for r: Dictionary in rows:
		if r["card"] == "none" and not r.has("bad_branch"):
			none["%d:%d" % [int(r["i"]), int(r["wave"])]] = r
	var out: Dictionary = {}
	for card: String in RISK_CARDS:
		var early: Array = [0.0, 0.0, 0]
		var late: Array = [0.0, 0.0, 0]
		for r: Dictionary in rows:
			if r["card"] != card or r.has("bad_branch"):
				continue
			var key: String = "%d:%d" % [int(r["i"]), int(r["wave"])]
			if not none.has(key):
				continue
			var base: Dictionary = none[key]
			var bucket: Array = early if int(r["wave"]) <= 7 else late
			bucket[0] = float(bucket[0]) + float(r["lives_lost"]) - float(base["lives_lost"])
			bucket[1] = float(bucket[1]) + float(r["gold_gain"]) - float(base["gold_gain"])
			bucket[2] = int(bucket[2]) + 1
		out[card] = {"early": early, "late": late}
	return out


## {"per_life": card to gold a life in waves 2 to 8, "middle": the median of them, "outside": cards outside half to twice the middle}
func _risk_summary(rows: Array) -> Dictionary:
	var pairs: Dictionary = _risk_pairs(rows)
	var per_life: Dictionary = {}
	for card: String in RISK_CARDS:
		var e: Array = pairs[card]["early"]
		per_life[card] = (float(e[1]) / maxf(float(e[2]), 1.0)) / maxf(float(e[0]) / maxf(float(e[2]), 1.0), 0.001)
	var values: Array = per_life.values()
	values.sort()
	var middle: float = float(values[values.size() / 2])
	if values.size() % 2 == 0:
		middle = (float(values[values.size() / 2 - 1]) + float(values[values.size() / 2])) / 2.0
	var outside: Array = []
	for card: String in RISK_CARDS:
		var v: float = float(per_life[card])
		if v < middle / 2.0 or v > middle * 2.0:
			outside.append(card)
	return {"per_life": per_life, "middle": middle, "outside": outside}


## The risk replay: each risk card against the same wave with no risk card, waves 2 to 8, and the gold for each life.
func _riskfair_b4() -> void:
	var data: Dictionary = _read("risk_economy_wide.json")
	if data.is_empty():
		return
	var rows: Array = data["rows"]
	print("\n### Risk cards trade fairly: the risk replay (%s on seeds %d to %d, every card, each of waves 2 to 17 played again with each risk card)\n" % [data["strategy"], int(data["first"]), int(data["first"]) + int(data["count"]) - 1])
	print("Extra lives lost and extra gold gained against the same wave with no risk card, same towers, no more buying. Waves 2 to 8 are the waves where the bar is read; waves 9 to 17 are shown for the shape.\n")
	_head(["Card", "Waves 2 to 8: pairs", "Extra lives", "Extra gold", "Gold a life", "Waves 9 to 17: extra lives", "Extra gold", "Gold a life"])
	var pairs: Dictionary = _risk_pairs(rows)
	var summary: Dictionary = _risk_summary(rows)
	for card: String in RISK_CARDS:
		var e: Array = pairs[card]["early"]
		var l: Array = pairs[card]["late"]
		var n_e: float = maxf(float(e[2]), 1.0)
		var n_l: float = maxf(float(l[2]), 1.0)
		_row([card, e[2], "%+.2f" % (float(e[0]) / n_e), "%+.0f" % (float(e[1]) / n_e), "%.0f" % summary["per_life"][card], "%+.2f" % (float(l[0]) / n_l), "%+.0f" % (float(l[1]) / n_l),
			"%.0f" % ((float(l[1]) / n_l) / maxf(float(l[0]) / n_l, 0.001))])
	var middle: float = summary["middle"]
	print("\nMiddle value of the %d risk cards (the median; an even count takes the mean of the two in the middle): %.1f gold a life. Bar: from %.1f to %.1f. Gateless Night is reported, not held to it.\n" % [RISK_CARDS.size(), middle, middle / 2.0, middle * 2.0])
	var outside: Array = summary["outside"]
	print("Outside the range: %s.\n" % (", ".join(PackedStringArray(outside)) if not outside.is_empty() else "none"))


## Run length of won runs, grouped by the 12 to 16 minute bar.
func _length_b4() -> void:
	print("\n### Run length at 1x (wave time plus 15 s for each build phase), won runs\n")
	_head(["Setting", "Wins", "Mean min", "10th / 50th / 90th percentile", "Under 12", "12 to 16", "16 to 20", "Over 20", "Bar: mean 12 to 16"])
	for config: String in CONFIGS:
		var rows: Array = _where(_rates[config], func(r: Dictionary) -> bool: return bool(r["won"]))
		if rows.is_empty():
			continue
		var mins: Array = rows.map(func(r: Dictionary) -> float: return _minutes(r))
		var mean: float = _mean(mins)
		_row([CONFIG_NAMES[config], rows.size(), "%.1f" % mean, "%.1f / %.1f / %.1f" % [_quant(mins, 0.1), _quant(mins, 0.5), _quant(mins, 0.9)],
			_pct(mins.filter(func(m: float) -> bool: return m < 12.0).size(), mins.size()), _pct(mins.filter(func(m: float) -> bool: return m >= 12.0 and m < 16.0).size(), mins.size()),
			_pct(mins.filter(func(m: float) -> bool: return m >= 16.0 and m < 20.0).size(), mins.size()), _pct(mins.filter(func(m: float) -> bool: return m >= 20.0).size(), mins.size()),
			("met" if mean >= 12.0 and mean <= 16.0 else "NOT MET") if config == "base_r0" else "-"])
	print("\nNormal, base cards, won runs by early calls:\n")
	_head(["Kind", "Wins", "Mean min", "Wave time only, mean min", "Build phases (mean)", "Early calls (mean)", "Mean min at 30 s a build phase"])
	for group: Array in [["no early calls", false], ["early calls", true]]:
		var rows2: Array = _where(_rates["base_r0"], func(r: Dictionary) -> bool: return bool(r["won"]) and String(r["strategy"]).ends_with("_early") == bool(group[1]))
		if rows2.is_empty():
			continue
		_row([group[0], rows2.size(), "%.1f" % _mean(rows2.map(func(r: Dictionary) -> float: return _minutes(r))), "%.1f" % _mean(rows2.map(func(r: Dictionary) -> float: return _wave_minutes(r))),
			"%.1f" % _mean(rows2.map(func(r: Dictionary) -> float: return float(r["builds"]))), "%.1f" % _mean(rows2.map(func(r: Dictionary) -> float: return float(r["early"]))),
			"%.1f" % _mean(rows2.map(func(r: Dictionary) -> float: return (float(r["ticks"]) / 20.0 + 30.0 * int(r["builds"])) / 60.0))])
	print()


## Same seed, same run, with the save checks.
func _det_b4() -> void:
	print("\n### Same seed, same run (with the save checks of RunSession.from_data)\n")
	var files: Array = [["det.json", "Seeds 1 to 50, first 50 days"], ["det_more.json", "Seeds 51 to 200, days 50 to 149"]]
	_head(["Set", "Runs", "Same map twice", "Played twice equal", "Save in a wave equal", "Save with a draft open equal", "Saves really made (wave, draft)", "Dailies", "Played twice equal", "Wave save equal", "Draft save equal", "Saves refused by a load"])
	var refused: Array = []
	for item: Array in files:
		var d: Dictionary = _read(String(item[0]))
		if d.is_empty():
			continue
		var rows: Array = d["rows"]
		var days: Array = d["daily_rows"]
		var counts: Dictionary = {}
		for key: String in ["map_equal", "again_equal", "wave_restore_equal", "draft_restore_equal", "wave_restored", "draft_restored"]:
			counts[key] = rows.filter(func(r: Dictionary) -> bool: return bool(r.get(key, false))).size()
		var day_counts: Dictionary = {}
		for key: String in ["again_equal", "wave_restore_equal", "draft_restore_equal"]:
			day_counts[key] = days.filter(func(r: Dictionary) -> bool: return bool(r.get(key, false))).size()
		var refusals: int = 0
		var both: Array = rows.duplicate()
		both.append_array(days)
		for r: Dictionary in both:
			for key: String in ["wave_refused", "draft_refused"]:
				if String(r.get(key, "")) != "":
					refusals += 1
					refused.append("%s %s (%s)" % [str(r.get("i", r.get("day", ""))), r.get("strategy", ""), r[key]])
		_row([item[1], rows.size(), counts["map_equal"], counts["again_equal"], counts["wave_restore_equal"], counts["draft_restore_equal"], "%d, %d" % [counts["wave_restored"], counts["draft_restored"]],
			days.size(), day_counts["again_equal"], day_counts["wave_restore_equal"], day_counts["draft_restore_equal"], refusals])
	var first: Dictionary = _read("det.json")
	var again: Dictionary = _read("det_again.json")
	if not first.is_empty():
		print("\nFailures in det.json: %s. Failures in det_more.json: %s. Chain hash of the first process %d, of a second process %s: %s." % [str(first["failures"]), str(_read("det_more.json").get("failures", "missing")), int(first["chain_hash"]),
			("%d" % int(again["chain_hash"])) if again.has("chain_hash") else "missing", "equal" if again.has("chain_hash") and int(again["chain_hash"]) == int(first["chain_hash"]) else "NOT EQUAL"])
	print("Saves refused by a load: %s.\n" % (", ".join(PackedStringArray(refused)) if not refused.is_empty() else "none"))
	var wins: int = 0
	var total: int = 0
	for item2: Array in files:
		for r: Dictionary in _read(String(item2[0])).get("rows", []):
			total += 1
			wins += 1 if bool(r["won"]) else 0
	print("%d of the %d runs were wins, so the checks cover wins and losses.\n" % [wins, total])


## The daily against RULES 15's bar.
func _daily_b4() -> void:
	var days: Array = _load_rows("daily_")
	if days.is_empty():
		print("(no daily files)")
		return
	print("\n### The daily: %d days from %s (RULES 15)\n" % [days.size(), days[0]["day"]])
	var named: int = 0
	var extra_won: int = 0
	var unwon: Array = []
	var tried: Array = []
	var flags: Array = []
	for d: Dictionary in days:
		var won_named: bool = false
		for p: Dictionary in d["plays"]:
			won_named = won_named or bool(p["won"])
		var any: bool = won_named
		if won_named:
			named += 1
		elif d.has("extra"):
			tried.append(int(d["extra"]["tried"]))
			if bool(d["extra"]["won"]):
				extra_won += 1
				any = true
			else:
				unwon.append(d)
		else:
			unwon.append(d)
		flags.append(any)
	var longest_lost: int = 0
	var run_lost: int = 0
	for any_day: bool in flags:
		run_lost = 0 if any_day else run_lost + 1
		longest_lost = maxi(longest_lost, run_lost)
	var named_share: float = 100.0 * named / days.size()
	var all_share: float = 100.0 * (named + extra_won) / days.size()
	_head(["Measure", "Days", "Bar"])
	_row(["Won by at least one of the 16 named strategies", _rate(named, days.size()), "at least 60%: " + ("met" if named_share >= 60.0 else "NOT MET")])
	_row(["Not won by a named strategy, won by up to 400 random strategies", _rate(extra_won, days.size() - named), ""])
	_row(["Won by some strategy in all", _rate(named + extra_won, days.size()), "at least 98%: " + ("met" if all_share >= 98.0 else "NOT MET")])
	_row(["Not won by any strategy tried", _rate(unwon.size(), days.size()), ""])
	_row(["Longest run of days in a row that none won", longest_lost, "no two in a row: " + ("met" if longest_lost <= 1 else "NOT MET")])
	if not tried.is_empty():
		_row(["Random strategies tried on a day no named strategy won (median / 90th percentile / most)", "%d / %d / %d" % [_quant(tried, 0.5), _quant(tried, 0.9), int(tried.max())], ""])
	print("\nPer strategy, the share of the %d days won:\n" % days.size())
	_head(["Strategy", "Days won"])
	var ids: Array = []
	for p: Dictionary in days[0]["plays"]:
		ids.append(p["strategy"])
	for id: String in ids:
		var won: int = 0
		for d: Dictionary in days:
			for p: Dictionary in d["plays"]:
				if p["strategy"] == id and bool(p["won"]):
					won += 1
		_row([id, _rate(won, days.size())])
	var every: Array = []
	for d: Dictionary in days:
		for p: Dictionary in d["plays"]:
			every.append(p)
	_row(["**All 16**", _rate(_won(every), every.size())])
	print("\nBy boss:\n")
	_head(["Boss", "Days", "Won by a named strategy", "Won by any tried", "Share of the 16 plays that won"])
	for boss: String in _bosses():
		var list: Array = _where(days, func(d: Dictionary) -> bool: return d["boss"] == boss)
		var any_named: int = 0
		var any_all: int = 0
		var plays: Array = []
		for d: Dictionary in list:
			var won_named: bool = false
			for p: Dictionary in d["plays"]:
				won_named = won_named or bool(p["won"])
				plays.append(p)
			any_named += 1 if won_named else 0
			any_all += 1 if (won_named or (d.has("extra") and bool(d["extra"]["won"]))) else 0
		_row([boss, list.size(), _rate(any_named, list.size()), _rate(any_all, list.size()), _pct(_won(plays), plays.size())])
	var hard: Array = days.filter(func(d: Dictionary) -> bool: return d.has("extra"))
	if not hard.is_empty():
		print("\nDays no named strategy won, and what the random strategies did (%d days):\n" % hard.size())
		_head(["Day", "Stack", "Boss", "Most waves cleared by a named strategy", "Random strategies tried", "Won", "Lives left if won"])
		for d: Dictionary in hard:
			var best: int = 0
			for p: Dictionary in d["plays"]:
				best = maxi(best, int(p["cleared"]))
			var e: Dictionary = d["extra"]
			_row([d["day"], String(d["stack"]).replace("|", ", "), d["boss"], best, int(e["tried"]), "yes" if bool(e["won"]) else "no (best %d waves)" % int(e["cleared"]), int(e["lives"]) if bool(e["won"]) else "-"])
	print()


## What-ifs on the bots and on the pool, one row for each set of chunks, against the main run on the same seeds.
func _whatif_b4() -> void:
	var files: Array[String] = _files("whatif_")
	if files.is_empty():
		return
	var groups: Dictionary = {}
	var order: Array = []
	for file: String in files:
		var key: String = file.trim_suffix(".json")
		key = key.substr(0, key.rfind("_"))
		if not groups.has(key):
			groups[key] = []
			order.append(key)
		(groups[key] as Array).append(file)
	print("
### What-ifs on the bots and the pool (Normal; the main run's numbers are for the same seeds)
")
	_head(["What-if", "Bots", "Pool", "Seeds", "Plays", "Won (16 together)", "Main run, same seeds", "Difference (points)", "Best strategy", "Main run", "Started wave 18, won of those", "Main run", "Lost by wave 6", "Main run"])
	for key: String in order:
		var rows: Array = []
		var main: Array = []
		var data: Dictionary = {}
		var low: int = 100000
		var high: int = 0
		for file: String in groups[key]:
			data = _read(file)
			if (data["rows"] as Array).is_empty():
				continue
			rows.append_array(data["rows"])
			var config: String = "%s_r%d" % ["all" if data["pool"] == "all" else "base", 1 if bool(data["relaxed"]) else 0]
			var first: int = int(data["first"])
			var last: int = first + int(data["count"]) - 1
			low = mini(low, first)
			high = maxi(high, last)
			main.append_array(_rows_of_seeds(_rates[config], first, last))
		if rows.is_empty():
			continue
		var bots: Dictionary = data["bots"]
		var label: String = "Bakery from wave %d, perks %s%s" % [int(bots["bakery_from"]), ["blind", "fit", "all sidegrades passed"][int(bots["perk_fit"])], ", boss aim" if int(bots["boss_aim"]) == 1 else ""]
		var best: Array = _best_strategy(rows)
		var best_main: Array = _best_strategy(main)
		var boss: Array = rows.filter(func(r: Dictionary) -> bool: return int(r["reached"]) >= 18)
		var boss_main: Array = main.filter(func(r: Dictionary) -> bool: return int(r["reached"]) >= 18)
		var diff: float = 100.0 * _won(rows) / rows.size() - 100.0 * _won(main) / main.size()
		_row([key.trim_prefix("whatif_"), label, data["pool"], "%d to %d" % [low, high], rows.size(), _rate(_won(rows), rows.size()), _rate(_won(main), main.size()), "%+.1f" % diff,
			"%s %s" % [best[0], _pct(int(best[1]), int(best[2]))], "%s %s" % [best_main[0], _pct(int(best_main[1]), int(best_main[2]))],
			"%d, %s" % [boss.size(), _pct(_won(boss), boss.size())], "%d, %s" % [boss_main.size(), _pct(_won(boss_main), boss_main.size())],
			_pct(rows.filter(func(r: Dictionary) -> bool: return _lost_by(r, 6)).size(), rows.size()), _pct(main.filter(func(r: Dictionary) -> bool: return _lost_by(r, 6)).size(), main.size())])
	print()


## Phase B job lines: what to force (stacks and packs that fail a check), the seeds the search must try, and two fixed stacks.
func _flags_b4() -> void:
	var rows: Array = _rates["base_r0"]
	var out_dir: String = "OUTDIR"
	var lines: Array = []
	# Seeds 1 to 50 that no named strategy won.
	var won_seed: Dictionary = {}
	for r: Dictionary in rows:
		if int(r["i"]) <= 50:
			won_seed[int(r["i"])] = bool(won_seed.get(int(r["i"]), false)) or bool(r["won"])
	var search: Array = []
	for i: int in range(1, 51):
		if not bool(won_seed.get(i, false)):
			search.append(str(i))
	if not search.is_empty():
		lines.append(_flag_line("mode=search list=%s n=100 pool=base relaxed=0 out=%s/search_base_r0_list.json" % [",".join(PackedStringArray(search)), out_dir]))
	# Stacks of 4 or more seeds above 10% lost by wave 6, and the two mid_merge stacks of 3.4a.
	var stacks: Array = []
	for r: Dictionary in rows:
		if not stacks.has(r["stack"]):
			stacks.append(r["stack"])
	stacks.sort()
	var forced: Array = ["top_fork|mid_merge|bot_square", "top_twin|mid_merge|bot_square"]
	for stack: String in stacks:
		var list: Array = _where(rows, func(r: Dictionary) -> bool: return r["stack"] == stack)
		if _distinct_seeds(list) >= 4 and 100.0 * list.filter(func(r: Dictionary) -> bool: return _lost_by(r, 6)).size() / list.size() > 10.0 and not forced.has(stack):
			forced.append(stack)
	for stack: String in forced:
		for first: int in [1, 51, 101, 151]:
			lines.append(_flag_line("mode=rates first=%d count=50 pool=base relaxed=0 stack=%s stop=6 out=%s/force_stack_%s_%d.json" % [first, stack.replace("|", ","), out_dir, stack.replace("|", "_"), first]))
	# Packs of bands 1 to 5 above 10% lost inside, and band 6 packs outside 50% to 75%.
	for band: int in range(1, 6):
		for pack: Dictionary in _game.run.packs_of(band, &"", _tier):
			var info: Dictionary = _pack_stats(rows, band, String(pack["id"]))
			if 100.0 * int(info["lost"]) / maxf(float(info["reached"]), 1.0) > 10.0:
				for first: int in [1, 51, 101, 151]:
					lines.append(_flag_line("mode=rates first=%d count=50 pool=base relaxed=0 pack=%s stop=%d out=%s/force_pack_%s_%d.json" % [first, pack["id"], band * 3, out_dir, pack["id"], first]))
	var boss: Dictionary = _boss_pack_stats(rows)
	for id: String in boss.keys():
		var share: float = 100.0 * int(boss[id]["won"]) / maxf(float(boss[id]["started"]), 1.0)
		if share < 50.0 or share > 75.0:
			for first: int in [1, 51, 101, 151]:
				lines.append(_flag_line("mode=rates first=%d count=50 pool=base relaxed=0 pack=%s out=%s/force_pack_%s_%d.json" % [first, id, out_dir, id, first]))
	for line: String in lines:
		print(line)


## Every bar of RULES 14.8 and 15 in one table, with the numbers read from the files.
func _bars() -> void:
	print("\n### Every bar of RULES 14.8 and 15\n")
	_head(["Check", "Bar", "Result", "Met"])
	var base: Array = _rates["base_r0"]
	var relaxed: Array = _rates["base_r1"]
	# Every run can be won, seeds 1 to 50.
	var won_seed: Dictionary = {}
	for r: Dictionary in base:
		if int(r["i"]) <= 50:
			won_seed[int(r["i"])] = bool(won_seed.get(int(r["i"]), false)) or bool(r["won"])
	var named_seeds: int = 0
	for i: int in range(1, 51):
		named_seeds += 1 if bool(won_seed.get(i, false)) else 0
	var search_won: int = 0
	var search_tried: int = 0
	var search_miss: Array = []
	for r: Dictionary in _load_rows("search_base_r0_"):
		search_tried += 1
		if bool(r["best_won"]):
			search_won += 1
		else:
			search_miss.append(int(r["i"]))
	_row(["Every run can be won", "seeds 1 to 50: a named strategy or one of 100 random", "%d of 50 seeds won by a named strategy; random strategies won %d of the other %d (seeds with no win: %s)" % [named_seeds, search_won, search_tried, str(search_miss) if not search_miss.is_empty() else "none"],
		"met" if named_seeds + search_won >= 50 else "NOT MET"])
	# Normal.
	var best: Array = _best_strategy(base)
	var all_rate: float = 100.0 * _won(base) / maxf(float(base.size()), 1.0)
	var best_rate: float = 100.0 * int(best[1]) / maxf(float(best[2]), 1.0)
	var best_se: float = 100.0 * sqrt((float(best[1]) / float(best[2])) * (1.0 - float(best[1]) / float(best[2])) / float(best[2]))
	var best_verdict: String = "met"
	if best_rate > 75.0:
		best_verdict = "NOT MET: %.1f points over the ceiling, %.1f SEs" % [best_rate - 75.0, (best_rate - 75.0) / best_se]
	elif best_rate < 55.0:
		best_verdict = "NOT MET: %.1f points under the floor, %.1f SEs" % [55.0 - best_rate, (55.0 - best_rate) / best_se]
	_row(["Normal, best strategy", "55% to 75%", "%s %s, SE %.1f points" % [best[0], _rate(int(best[1]), int(best[2])), best_se], best_verdict])
	_row(["Normal, the 16 together", "35% to 55%", _rate(_won(base), base.size()), "met" if all_rate >= 35.0 and all_rate <= 55.0 else "NOT MET"])
	var best_r: Array = _best_strategy(relaxed)
	var best_r_rate: float = 100.0 * int(best_r[1]) / maxf(float(best_r[2]), 1.0)
	var all_r_rate: float = 100.0 * _won(relaxed) / maxf(float(relaxed.size()), 1.0)
	_row(["Relaxed, best strategy", "at least 90%", "%s %s" % [best_r[0], _rate(int(best_r[1]), int(best_r[2]))], "met" if best_r_rate >= 90.0 else "NOT MET"])
	_row(["Relaxed, the 16 together", "at least 80%", _rate(_won(relaxed), relaxed.size()), "met" if all_r_rate >= 80.0 else "NOT MET"])
	# Every card unlocked.
	for item: Array in [["Every card unlocked, Normal", "base_r0", "all_r0"], ["Every card unlocked, Relaxed", "base_r1", "all_r1"]]:
		var a: Array = _rates[item[1]]
		var b: Array = _rates[item[2]]
		if b.is_empty():
			continue
		var diff: float = 100.0 * _won(b) / b.size() - 100.0 * _won(a) / a.size()
		_row([item[0], "within 5 points of no unlocks", "%+.1f points (%s against %s)" % [diff, _pct(_won(b), b.size()), _pct(_won(a), a.size())], "met" if absf(diff) <= 5.0 else "NOT MET"])
	# The boss.
	var boss: Dictionary = _boss_pack_stats(base)
	var low: String = ""
	var high: String = ""
	var low_v: float = 1000.0
	var high_v: float = -1.0
	var failing: Array = []
	for id: String in boss.keys():
		var share: float = 100.0 * int(boss[id]["won"]) / maxf(float(boss[id]["started"]), 1.0)
		if share < low_v:
			low_v = share
			low = id
		if share > high_v:
			high_v = share
			high = id
		if share < 50.0 or share > 75.0:
			failing.append("%s %.1f%%" % [id, share])
	_row(["The boss, each band 6 pack", "50% to 75% of runs that start wave 18 win", "lowest %s %.1f%%, highest %s %.1f%%" % [low, low_v, high, high_v], "met" if failing.is_empty() else "NOT MET: " + ", ".join(PackedStringArray(failing))])
	# Fair maps.
	var overall: float = float(_won(base)) / maxf(float(base.size()), 1.0)
	var worst_name: String = ""
	var worst_ratio: float = 100.0
	var worst_se: float = 0.0
	var below: Array = []
	for kind: int in 3:
		var names: Array = []
		for r: Dictionary in base:
			var piece: String = String(r["stack"]).split("|")[kind]
			if not names.has(piece):
				names.append(piece)
		for piece: String in names:
			var list: Array = _where(base, func(r: Dictionary) -> bool: return String(r["stack"]).split("|")[kind] == piece)
			var ratio: float = float(_won(list)) / float(list.size()) / overall
			if ratio < worst_ratio:
				worst_ratio = ratio
				worst_name = piece
				worst_se = _segment_se(base, kind, piece) / overall
			if ratio < 0.75:
				below.append("%s %.2f" % [piece, ratio])
	_row(["Fair maps, each segment", "at least 0.75 times all runs", "lowest %s %.3f times, SE about %.2f" % [worst_name, worst_ratio, worst_se], "met" if below.is_empty() else ("NOT MET: under the bar by %.3f, %.1f SEs (%s)" % [0.75 - worst_ratio, (0.75 - worst_ratio) / maxf(worst_se, 0.001), ", ".join(PackedStringArray(below))])])
	var stacks: Array = []
	for r: Dictionary in base:
		if not stacks.has(r["stack"]):
			stacks.append(r["stack"])
	var stack_fail: Array = []
	var stack_worst: String = ""
	var stack_worst_v: float = -1.0
	for stack: String in stacks:
		var list2: Array = _where(base, func(r: Dictionary) -> bool: return r["stack"] == stack)
		if _distinct_seeds(list2) < 4:
			continue
		var share2: float = 100.0 * list2.filter(func(r: Dictionary) -> bool: return _lost_by(r, 6)).size() / list2.size()
		if share2 > stack_worst_v:
			stack_worst_v = share2
			stack_worst = stack
		if share2 > 10.0:
			stack_fail.append("%s %.1f%%" % [stack.replace("|", ", "), share2])
	var forced_rows: Array = _load_rows("force_stack_")
	var forced_fail: Array = []
	var forced_stacks: Array = []
	var forced_worst: String = ""
	var forced_worst_v: float = -1.0
	for r: Dictionary in forced_rows:
		if not forced_stacks.has(r["stack"]):
			forced_stacks.append(r["stack"])
	for stack: String in forced_stacks:
		var list3: Array = _where(forced_rows, func(r: Dictionary) -> bool: return r["stack"] == stack)
		var share4: float = 100.0 * list3.filter(func(r: Dictionary) -> bool: return _lost_by(r, 6)).size() / list3.size()
		if share4 > forced_worst_v:
			forced_worst_v = share4
			forced_worst = stack
		if share4 > 10.0:
			forced_fail.append("%s %.1f%%" % [stack.replace("|", ", "), share4])
	_row(["Fair maps, each stack of 4 or more seeds, natural seeds", "at most 10% lost by wave 6", "worst %s %.1f%%; %d stacks above 10%%" % [stack_worst.replace("|", ", "), stack_worst_v, stack_fail.size()],
		"met" if stack_fail.is_empty() else "NOT MET: " + "; ".join(PackedStringArray(stack_fail))])
	if not forced_stacks.is_empty():
		_row(["Fair maps, every stack forced onto seeds 1 to 200 (%d stacks, %d plays each)" % [forced_stacks.size(), _where(forced_rows, func(r: Dictionary) -> bool: return r["stack"] == forced_stacks[0]).size()], "at most 10% lost by wave 6", "worst %s %.1f%%; %d stacks above 10%%" % [forced_worst.replace("|", ", "), forced_worst_v, forced_fail.size()],
			"met" if forced_fail.is_empty() else "NOT MET: " + "; ".join(PackedStringArray(forced_fail))])
	# Fair packs.
	var pack_fail: Array = []
	var pack_worst: String = ""
	var pack_worst_v: float = -1.0
	for band: int in range(1, 6):
		for pack: Dictionary in _game.run.packs_of(band, &"", _tier):
			var info: Dictionary = _pack_stats(base, band, String(pack["id"]))
			var share3: float = 100.0 * int(info["lost"]) / maxf(float(info["reached"]), 1.0)
			if share3 > pack_worst_v:
				pack_worst_v = share3
				pack_worst = String(pack["id"])
			if share3 > 10.0:
				pack_fail.append("%s %.1f%%" % [pack["id"], share3])
	_row(["Fair packs, bands 1 to 5", "at most 10% of runs that reach a pack lost inside it", "worst %s %.1f%%" % [pack_worst, pack_worst_v], "met" if pack_fail.is_empty() else "NOT MET on natural seeds: " + ", ".join(PackedStringArray(pack_fail)) + " (forced: see Forced packs)"])
	# No card decides a run.
	for pool: String in ["base", "all"]:
		var rows: Array = _load_rows("cardvalue_%s_" % pool)
		if rows.is_empty():
			continue
		var gains: Dictionary = _card_gains(rows)
		var top_card: String = ""
		var top_gain: float = -100.0
		var over: Array = []
		var noise: Array = []
		var tower_top: String = ""
		var tower_gain: float = -100.0
		for id: String in gains.keys():
			var m: float = 100.0 * _mean(gains[id])
			var kind: String = String(_game.run.card(StringName(id)).get("kind", ""))
			if kind == "tower":
				if m > tower_gain:
					tower_gain = m
					tower_top = id
				continue
			if m > top_gain:
				top_gain = m
				top_card = id
			if m > 5.0:
				var text: String = "%s %+.1f (SE %.1f, %d offers)" % [id, m, 100.0 * _se(gains[id]), (gains[id] as Array).size()]
				if m - 5.0 <= 100.0 * _se(gains[id]):
					noise.append(text)
				else:
					over.append(text)
		_row(["No card decides a run (%s cards, %d drafts)" % ["base" if pool == "base" else "every", rows.size()], "no perk, gate, economy or risk card above +5 points",
			"best %s %+.1f (SE %.1f); best tower card %s %+.1f (reported)" % [top_card, top_gain, 100.0 * _se(gains[top_card]), tower_top, tower_gain], ("NOT MET: " + ", ".join(PackedStringArray(over))) if not over.is_empty() else (("met; over +5 by the number but within one SE, so noise: " + ", ".join(PackedStringArray(noise))) if not noise.is_empty() else "met")])
	# Risk cards.
	var risk_data: Dictionary = _read("risk_economy_wide.json")
	if not risk_data.is_empty():
		var summary: Dictionary = _risk_summary(risk_data["rows"])
		var lo: float = 100000.0
		var hi: float = 0.0
		var outside: Array = []
		for card: String in RISK_CARDS:
			if card == "gateless_night":
				continue
			lo = minf(lo, float(summary["per_life"][card]))
			hi = maxf(hi, float(summary["per_life"][card]))
			if (summary["outside"] as Array).has(card):
				outside.append(card)
		_row(["Risk cards trade fairly", "between half and twice the middle value", "middle %.1f, so %.1f to %.1f; held cards run %.0f to %.0f; Gateless Night %.0f (reported)" % [float(summary["middle"]), float(summary["middle"]) / 2.0, float(summary["middle"]) * 2.0, lo, hi, float(summary["per_life"]["gateless_night"])],
			"met" if outside.is_empty() else "NOT MET: " + ", ".join(PackedStringArray(outside))])
	# Length.
	var won: Array = _where(base, func(r: Dictionary) -> bool: return bool(r["won"]))
	var mins: Array = won.map(func(r: Dictionary) -> float: return _minutes(r))
	var quiet: Array = _where(won, func(r: Dictionary) -> bool: return int(r["early"]) == 0).map(func(r: Dictionary) -> float: return _minutes(r))
	_row(["Length", "won runs average about 12 to 16 minutes at 1x", "%.1f minutes (%d wins; %.1f with no early calls)" % [_mean(mins), won.size(), _mean(quiet)], "met" if _mean(mins) >= 12.0 and _mean(mins) <= 16.0 else "NOT MET"])
	# Same seed.
	var det: Dictionary = _read("det.json")
	var more: Dictionary = _read("det_more.json")
	var again: Dictionary = _read("det_again.json")
	if not det.is_empty():
		var bad: int = (det["failures"] as Array).size() + (more.get("failures", []) as Array).size()
		var hash_ok: bool = again.has("chain_hash") and int(again["chain_hash"]) == int(det["chain_hash"])
		_row(["Same seed, same run", "equal across a save and load in a wave or with a draft open", "%d runs and %d dailies checked, %d failures; second process chain hash %s" % [(det["rows"] as Array).size() + (more.get("rows", []) as Array).size(), (det["daily_rows"] as Array).size() + (more.get("daily_rows", []) as Array).size(), bad, "equal" if hash_ok else "NOT EQUAL"],
			"met" if bad == 0 and hash_ok else "NOT MET"])
	# The daily.
	var days: Array = _load_rows("daily_")
	if not days.is_empty():
		var named: int = 0
		var any_won: int = 0
		var longest: int = 0
		var run_lost: int = 0
		for d: Dictionary in days:
			var w: bool = false
			for p: Dictionary in d["plays"]:
				w = w or bool(p["won"])
			named += 1 if w else 0
			var anyw: bool = w or (d.has("extra") and bool(d["extra"]["won"]))
			any_won += 1 if anyw else 0
			run_lost = 0 if anyw else run_lost + 1
			longest = maxi(longest, run_lost)
		var dn: float = 100.0 * named / days.size()
		var da: float = 100.0 * any_won / days.size()
		_row(["The daily (RULES 15)", "at least 98%% of %d days won by a named or one of up to 400 random strategies; no two unwon in a row; named alone at least 60%%" % days.size(), "%s won by some strategy, %s by the named alone, longest run unwon %d" % [_rate(any_won, days.size()), _rate(named, days.size()), longest],
			"met" if da >= 98.0 and longest <= 1 and dn >= 60.0 else "NOT MET"])
	print()


## Phase C job lines: every stack that fits (top, a middle under it, a bottom under that), forced onto seeds 1 to 200, stopped at wave 6.
func _allstacks_b4() -> void:
	var data: RunData = _game.run
	for top: Dictionary in data.segments_of(&"top", _tier):
		for middle: Dictionary in data.segments_under(top["id"], _tier):
			for bottom: Dictionary in data.segments_under(middle["id"], _tier):
				var name: String = "%s_%s_%s" % [top["id"], middle["id"], bottom["id"]]
				for first: int in [1, 51, 101, 151]:
					print(_flag_line("mode=rates first=%d count=50 pool=base relaxed=0 stack=%s,%s,%s stop=6 out=OUTDIR/force_stack_%s_%d.json" % [first, top["id"], middle["id"], bottom["id"], name, first]))


## The standard error of a segment's win rate (a fraction), counting each seed as one sample (its plays on that map are 16 tries
## of one map): the spread of the seeds' mean win rates over the root of their number.
func _segment_se(rows: Array, kind: int, piece: String) -> float:
	var by_seed: Dictionary = {}
	for r: Dictionary in rows:
		if String(r["stack"]).split("|")[kind] != piece:
			continue
		var i: int = int(r["i"])
		if not by_seed.has(i):
			by_seed[i] = [0, 0]
		by_seed[i][1] = int(by_seed[i][1]) + 1
		by_seed[i][0] = int(by_seed[i][0]) + (1 if bool(r["won"]) else 0)
	var rates: Array = []
	for i: int in by_seed.keys():
		rates.append(float(by_seed[i][0]) / float(by_seed[i][1]))
	return _se(rates) if rates.size() > 1 else 0.0


## Whole runs on forced stacks: every stack with mid_eye forced onto seeds 1 to 200, full plays (full_stack_*.json).
func _fullstacks_b5() -> void:
	var rows: Array = _load_rows("full_stack_")
	if rows.is_empty():
		return
	var base: Array = _rates["base_r0"]
	var overall: float = float(_won(base)) / maxf(float(base.size()), 1.0)
	print("\n### Whole runs on forced stacks (Normal, base cards, seeds 1 to 200, 16 strategies, full plays; all runs on natural maps win %.1f%%)\n" % (100.0 * overall))
	_head(["Stack", "Plays", "Won", "Times all runs", "SE (seeds as samples)", "Lost by wave 6", "Lost at the boss"])
	var stacks: Array = []
	for r: Dictionary in rows:
		if not stacks.has(r["stack"]):
			stacks.append(r["stack"])
	stacks.sort()
	for stack: String in stacks:
		var list: Array = _where(rows, func(r: Dictionary) -> bool: return r["stack"] == stack)
		var by_seed: Dictionary = {}
		for r: Dictionary in list:
			var i: int = int(r["i"])
			if not by_seed.has(i):
				by_seed[i] = [0, 0]
			by_seed[i][1] = int(by_seed[i][1]) + 1
			by_seed[i][0] = int(by_seed[i][0]) + (1 if bool(r["won"]) else 0)
		var rates: Array = []
		for i: int in by_seed.keys():
			rates.append(float(by_seed[i][0]) / float(by_seed[i][1]))
		var rate: float = float(_won(list)) / list.size()
		_row([stack.replace("|", ", "), list.size(), _pct(_won(list), list.size()), "%.3f" % (rate / overall), "%.3f" % (_se(rates) / overall),
			_pct(list.filter(func(r: Dictionary) -> bool: return _lost_by(r, 6)).size(), list.size()),
			_pct(list.filter(func(r: Dictionary) -> bool: return not bool(r["won"]) and int(r["reached"]) >= 18).size(), list.size())])
	var total: int = rows.size()
	var won: int = _won(rows)
	# Every (stack, seed) is one sample: the 16 strategies' mean win rate on that map. The stacks are weighted equally, as a seed draws them.
	var cells: Dictionary = {}
	for r: Dictionary in rows:
		var key: String = "%s:%d" % [r["stack"], int(r["i"])]
		if not cells.has(key):
			cells[key] = [0, 0]
		cells[key][1] = int(cells[key][1]) + 1
		cells[key][0] = int(cells[key][0]) + (1 if bool(r["won"]) else 0)
	var cell_rates: Array = []
	for key: String in cells.keys():
		cell_rates.append(float(cells[key][0]) / float(cells[key][1]))
	print("\nAll %d stacks together: %d plays, %s won, %.3f times all runs (SE %.3f, each stack and seed one sample; the stacks are equally likely in a draw, so this is the segment's whole-run ratio).\n" % [stacks.size(), total, _pct(won, total), (float(won) / total) / overall, _se(cell_rates) / overall])


## The benchmark's largest wave: perf_*.json, perf2_*.json and perf3_*.json from run_perf.sh (the case keeps its higher peak).
func _perf_b5() -> void:
	var best_of: Dictionary = {}
	for prefix: String in ["perf_", "perf2_", "perf3_"]:
		for file: String in _files(prefix):
			var d: Dictionary = _read(file)
			if d.has("peak") and (not best_of.has(d["case"]) or int(d["peak"]) > int(best_of[d["case"]]["peak"])):
				best_of[d["case"]] = d
	var rows: Array = best_of.values()
	if rows.is_empty():
		return
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["peak"]) > int(b["peak"]))
	print("\n### The most crowded moment of each case (peak live creatures, tick times on this PC, headless)\n")
	print("Each case: a bot plays to the build phase before the target wave (runs: with the risk card taken for it), the wave starts, and the next wave is called early as soon as the game allows. Times are the median of 5 plays of that tail, in microseconds a tick; busy ticks have 50 or more creatures. Sorted by peak.\n")
	_head(["Case", "Wave", "Wave size", "Next wave", "Peak live creatures", "Ticks (busy)", "Mean us", "p99 us", "Busy mean us", "Busy p99 us", "Max us", "Seed / strategy"])
	for d: Dictionary in rows:
		var is_level: bool = d["kind"] == "level"
		_row([d["case"], int(d["wave"]), int(d.get("wave_size", 0)) if is_level else "-", int(d.get("next_wave_size", 0)) if is_level else "-", int(d["peak"]),
			"%d (%d)" % [int(d["ticks"]), int(d["busy_ticks"])], int(d["mean_us"]), int(d["p99_us"]), int(d["busy_mean_us"]), int(d["busy_p99_us"]), int(d["max_us"]),
			("%d" % int(d["seed"])) if is_level else ("%d, %s" % [int(d["seed"]), d["strategy"]])])
	print()


## E6.2: the anti-air check. Reads air/t<tier>_floor<P>_<first>.json (runs.gd mode=rates leaks=1 air_floor=P) from the folder given by dir=.
## Per tier and floor: win rate, how many attackers a run builds and the share that can hit flyers (Sling Post, Firework Tower, Moth Lantern),
## the share that cannot (Bramble Cottage, Snow Fort are the new ones), and in the lost runs the lives lost to flyers against walkers.
func _air_e6() -> void:
	var dir: DirAccess = DirAccess.open(_dir.path_join("air"))
	if dir == null:
		return
	var groups: Dictionary = {}
	for file: String in dir.get_files():
		if not file.ends_with(".json"):
			continue
		var key: String = file.get_slice("_floor", 0) + "|" + file.get_slice("_floor", 1).get_slice("_", 0)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_dir.path_join("air").path_join(file)))
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append_array((parsed as Dictionary).get("rows", []))
	var keys: Array = groups.keys()
	keys.sort()
	print("\n### Anti-air towers and the lives lost to flyers (Normal, base cards, the 16 strategies; floor 0 is the default bots)\n")
	_head(["Tier", "Floor", "Plays", "Won", "Attackers a run", "Anti-air share", "Bramble and Snow Fort share", "Lost runs", "Lives lost, flyers share of lost runs", "Lost runs where flyers took more lives than walkers"])
	for key: String in keys:
		var rows: Array = groups[key]
		var wins: int = 0
		var attackers: int = 0
		var air: int = 0
		var ground_new: int = 0
		var lost: int = 0
		var fly_lives: int = 0
		var walk_lives: int = 0
		var flyer_lost: int = 0
		for r: Dictionary in rows:
			if bool(r["won"]):
				wins += 1
			for tower: String in r["mix"].keys():
				if not _game.catalog.has_tower(StringName(tower)) or _game.catalog.tower(StringName(tower)).kind != &"attack":
					continue
				var n: int = int(r["mix"][tower])
				attackers += n
				if tower == "sling_post" or tower == "firework_tower" or tower == "moth_lantern":
					air += n
				elif tower == "bramble_cottage" or tower == "snow_fort":
					ground_new += n
			if not bool(r["won"]):
				lost += 1
				var f: int = 0
				var w: int = 0
				for type_key: String in r.get("leaks", {}).keys():
					if _game.catalog.enemy(StringName(type_key)).flying:
						f += int(r["leaks"][type_key])
					else:
						w += int(r["leaks"][type_key])
				fly_lives += f
				walk_lives += w
				if f > w:
					flyer_lost += 1
		_row([key.get_slice("|", 0).trim_prefix("t"), key.get_slice("|", 1), rows.size(), _rate(wins, rows.size()), "%.2f" % (float(attackers) / maxf(rows.size(), 1.0)),
			"%.3f" % (float(air) / maxf(attackers, 1.0)), "%.3f" % (float(ground_new) / maxf(attackers, 1.0)), lost, _pct(fly_lives, fly_lives + walk_lives), _rate(flyer_lost, lost)])
	print("\nWin rate by the anti-air share of the run's attackers (floor 0, all tiers in the folder):\n")
	_head(["Tier", "Anti-air share", "Plays", "Won"])
	for key: String in keys:
		if not key.ends_with("|0"):
			continue
		var bands: Dictionary = {}
		for r: Dictionary in groups[key]:
			var a: int = 0
			var t: int = 0
			for tower: String in r["mix"].keys():
				if _game.catalog.has_tower(StringName(tower)) and _game.catalog.tower(StringName(tower)).kind == &"attack":
					t += int(r["mix"][tower])
					if tower == "sling_post" or tower == "firework_tower" or tower == "moth_lantern":
						a += int(r["mix"][tower])
			var share: float = float(a) / maxf(t, 1.0)
			var band: String = "under 0.35" if share < 0.35 else ("0.35 to 0.45" if share < 0.45 else ("0.45 to 0.55" if share < 0.55 else ("0.55 to 0.65" if share < 0.65 else "0.65 and over")))
			if not bands.has(band):
				bands[band] = [0, 0]
			bands[band][0] += 1
			bands[band][1] += 1 if bool(r["won"]) else 0
		for band: String in ["under 0.35", "0.35 to 0.45", "0.45 to 0.55", "0.55 to 0.65", "0.65 and over"]:
			if bands.has(band):
				_row([key.get_slice("|", 0).trim_prefix("t"), band, bands[band][0], _rate(bands[band][1], bands[band][0])])
	print()
