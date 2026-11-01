# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## The run and daily runner (task B2). One job per process, so many can run side by side.
##
##   godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=50 pool=base relaxed=0 out=PATH
##   godot --headless --path . --script res://tools/balance/runs.gd -- mode=det first=1 count=50 out=PATH
##   godot --headless --path . --script res://tools/balance/runs.gd -- mode=daily from=0 count=400 out=PATH
##   godot --headless --path . --script res://tools/balance/runs.gd -- mode=search first=1 count=50 n=200 pool=base relaxed=0 out=PATH
##   godot --headless --path . --script res://tools/balance/runs.gd -- mode=risk first=1 count=20 strat=towers_wide out=PATH
##   godot --headless --path . --script res://tools/balance/runs.gd -- mode=static out=PATH
##
## mode=rates: every strategy (or strats=id,id) plays run seeds seed_of(first) to seed_of(first + count - 1).
##   pool=base is the pool with no unlocks, pool=all every card, pool=plus:id,id the base cards and those cards. relaxed=1 plays Relaxed.
##   pool=minus:id,id is the base cards without those (E5.2). bramble_fit=1 puts a Bramble Cottage on the spot with the most road in its own reach. bramble_cap=N builds at most N. E6.2: tweak=pack_count:PACK_ID;WAVE;ENEMY;N sets the count of a creature's group in a pack wave and tweak=pack_strength:PACK_ID;N sets a band 6 pack's boss wave strength (in memory); scarecrow_from=W builds no Scarecrow before W waves have started; air_floor=P keeps anti-air towers at P percent of a bot's attackers (E5.5: from tier 2 up the defaults are scarecrow_from=9 and air_floor=55, tiers 0 and 1 off; a value on the command line wins); leaks=1 (on rates) adds the lives lost by creature type to every row. towers=PATH and enemies=PATH play other stat files, and data=DIR plays another copy of the data folder (levels, stats, run files, segments and packs): what-ifs; the real data is not touched.
## mode=det: the same-seed checks (docs/balance/README.md "Runs"). days=N day_from=K play N dailies from day offset K
##   (default the first min(count, 50) days). A save that a load refuses is recorded in the row (wave_refused, draft_refused).
## mode=daily: day offsets from to from + count - 1, counted from 2026-10-25 (offset 0). Always Normal and every card.
## rates and daily also take boss=ironshell: only the seeds (days) whose run has that boss.
## mode=search: n random strategies (RunBot.random_strategy, seeded from the run seed) play each run seed.
##   list=3,17,40 searches only those seeds (run seed indexes) instead of first to first + count - 1.
## mode=daily also takes extra=N: a day no named strategy wins gets up to N random strategies, until one wins.
## mode=cardvalue: a strategy (strats=a,b alternate by seed) plays a run; before each pick the state is saved, and each of the
##   3 offered cards is taken in turn and the run played on to its end by the same strategy (pool=base or all).
## mode=deep: days=2026-11-11,2026-12-01 n=1000: n random strategies on each listed day (the days the daily run left unwon).
## mode=risk: snapshots of one strategy's run before each wave, then each risk card applied to that wave.
## mode=static: the stacks, the packs and the most creatures a pack wave spawns with each risk card.
## Any mode takes bakery_min=1 (a bot builds a Bakery that reaches only 1 spot; default 2).
## Any mode takes bakery_from=W (a bot builds no Bakery before W waves have started; B4 default 9, 0 is B2's rule),
##   perk_fit=0 (bots pick perks blindly, as in B2) and boss_aim=1 (attackers aim at Strong when the boss wave starts).
## mode=rates also takes stack=TOP,MIDDLE,BOTTOM (play every seed on that stack), pack=PACK_ID (every seed uses that pack
##   in its band) and stop=N (a play ends when N waves have started and none is on the map).
## Any mode takes tweak=strength_step:8,strength_start:100,start_gold:300,gates:1,tea_break:5 (RunData numbers and the lives of Tea Break, in memory only).
## Any mode takes tier=N (B6, 0 to 4): every run and daily is of that content tier (RULES 14.9, 15). The pool, the map, the packs and the bosses
##   are those of the tier and below. With tier 0 (the default) nothing changes, and the result has no "tier" key.
## Any mode takes fixture=1: the test catalog with the expansion towers and the creatures the sim engineer has, and run data with four content
##   tiers (tools/balance/fixtures.gd), because the real run data holds no tiers yet. The result then says "fixture": true.
## The result is one JSON object, written to `out` and printed after "RESULT ".

const RunBot: GDScript = preload("res://tools/balance/run_bot.gd")
const Fixtures: GDScript = preload("res://tools/balance/fixtures.gd")
const DAILY_FIRST: Dictionary = {"year": 2026, "month": 10, "day": 25, "hour": 0, "minute": 0, "second": 0}

var _args: Dictionary = {}
var _tier: int = 0                                # tier=N: the content tier of every run and daily (ARCHITECTURE 14.8)


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.split("=", true, 1)
		if parts.size() == 2:
			_args[parts[0]] = parts[1]
	var fixture: bool = String(_args.get("fixture", "0")) == "1"
	var game: GameData = Fixtures.game() if fixture else GameData.load_from(String(_args.get("data", "res://data")))
	_tier = int(_args.get("tier", "0"))
	if game == null:
		quit(2)
		return
	if _tier < 0 or (game.run != null and _tier > game.run.tiers.size()):
		printerr("tier=%d is outside 0 to %d" % [_tier, game.run.tiers.size()])
		quit(2)
		return
	if not game.problems.is_empty() or game.run == null:
		printerr("data problems: %s" % ", ".join(game.problems))
		quit(2)
		return
	if not _apply_files(game):
		return
	RunBot.set_bakery_min(int(_args.get("bakery_min", "2")))
	RunBot.set_options(int(_args.get("bakery_from", "9")), int(_args.get("boss_aim", "0")), int(_args.get("perk_fit", "1")))
	RunBot.set_bramble_fit(int(_args.get("bramble_fit", "0")))
	RunBot.set_bramble_cap(int(_args.get("bramble_cap", "0")))
	RunBot.habits(_tier, _args)
	var tweak: String = String(_args.get("tweak", ""))
	if tweak != "" and not _apply_tweak(game, tweak):
		return
	var started: int = Time.get_ticks_msec()
	var mode: String = String(_args.get("mode", "rates"))
	var first: int = int(_args.get("first", "1"))
	var count: int = int(_args.get("count", "50"))
	var result: Dictionary = {}
	if mode == "rates":
		result = _rates(game, first, count)
	elif mode == "det":
		result = _det(game, first, count)
	elif mode == "daily":
		result = _daily(game, int(_args.get("from", "0")), count)
	elif mode == "search":
		result = _search(game, first, count)
	elif mode == "risk":
		result = _risk(game, first, count)
	elif mode == "deep":
		result = _deep(game)
	elif mode == "cardvalue":
		result = _cardvalue(game, first, count)
	elif mode == "static":
		result = _static(game)
	else:
		printerr("unknown mode %s" % mode)
		quit(2)
		return
	if result.has("bad"):
		printerr(String(result["bad"]))
		quit(2)
		return
	result["mode"] = mode
	if _tier > 0:
		result["tier"] = _tier
	if fixture:
		result["fixture"] = true
	result["seconds"] = (Time.get_ticks_msec() - started) / 1000.0
	if tweak != "":
		result["tweak"] = tweak
	if RunBot.get_bakery_min() != 2:
		result["tweak"] = (String(result.get("tweak", "")) + " bakery_min:%d" % RunBot.get_bakery_min()).strip_edges()
	result["bots"] = {"bakery_from": RunBot.bakery_from, "boss_aim": RunBot.boss_aim, "perk_fit": RunBot.perk_fit}
	if RunBot.bramble_fit != 0:
		result["bots"]["bramble_fit"] = RunBot.bramble_fit
	if RunBot.bramble_cap != 0:
		result["bots"]["bramble_cap"] = RunBot.bramble_cap
	if RunBot.air_floor != 0 or _tier >= 2:
		result["bots"]["air_floor"] = RunBot.air_floor
	if RunBot.scarecrow_from != 0 or _tier >= 2:
		result["bots"]["scarecrow_from"] = RunBot.scarecrow_from
	for key: String in ["stack", "pack", "stop"]:
		if _args.has(key):
			result[key] = String(_args[key])
	var text: String = JSON.stringify(result)
	print("RESULT " + text.substr(0, 300))
	var out: String = String(_args.get("out", ""))
	if out != "":
		var file: FileAccess = FileAccess.open(out, FileAccess.WRITE)
		if file == null:
			printerr("cannot write %s" % out)
			quit(2)
			return
		file.store_string(text)
		file.close()
	quit(0)


## towers=PATH and enemies=PATH (E5.2): play other stat files than data/stats/towers.json and enemies.json, as a what-if. A missing or
## bad file stops the run with exit code 2. Nothing in data/ is touched. With neither argument this changes nothing.
func _apply_files(game: GameData) -> bool:
	var towers_path: String = String(_args.get("towers", ""))
	var enemies_path: String = String(_args.get("enemies", ""))
	if towers_path == "" and enemies_path == "":
		return true
	var towers: Variant = _read_json(towers_path if towers_path != "" else "res://data/stats/towers.json")
	var enemies: Variant = _read_json(enemies_path if enemies_path != "" else "res://data/stats/enemies.json")
	var rules: Variant = _read_json("res://data/stats/rules.json")
	if towers == null or enemies == null or rules == null:
		quit(2)
		return false
	var catalog: Catalog = Catalog.from_data(towers, enemies, rules)
	if catalog == null:
		printerr("stat files are refused: %s" % ", ".join(Catalog.check(towers, enemies, rules)))
		quit(2)
		return false
	game.catalog = catalog
	return true


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		printerr("cannot read %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		printerr("%s is not a JSON object" % path)
		return null
	return parsed


## The i-th run seed: i times 2654435761, modulo 2^32. A spread of seeds like the ones a phone draws.
static func seed_of(i: int) -> int:
	return (i * 2654435761) % 4294967296


## The day key `offset` days after 2026-10-25 (offset 0 is the day after this report is dated).
static func day_of(offset: int) -> String:
	var unix: int = Time.get_unix_time_from_datetime_dict(DAILY_FIRST) + offset * 86400
	return RunSeeds.day_key(Time.get_date_dict_from_unix_time(unix))


func _apply_tweak(game: GameData, tweak: String) -> bool:
	for item: String in tweak.split(","):
		var parts: PackedStringArray = item.split(":")
		if parts.size() != 2:
			printerr("bad tweak %s" % item)
			quit(2)
			return false
		var value: int = int(parts[1])
		match parts[0]:
			"strength_step":
				game.run.strength_step = value
			"strength_start":
				game.run.strength_start = value
			"start_gold":
				game.run.start_gold = value
			"gates":
				game.run.gates = value
			"pack_strength":
				# E6.2. pack_strength:PACK_ID;N sets the strength of a band 6 pack's boss wave (what-if only).
				var bits: PackedStringArray = parts[1].split(";")
				for pack: Dictionary in game.run.packs:
					if String(pack["id"]) == bits[0] and bits.size() == 2:
						pack["waves"][2]["strength"] = int(bits[1])
			"pack_count":
				# E6.2. pack_count:PACK_ID;WAVE;ENEMY;N sets the count of one creature's group in a wave (1 to 3) of a pack (what-if only).
				var cut: PackedStringArray = parts[1].split(";")
				for pack: Dictionary in game.run.packs:
					if String(pack["id"]) == cut[0] and cut.size() == 4:
						for group: Dictionary in pack["waves"][int(cut[1]) - 1]["groups"]:
							if String(group["enemy"]) == cut[2]:
								group["count"] = int(cut[3])
			"tea_break":
				# The lives Tea Break gives, in the held card data (what-if only).
				for card: Dictionary in game.run.cards:
					if card["id"] == &"tea_break":
						card["effects"][0]["amount"] = value
			_:
				printerr("unknown tweak %s" % parts[0])
				quit(2)
				return false
	return true


## pool=base (no unlocks), pool=all (every card), pool=plus:id,id (the base cards and those unlock cards: what-ifs that find
## which unlock cards cost the bots win rate) or pool=minus:id,id (the base cards without those, E5.2).
func _pool(game: GameData, which: String) -> Array[StringName]:
	if which == "all":
		return game.run.card_ids(_tier)
	var out: Array[StringName] = game.run.pool({}, _tier)
	if which.begins_with("plus:"):
		for id: String in which.trim_prefix("plus:").split(",", false):
			if not game.run.card(StringName(id)).is_empty() and not out.has(StringName(id)):
				out.append(StringName(id))
	if which.begins_with("minus:"):
		# E5.2: the base cards without these (what-if: does one card, such as the Bramble Cottage's, cost the bots win rate).
		for id: String in which.trim_prefix("minus:").split(",", false):
			out.erase(StringName(id))
	return out


func _stack(game: GameData, run_seed: int) -> Dictionary:
	var plan: Dictionary = MapAssembler.plan(run_seed, game.run, _tier)
	var packs: Array[String] = []
	for id: StringName in plan["packs"]:
		packs.append(String(id))
	return {"top": String(plan["top"]), "middle": String(plan["middle"]), "bottom": String(plan["bottom"]),
		"boss": String(plan["boss"]), "packs": packs}


func _card_ids(game: GameData) -> Array:
	var out: Array = []
	for id: StringName in game.run.card_ids(_tier):
		out.append(String(id))
	return out


# Win rates.

func _rates(game: GameData, first: int, count: int) -> Dictionary:
	var relaxed: bool = String(_args.get("relaxed", "0")) == "1"
	var which: String = String(_args.get("pool", "base"))
	var pool: Array[StringName] = _pool(game, which)
	var chosen: Array[Dictionary] = RunBot.strategies()
	var wanted: String = String(_args.get("strats", "all"))
	if wanted != "all":
		var list: PackedStringArray = wanted.split(",")
		chosen = []
		for id: String in list:
			var strat: Dictionary = RunBot.strategy(id)
			if strat.is_empty():
				return {"bad": "unknown strategy %s" % id}
			chosen.append(strat)
	var cards: Array = _card_ids(game)
	var only_boss: String = String(_args.get("boss", ""))
	var opts: Dictionary = {"tier": _tier}
	if String(_args.get("leaks", "0")) == "1":
		opts["leaks"] = true
	var forced_stack: PackedStringArray = String(_args.get("stack", "")).split(",", false)
	if forced_stack.size() == 3:
		opts["stack"] = Array(forced_stack)
	elif forced_stack.size() != 0:
		return {"bad": "stack= needs TOP,MIDDLE,BOTTOM"}
	var forced_pack: String = String(_args.get("pack", ""))
	var forced_boss: String = ""
	if forced_pack != "":
		opts["pack"] = forced_pack
		var known: bool = false
		for item: Dictionary in game.run.packs:
			if String(item["id"]) == forced_pack:
				known = true
				if int(item["band"]) == RunData.BANDS:
					forced_boss = String(item["boss"])
		if not known:
			return {"bad": "unknown pack %s" % forced_pack}
	if int(_args.get("stop", "0")) > 0:
		opts["stop_after"] = int(_args["stop"])
	var rows: Array = []
	for i: int in range(first, first + count):
		var run_seed: int = seed_of(i)
		var stack: Dictionary = _stack(game, run_seed)
		if only_boss != "" and stack["boss"] != only_boss:
			continue
		for strat: Dictionary in chosen:
			var row: Dictionary = RunBot.play(game, run_seed, "", relaxed, pool, strat, opts)
			if row.has("bad"):
				return row
			row["i"] = i
			if forced_stack.size() == 3:
				row["stack"] = "|".join(forced_stack)
			else:
				row["stack"] = "%s|%s|%s" % [stack["top"], stack["middle"], stack["bottom"]]
			row["boss"] = forced_boss if forced_boss != "" else stack["boss"]
			if forced_pack != "":
				row["pack"] = forced_pack
			_pack_cards(row, cards)
			rows.append(row)
	return {"relaxed": relaxed, "pool": which, "pool_size": pool.size(), "cards": cards, "first": first, "count": count, "rows": rows}


## Card ids become their index in cards.json order, so a file stays small.
func _pack_cards(row: Dictionary, cards: Array) -> void:
	var picks: Array = []
	for id: Variant in row["picks"]:
		picks.append(cards.find(String(id)))
	row["picks"] = picks
	var offered: Array = []
	for list: Array in row["offered"]:
		var coded: Array = []
		for id: Variant in list:
			coded.append(cards.find(String(id)))
		offered.append(coded)
	row["offered"] = offered
	row.erase("battle_hash")
	row.erase("run_hash")
	row.erase("restores")
	row.erase("offers_equal")


# The same seed plays the same.

func _det(game: GameData, first: int, count: int) -> Dictionary:
	var strats: Array[Dictionary] = RunBot.strategies()
	var all_cards: Array[StringName] = game.run.card_ids(_tier)
	var base_cards: Array[StringName] = game.run.pool({}, _tier)
	var rows: Array = []
	var chain: String = ""
	var failures: Array = []
	for i: int in range(first, first + count):
		var run_seed: int = seed_of(i)
		var k: int = i - first
		var strat: Dictionary = strats[k % strats.size()]
		var relaxed: bool = k % 4 >= 2
		var pool: Array[StringName] = all_cards if k % 2 == 0 else base_cards
		var row: Dictionary = {"i": i, "seed": run_seed, "strategy": String(strat["id"]), "relaxed": relaxed, "pool": "all" if k % 2 == 0 else "base"}
		# The map, the waves and the picks of the seed, built twice.
		var plan_a: Dictionary = MapAssembler.plan(run_seed, game.run, _tier)
		var plan_b: Dictionary = MapAssembler.plan(run_seed, game.run, _tier)
		var level_a: LevelData = MapAssembler.assemble(run_seed, game.run, game.catalog, _tier)
		var level_b: LevelData = MapAssembler.assemble(run_seed, game.run, game.catalog, _tier)
		var text_a: String = JSON.stringify(level_a.to_data())
		row["map_equal"] = JSON.stringify(plan_a) == JSON.stringify(plan_b) and text_a == JSON.stringify(level_b.to_data())
		row["map_hash"] = text_a.hash()
		# The same play twice, then with a save and load in the middle of a wave, then with a draft open.
		var a: Dictionary = RunBot.play(game, run_seed, "", relaxed, pool, strat, {"tier": _tier})
		var b: Dictionary = RunBot.play(game, run_seed, "", relaxed, pool, strat, {"tier": _tier})
		var wave_at: int = clampi(2 + k % 12, 0, int(a["reached"]) - 1)
		var c: Dictionary = RunBot.play(game, run_seed, "", relaxed, pool, strat, {"tier": _tier, "restore_wave": [wave_at, 60 + 40 * (k % 5)]})
		var draft_at: int = clampi(1 + k % 12, 0, maxi(a["picks"].size() - 1, 0))
		var d: Dictionary = RunBot.play(game, run_seed, "", relaxed, pool, strat, {"tier": _tier, "restore_draft": draft_at})
		row["again_equal"] = _same(a, b)
		row["wave_restore_equal"] = _same(a, c)
		row["wave_restored"] = int(c.get("restores", 0)) == 1
		row["draft_restore_equal"] = _same(a, d) and bool(d.get("offers_equal", false))
		row["draft_restored"] = int(d.get("restores", 0)) == 1
		row["wave_refused"] = "%s at %s" % [c["refused"], c["at"]] if c.has("refused") else ""
		row["draft_refused"] = "%s at %s" % [d["refused"], d["at"]] if d.has("refused") else ""
		row["won"] = a["won"]
		row["cleared"] = a["cleared"]
		row["offers_hash"] = JSON.stringify(a["offered"]).hash()
		row["battle_hash"] = a["battle_hash"]
		row["run_hash"] = a["run_hash"]
		if not (row["map_equal"] and row["again_equal"] and row["wave_restore_equal"] and row["draft_restore_equal"]):
			failures.append(i)
		chain += "%d:%d:%d:%d;" % [row["map_hash"], row["offers_hash"], row["battle_hash"], row["run_hash"]]
		rows.append(row)
	# Dailies: the first days after the report, played twice and with the same two saves.
	var daily_rows: Array = []
	var day_from: int = int(_args.get("day_from", "0"))
	var day_count: int = int(_args.get("days", str(mini(count, 50))))
	for n: int in range(day_from, day_from + day_count):
		var day: String = day_of(n)
		var daily_seed: int = RunSeeds.daily_seed(day)
		var strat: Dictionary = strats[n % strats.size()]
		var a: Dictionary = RunBot.play(game, daily_seed, day, false, all_cards, strat, {"tier": _tier})
		var b: Dictionary = RunBot.play(game, daily_seed, day, false, all_cards, strat, {"tier": _tier})
		var c: Dictionary = RunBot.play(game, daily_seed, day, false, all_cards, strat, {"tier": _tier, "restore_wave": [clampi(3 + n % 10, 0, int(a["reached"]) - 1), 100]})
		var d: Dictionary = RunBot.play(game, daily_seed, day, false, all_cards, strat, {"tier": _tier, "restore_draft": clampi(2 + n % 10, 0, maxi(a["picks"].size() - 1, 0))})
		var drow: Dictionary = {"day": day, "seed": daily_seed, "strategy": String(strat["id"]),
			"again_equal": _same(a, b), "wave_restore_equal": _same(a, c), "wave_restored": int(c.get("restores", 0)) == 1,
			"draft_restore_equal": _same(a, d) and bool(d.get("offers_equal", false)), "draft_restored": int(d.get("restores", 0)) == 1,
			"wave_refused": "%s at %s" % [c["refused"], c["at"]] if c.has("refused") else "",
			"draft_refused": "%s at %s" % [d["refused"], d["at"]] if d.has("refused") else "",
			"won": a["won"], "battle_hash": a["battle_hash"], "run_hash": a["run_hash"]}
		if not (drow["again_equal"] and drow["wave_restore_equal"] and drow["draft_restore_equal"]):
			failures.append(day)
		chain += "%s:%d:%d;" % [day, drow["battle_hash"], drow["run_hash"]]
		daily_rows.append(drow)
	return {"first": first, "count": count, "rows": rows, "daily_rows": daily_rows, "failures": failures, "chain_hash": chain.hash()}


## Two plays are the same when every field matches, except the count of restores they made.
func _same(a: Dictionary, b: Dictionary) -> bool:
	if a.has("bad") or b.has("bad") or a.has("restore_failed") or b.has("restore_failed"):
		return false
	var x: Dictionary = a.duplicate()
	var y: Dictionary = b.duplicate()
	for key: String in ["restores", "offers_equal"]:
		x.erase(key)
		y.erase(key)
	return JSON.stringify(x) == JSON.stringify(y)


# The daily.

func _daily(game: GameData, from: int, count: int) -> Dictionary:
	var extra: int = int(_args.get("extra", "0"))
	var cards: Array = _card_ids(game)
	var pool: Array[StringName] = game.run.card_ids(_tier)
	var chosen: Array[Dictionary] = RunBot.strategies()
	var rows: Array = []
	for n: int in range(from, from + count):
		var day: String = day_of(n)
		var daily_seed: int = RunSeeds.daily_seed(day)
		var stack: Dictionary = _stack(game, daily_seed)
		if String(_args.get("boss", "")) != "" and stack["boss"] != String(_args.get("boss", "")):
			continue
		var plays: Array = []
		for strat: Dictionary in chosen:
			var row: Dictionary = RunBot.play(game, daily_seed, day, false, pool, strat, {"tier": _tier})
			if row.has("bad"):
				return row
			_pack_cards(row, cards)
			plays.append({"strategy": row["strategy"], "won": row["won"], "lives": row["lives"], "cleared": row["cleared"], "reached": row["reached"],
				"ticks": row["ticks"], "builds": row["builds"], "risks": row["risks"], "early": row["early"], "peak": row["peak"]})
		var won_any: bool = false
		for play: Dictionary in plays:
			won_any = won_any or bool(play["won"])
		var line: Dictionary = {"n": n, "day": day, "seed": daily_seed, "stack": "%s|%s|%s" % [stack["top"], stack["middle"], stack["bottom"]],
			"boss": stack["boss"], "plays": plays}
		if not won_any and extra > 0:
			line["extra"] = _extra(game, daily_seed, day, false, pool, extra)
		rows.append(line)
	return {"from": from, "count": count, "extra": extra, "rows": rows}


## Random strategies on one seed, until one wins or n are tried. {"tried", "won", "lives", "cleared", "strategy"}
## (the winner, or the one that cleared the most waves).
func _extra(game: GameData, run_seed: int, day: String, relaxed: bool, pool: Array[StringName], n: int) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = ("%d:search" % run_seed).hash()
	var best: Dictionary = {}
	var best_strat: Dictionary = {}
	var tried: int = 0
	for k: int in n:
		var strat: Dictionary = RunBot.random_strategy(rng, "x%d" % k)
		var row: Dictionary = RunBot.play(game, run_seed, day, relaxed, pool, strat, {"tier": _tier})
		tried += 1
		if best.is_empty() or _better(row, best):
			best = row
			best_strat = strat
		if bool(row["won"]):
			break
	return {"tried": tried, "won": best["won"], "lives": best["lives"], "cleared": best["cleared"], "strategy": best_strat}


func _better(a: Dictionary, b: Dictionary) -> bool:
	if bool(a["won"]) != bool(b["won"]):
		return bool(a["won"])
	if bool(a["won"]):
		return int(a["lives"]) > int(b["lives"])
	return int(a["cleared"]) > int(b["cleared"]) or (int(a["cleared"]) == int(b["cleared"]) and int(a["lives"]) > int(b["lives"]))


# A search on run seeds: n random strategies each.

func _search(game: GameData, first: int, count: int) -> Dictionary:
	var relaxed: bool = String(_args.get("relaxed", "0")) == "1"
	var which: String = String(_args.get("pool", "base"))
	var pool: Array[StringName] = _pool(game, which)
	var n: int = int(_args.get("n", "200"))
	var rows: Array = []
	var seeds: Array[int] = []
	if _args.has("list"):
		for item: String in String(_args["list"]).split(",", false):
			seeds.append(int(item))
	else:
		for i: int in range(first, first + count):
			seeds.append(i)
	for i: int in seeds:
		var run_seed: int = seed_of(i)
		var stack: Dictionary = _stack(game, run_seed)
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = ("%d:search" % run_seed).hash()
		var wins: int = 0
		var best: Dictionary = {}
		var best_strat: Dictionary = {}
		var lives_sum: int = 0
		for k: int in n:
			var strat: Dictionary = RunBot.random_strategy(rng, "x%d" % k)
			var row: Dictionary = RunBot.play(game, run_seed, "", relaxed, pool, strat, {"tier": _tier})
			if row.has("bad"):
				return row
			if bool(row["won"]):
				wins += 1
				lives_sum += int(row["lives"])
			if best.is_empty() or _better(row, best):
				best = row
				best_strat = strat
		rows.append({"i": i, "seed": run_seed, "stack": "%s|%s|%s" % [stack["top"], stack["middle"], stack["bottom"]], "boss": stack["boss"],
			"tried": n, "wins": wins, "best_won": best["won"], "best_lives": best["lives"], "best_cleared": best["cleared"], "best_ticks": best["ticks"],
			"best_strategy": best_strat})
	return {"relaxed": relaxed, "pool": which, "n": n, "first": first, "count": count, "rows": rows}


# Days nobody won.

func _deep(game: GameData) -> Dictionary:
	var pool: Array[StringName] = game.run.card_ids(_tier)
	var n: int = int(_args.get("n", "1000"))
	var rows: Array = []
	for day: String in String(_args.get("days", "")).split(","):
		if not RunSeeds.is_day_key(day):
			return {"bad": "not a day key: %s" % day}
		var daily_seed: int = RunSeeds.daily_seed(day)
		var stack: Dictionary = _stack(game, daily_seed)
		var found: Dictionary = _extra(game, daily_seed, day, false, pool, n)
		rows.append({"day": day, "seed": daily_seed, "stack": "%s|%s|%s" % [stack["top"], stack["middle"], stack["bottom"]], "boss": stack["boss"], "found": found})
	return {"n": n, "rows": rows}


# What each card is worth.

func _cardvalue(game: GameData, first: int, count: int) -> Dictionary:
	var which: String = String(_args.get("pool", "base"))
	var pool: Array[StringName] = _pool(game, which)
	var names: PackedStringArray = String(_args.get("strats", "random_wide,random_tall")).split(",")
	var rows: Array = []
	for i: int in range(first, first + count):
		var run_seed: int = seed_of(i)
		var strat: Dictionary = RunBot.strategy(names[(i - first) % names.size()])
		if strat.is_empty():
			return {"bad": "unknown strategy"}
		var base: Dictionary = RunBot.play(game, run_seed, "", false, pool, strat, {"tier": _tier, "draft_snapshots": true})
		if base.has("bad"):
			return base
		for snap: Dictionary in base["draft_snaps"]:
			var outcomes: Array = []
			for card: StringName in snap["offers"]:
				var res: Dictionary = RunBot.play(game, run_seed, "", false, pool, strat, {"tier": _tier, "resume": snap, "force": card})
				if res.has("bad"):
					return res
				outcomes.append({"card": String(card), "won": res["won"], "lives": res["lives"], "cleared": res["cleared"]})
			rows.append({"i": i, "strategy": String(strat["id"]), "k": snap["k"], "outcomes": outcomes})
	return {"pool": which, "first": first, "count": count, "rows": rows}


# Peak creatures with each risk card.

func _risk(game: GameData, first: int, count: int) -> Dictionary:
	var strat: Dictionary = RunBot.strategy(String(_args.get("strat", "towers_wide")))
	if strat.is_empty():
		return {"bad": "unknown strategy"}
	var pool: Array[StringName] = game.run.card_ids(_tier)
	var risk_cards: Array[Dictionary] = []
	for card: Dictionary in game.run.cards:
		if card["kind"] == &"risk":
			risk_cards.append(card)
	var rows: Array = []
	var bases: Array = []
	for i: int in range(first, first + count):
		var run_seed: int = seed_of(i)
		var base: Dictionary = RunBot.play(game, run_seed, "", false, pool, strat, {"tier": _tier, "snapshots": true})
		if base.has("bad"):
			return base
		bases.append({"i": i, "seed": run_seed, "won": base["won"], "cleared": base["cleared"], "lives": base["lives"]})
		for snap: Dictionary in base["snapshots"]:
			var wave: int = int(snap["wave"])
			# A risk card can change waves 2 to 17 (14.4): the draft after wave 1 is the first.
			if wave < 1 or wave > 16:
				continue
			var kinds: Array = [null]
			kinds.append_array(risk_cards)
			for card: Variant in kinds:
				var line: Dictionary = _branch(game, snap, wave, card)
				line["i"] = i
				line["wave"] = wave
				line["card"] = "none" if card == null else String((card as Dictionary)["id"])
				rows.append(line)
	return {"strategy": String(strat["id"]), "first": first, "count": count, "bases": bases, "rows": rows}


## One wave from a snapshot: optionally a risk card on it, then step until the wave is over.
func _branch(game: GameData, snap: Dictionary, wave: int, card: Variant) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(snap["battle"]))
	var b: Battle = Battle.from_data(parsed, game.catalog)
	if b == null:
		return {"bad_branch": true}
	b.record_events = false
	if card != null:
		var effects: Array[Dictionary] = []
		effects.append_array((card as Dictionary)["effects"])
		if b.add_effects(effects, true) != Battle.DONE:
			return {"bad_branch": true}
	var lives_before: int = b.lives
	var gold_before: int = b.gold
	var peak: int = 0
	if b.start_next_wave() != Battle.DONE:
		return {"bad_branch": true}
	var from_tick: int = b.tick
	while b.phase == Battle.Phase.WAVE and b.tick - from_tick < 12000:
		b.step()
		peak = maxi(peak, b.enemies.size())
	return {"peak": peak, "lives_lost": lives_before - b.lives, "gold_gain": b.gold - gold_before, "ticks": b.tick - from_tick,
		"lost": b.phase == Battle.Phase.LOST}


# Maps and packs.

func _static(game: GameData) -> Dictionary:
	var data: RunData = game.run
	var risk: Array[Dictionary] = []
	for card: Dictionary in data.cards:
		if card["kind"] == &"risk":
			risk.append(card)
	var spawn: Array = []
	for pack: Dictionary in data.packs:
		if int(pack["tier"]) > _tier:
			continue
		for w: int in 3:
			var groups: Array = pack["waves"][w]["groups"]
			var line: Dictionary = {"pack": String(pack["id"]), "band": pack["band"], "boss": String(pack["boss"]), "wave": (int(pack["band"]) - 1) * 3 + w + 1,
				"none": RunPacks.spawn_total(groups, game.catalog, [])}
			for card: Dictionary in risk:
				var effects: Array[Dictionary] = []
				effects.append_array(card["effects"])
				line[String(card["id"])] = RunPacks.spawn_total(groups, game.catalog, effects)
			spawn.append(line)
	# Every stack that fits, with the chance a seed picks it: tops evenly, then the middles that fit, then the bottoms.
	var stacks: Array = []
	var tops: Array[Dictionary] = data.segments_of(&"top", _tier)
	var first_packs: Array[StringName] = []
	for band: int in range(1, RunData.BANDS + 1):
		first_packs.append(data.packs_of(band, data.boss_ids(_tier)[0] if band == RunData.BANDS else &"", _tier)[0]["id"])
	for top: Dictionary in tops:
		var middles: Array[Dictionary] = data.segments_under(top["id"], _tier)
		for middle: Dictionary in middles:
			var bottoms: Array[Dictionary] = data.segments_under(middle["id"], _tier)
			for bottom: Dictionary in bottoms:
				var level: LevelData = MapAssembler.build(data, game.catalog, top["id"], middle["id"], bottom["id"], first_packs)
				var chance: float = 1.0 / tops.size() / middles.size() / bottoms.size()
				stacks.append({"top": String(top["id"]), "middle": String(middle["id"]), "bottom": String(bottom["id"]),
					"spots": level.spots.size() if level != null else -1, "sockets": level.sockets.size() if level != null else -1,
					"entrances": level.entrances.size() if level != null else -1, "chance": chance})
	var packs_per_band: Array = []
	for band: int in range(1, RunData.BANDS + 1):
		packs_per_band.append(data.packs_of(band, &"", _tier).size())
	return {"spawn": spawn, "stacks": stacks, "packs_per_band": packs_per_band, "bosses": _names(data.boss_ids(_tier))}


func _names(ids: Array[StringName]) -> Array:
	var out: Array = []
	for id: StringName in ids:
		out.append(String(id))
	return out
