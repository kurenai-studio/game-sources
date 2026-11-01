# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## The balance runner. One level and one job per run, so many can run side by side.
##
##   godot --headless --path . --script res://tools/balance/run.gd -- mode=spread level=r1_l1 seed=101 n=300 out=PATH
##   godot --headless --path . --script X02 evals=3000 only=any out=PATH
##   godot --headless --path . --script res://tools/balance/run.gd -- mode=det level=r1_l1 seed=303 out=PATH
##   godot --headless --path . --script res://tools/balance/run.gd -- mode=recipes level=r1_l1 out=PATH
##   godot --headless --path . --script res://tools/balance/run.gd -- mode=plain level=r2_l1 out=PATH
##   godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r2_l1 seed=7 evals=2500 only=solo:sling_post out=PATH
##   godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r2_l1 twist=1 seed=7 evals=1500 out=PATH
##
## mode=spread: n random strategies in each style (casual, typical, skilled), each played on
##   Normal and on Relaxed. Reports win, two star and three star rates.
## mode=spread also takes style=guided: only the guided style (every spot, both kinds, all tier 2, random places and gate).
## mode=search: a seeded search for the best strategy, from random starts and small edits
##   (docs/balance/README.md). `only` is `any` or a comma list of tower ids the strategy may use.
## mode=recipes: a few plain recipes a new player might follow (no seed; nothing is random),
##   each played on Normal and Relaxed with no gate and with a gate on every socket.
## mode=plain: the plain mixed recipe of RULES 12.6 (Bot.plain_recipe), played on Normal and on Relaxed once
##   for every gate placement that seals no entrance, with the wave sizes of the level. compare_old=1 also plays
##   the old region 1 recipe ("sling, catapult, alternating, road order, tier 2") and lists any difference.
## mode=det: the same strategies played twice, played again with a save and load in the middle
##   of a wave, and the same search run twice, must all match.
## mode=need: no play at all. Which attacking towers the "no super tower" check must search on this level (RULES 12.6):
##   the flyer cost and walker cost in the wave data, and for each attacking tower the reason to skip it, if any. The tower
##   a star 3 ban names is skipped, and `all_three_only` is the `only=` value of the "All three stars" search (`any`, or
##   the towers the ban leaves).
## mode=replay from=FILE,FILE pick=best_win|three_star_best|top|all [max_tier=N]: plays strategies saved in search results (or
##   from=plain, the plain recipe at every gate placement) again, on the level as it is now, so it can be used
##   with level_file=, towers=, enemies=, stat=, tweak= and twist=1 as a what-if. Each row has the saved result and
##   the new result, lives lost by creature type and how far the flying bosses got (relaxed=1 plays Relaxed).
## mode=search `only` also takes solo:ID, one attacking tower plus every support tower the level offers
##   (the "no super tower" search of RULES 12.6).
## Any mode takes twist=1: the level is played with its Twist (ARCHITECTURE 2.8), a banned tower is not offered,
##   and a win is all that counts (Twists have no stars).
## mode=search also takes stop_dry=N: the search stops when N builds are tried and none has won (RULES 12.6: if neither
##   of the two searches of a tower has won a game after 2500 builds, both may stop there). The result says `stopped_dry`.
## mode=plain also takes max_tier=N (1 to 3): no tower goes above that tier (the report's tier 2 variant on 3-4 and 3-5).
## mode=search also takes early=off: no strategy calls a wave early (the star 3 of 1-6 is then out of reach).
## Any mode also takes level_file=PATH (a level JSON file played in place of the level named by `level`),
##   towers=PATH and enemies=PATH (stat files played in place of data/stats/towers.json and enemies.json).
##   Paths are res:// or plain file paths. The usual checks still apply. Data files are never touched.
## Any mode also takes stat=pumpkin_catapult.splash:+25 (a what-if on tower numbers; see _apply_stat).
## Any mode also takes tweak=gold:300,count_pct:120 (a what-if; see _apply_tweak).
## Any mode takes fixture=1 (B6): the game is the test catalog with the four expansion towers and the creatures the sim engineer has,
##   plus the fixture levels r5_fx1, r6_fx1, r7_fx1, r8_fx1 and r8_fx2 (tools/balance/fixtures.gd), one for each map feature and one with
##   all four. The result then says "fixture": true. Without it nothing changes.
## The result is one JSON object, written to `out` when given and always printed after "RESULT ".
## Every random draw comes from a generator seeded with `seed` plus a fixed offset, so the same
## command line always gives the same output.

const Bot: GDScript = preload("res://tools/balance/bot.gd")
const Fixtures: GDScript = preload("res://tools/balance/fixtures.gd")

var _args: Dictionary = {}
var _waves: int = 0


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.split("=", true, 1)
		if parts.size() == 2:
			_args[parts[0]] = parts[1]
	var fixture: bool = String(_args.get("fixture", "0")) == "1"
	var game: GameData = Fixtures.game() if fixture else GameData.load_from("res://data")
	if game == null:
		quit(2)
		return
	if not game.problems.is_empty():
		printerr("data problems: %s" % ", ".join(game.problems))
		quit(2)
		return
	var level_id: StringName = StringName(String(_args.get("level", "r1_l1")))
	if not game.levels.has(level_id):
		printerr("unknown level %s" % level_id)
		quit(2)
		return
	if not _apply_files(game, level_id):
		return
	var stat: String = String(_args.get("stat", ""))
	if stat != "" and not _apply_stat(game, level_id, stat):
		return
	var tweak: String = String(_args.get("tweak", ""))
	if tweak != "" and not _apply_tweak(game, level_id, tweak):
		return
	var ctx: Dictionary = Bot.context(game, level_id, String(_args.get("twist", "0")) == "1")
	if ctx.has("bad"):
		printerr(String(ctx["bad"]))
		quit(2)
		return
	_waves = ctx["level"].waves.size()
	var seed_value: int = int(_args.get("seed", "1"))
	var mode: String = String(_args.get("mode", "spread"))
	var started: int = Time.get_ticks_msec()
	var result: Dictionary = {}
	if mode == "spread":
		result = _spread(ctx, seed_value, int(_args.get("n", "200")))
	elif mode == "search":
		result = _search(ctx, seed_value, int(_args.get("evals", "2000")), _allowed(ctx, String(_args.get("only", "any"))))
		result["only"] = String(_args.get("only", "any"))
	elif mode == "det":
		result = _det(ctx, seed_value)
	elif mode == "exhaust":
		result = _exhaust(ctx, _allowed(ctx, String(_args.get("only", "any"))), int(_args.get("max_towers", "2")),
			int(_args.get("shard", "0")), int(_args.get("shards", "1")))
		result["only"] = String(_args.get("only", "any"))
	elif mode == "recipes":
		result = _recipes(ctx)
	elif mode == "plain":
		result = _plain(ctx)
	elif mode == "need":
		result = _need(ctx)
	elif mode == "replay":
		result = _replay(ctx)
	else:
		printerr("unknown mode %s" % mode)
		quit(2)
		return
	result["level"] = String(level_id)
	result["mode"] = mode
	result["seed"] = seed_value
	if ctx["twist_on"]:
		result["twist"] = true
	if fixture:
		result["fixture"] = true
	result["seconds"] = (Time.get_ticks_msec() - started) / 1000.0
	var text: String = JSON.stringify(result)
	print("RESULT " + text)
	var out: String = String(_args.get("out", ""))
	if out != "":
		var file: FileAccess = FileAccess.open(out, FileAccess.WRITE)
		if file == null:
			printerr("cannot write %s" % out)
			quit(2)
			return
		file.store_string(JSON.stringify(result, "  "))
		file.close()
	quit(0)


## level_file=, towers= and enemies=: play other files than the ones in data/. A missing or bad file
## stops the run with exit code 2. The level is rebuilt against the (possibly new) catalog.
func _apply_files(game: GameData, level_id: StringName) -> bool:
	var level_path: String = String(_args.get("level_file", ""))
	var towers_path: String = String(_args.get("towers", ""))
	var enemies_path: String = String(_args.get("enemies", ""))
	if level_path == "" and towers_path == "" and enemies_path == "":
		return true
	var towers: Variant = _read_json(towers_path if towers_path != "" else "res://data/stats/towers.json")
	var enemies: Variant = _read_json(enemies_path if enemies_path != "" else "res://data/stats/enemies.json")
	var rules: Variant = _read_json("res://data/stats/rules.json")
	var level_data: Variant = _read_json(level_path) if level_path != "" else game.levels[level_id].to_data()
	if towers == null or enemies == null or rules == null or level_data == null:
		quit(2)
		return false
	var catalog: Catalog = Catalog.from_data(towers, enemies, rules)
	if catalog == null:
		printerr("stat files are refused: %s" % ", ".join(Catalog.check(towers, enemies, rules)))
		quit(2)
		return false
	var changed: LevelData = LevelData.from_data(level_data, catalog)
	if changed == null:
		printerr("level is refused: %s" % ", ".join(LevelData.check(level_data, catalog)))
		quit(2)
		return false
	game.catalog = catalog
	game.levels[level_id] = changed
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


## A what-if for a suggestion in a report. `tweak` is a comma list of name:value pairs:
##   gold:N          starting gold on Normal
##   count_pct:N     every group's count times N / 100, rounded up (bosses are left alone)
##   strength:N      every wave's strength
##   add_spot:C;R    scenery cell (column C, row R) becomes a build spot; drop_spot:C;R turns a spot into scenery
##   last_strength:N the final wave's strength
##   star3:KIND;N    the level's star 3 rule (star3:tier_at_most;2, star3:towers_at_most;5, star3:no_lives_lost, star3:tower_ban;pumpkin_catapult)
## The level is rebuilt through LevelData.from_data, so the usual checks still apply.
func _apply_tweak(game: GameData, level_id: StringName, tweak: String) -> bool:
	var data: Dictionary = game.levels[level_id].to_data()
	for pair: String in tweak.split(",", false):
		var kv: PackedStringArray = pair.split(":")
		var value: int = int(kv[1])
		match kv[0]:
			"add_spot", "drop_spot":
				# The cell is written column;row, for example add_spot:4;5. A scenery cell becomes
				# a build spot, or a build spot becomes scenery.
				var xy: PackedStringArray = kv[1].split(";")
				var row: String = data["grid"][int(xy[1])]
				var col: int = int(xy[0])
				data["grid"][int(xy[1])] = row.substr(0, col) + ("o" if kv[0] == "add_spot" else ".") + row.substr(col + 1)
			"gold":
				data["start_gold"] = value
			"strength":
				for wave: Dictionary in data["waves"]:
					wave["strength"] = value
			"last_strength":
				data["waves"][data["waves"].size() - 1]["strength"] = value
			"star3":
				# star3:KIND;VALUE, for example star3:tier_at_most;2 or star3:no_lives_lost (a kind with no number).
				var parts: PackedStringArray = kv[1].split(";")
				var star: Dictionary = {"kind": parts[0]}
				if parts.size() > 1 and parts[0] == "tower_ban":
					star["tower"] = parts[1]
				elif parts.size() > 1:
					star["value"] = int(parts[1])
				data["star3"] = star
			"count_pct":
				for wave: Dictionary in data["waves"]:
					for group: Dictionary in wave["groups"]:
						if not game.catalog.enemy(StringName(group["enemy"])).boss:
							group["count"] = (int(group["count"]) * value + 99) / 100
	var changed: LevelData = LevelData.from_data(data, game.catalog)
	if changed == null:
		printerr("tweak %s is refused: %s" % [tweak, ", ".join(LevelData.check(data, game.catalog))])
		quit(2)
		return false
	game.levels[level_id] = changed
	return true


## A what-if on tower numbers. `stat` is a list joined with ~ of tower.field:change, for example
## pumpkin_catapult.splash:+25~sling_post.damage:x80. The change is +N, -N or xP (P percent of the
## number, rounded half up). It applies to every tier and tier 3 path that has the field (a field
## of 0, such as splash on a Sling Post, is left alone). The catalog is rebuilt through
## Catalog.from_data, so the usual checks still apply. Data files on disk are never touched.
func _apply_stat(game: GameData, level_id: StringName, stat: String) -> bool:
	var towers: Variant = JSON.parse_string(FileAccess.get_file_as_string(String(_args.get("towers", "res://data/stats/towers.json"))))
	var enemies: Variant = JSON.parse_string(FileAccess.get_file_as_string(String(_args.get("enemies", "res://data/stats/enemies.json"))))
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/stats/rules.json"))
	for change: String in stat.split("~", false):
		var halves: PackedStringArray = change.split(":")
		var name_parts: PackedStringArray = halves[0].split(".")
		var how: String = halves[1]
		for tower: Dictionary in towers["towers"]:
			if tower["id"] != name_parts[0]:
				continue
			var blocks: Array = []
			blocks.append_array(tower["tiers"])
			blocks.append_array(tower["specs"])
			for block: Dictionary in blocks:
				if not block.has(name_parts[1]) or int(block[name_parts[1]]) == 0:
					continue
				var old: int = int(block[name_parts[1]])
				if how.begins_with("x"):
					block[name_parts[1]] = (old * int(how.substr(1)) + 50) / 100
				else:
					block[name_parts[1]] = old + int(how)
	var catalog: Catalog = Catalog.from_data(towers, enemies, rules)
	if catalog == null:
		printerr("stat %s is refused: %s" % [stat, ", ".join(Catalog.check(towers, enemies, rules))])
		quit(2)
		return false
	var changed: LevelData = LevelData.from_data(game.levels[level_id].to_data(), catalog)
	game.catalog = catalog
	game.levels[level_id] = changed
	return true


func _allowed(ctx: Dictionary, only: String) -> Array[StringName]:
	var offered: Array[StringName] = ctx["offered"]
	if only == "any":
		return offered.duplicate()
	var out: Array[StringName] = []
	if only.begins_with("solo:"):
		# One attacking tower and every support tower of the level, in the level's order.
		var attacker: StringName = StringName(only.substr(5))
		for id: StringName in offered:
			if id == attacker or ctx["catalog"].tower(id).kind != &"attack":
				out.append(id)
		return out
	for id: String in only.split(",", false):
		if offered.has(StringName(id)):
			out.append(StringName(id))
	return out


# Spread: how strategies of each style fare.

func _spread(ctx: Dictionary, seed_value: int, n: int) -> Dictionary:
	var allowed: Array[StringName] = ctx["offered"].duplicate()
	var styles: Dictionary = {}
	var share_bins: Dictionary = {}
	var size_bins: Dictionary = {}
	var peak_max: int = 0
	var peak_strategy: Dictionary = {}
	var style_list: Array[StringName] = Bot.STYLES.duplicate()
	if String(_args.get("style", "")) == "guided":
		style_list = [&"guided"]
	for s: int in style_list.size():
		var style: StringName = style_list[s]
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = seed_value + 7919 * (s + 1)
		var rows: Dictionary = {"normal": _tally(), "relaxed": _tally()}
		for i: int in n:
			var strat: Dictionary = Bot.random_strategy(ctx, rng, style, allowed)
			for mode: String in ["normal", "relaxed"]:
				var res: Dictionary = Bot.play(ctx, strat, mode == "relaxed")
				_add(rows[mode], res)
				if mode == "normal" and int(res["peak"]) > peak_max:
					peak_max = int(res["peak"])
					peak_strategy = Bot.to_data(strat)
				# Win rate by how much of the build is the first offered tower, and by tower count.
				var firsts: int = 0
				for t: Dictionary in strat["towers"]:
					if t["type"] == allowed[0]:
						firsts += 1
				var share: int = firsts * 4 / maxi(strat["towers"].size(), 1)
				_add(_bin(share_bins, "%s|%s_quarters_%d" % [mode, allowed[0], share]), res)
				_add(_bin(size_bins, "%s|%d_towers" % [mode, strat["towers"].size()]), res)
		styles[String(style)] = rows
	return {"n_per_style": n, "styles": styles, "by_first_tower_share": share_bins, "by_tower_count": size_bins,
		"peak_max": peak_max, "peak_strategy": peak_strategy}


func _tally() -> Dictionary:
	return {"n": 0, "won": 0, "two": 0, "three": 0, "rule3": 0, "lives_sum": 0, "ticks_sum": 0, "stuck": 0, "final": 0, "died_at": {}}


func _bin(bins: Dictionary, key: String) -> Dictionary:
	if not bins.has(key):
		bins[key] = _tally()
	return bins[key]


func _add(t: Dictionary, res: Dictionary) -> void:
	t["n"] = int(t["n"]) + 1
	if bool(res["stuck"]):
		t["stuck"] = int(t["stuck"]) + 1
	if res["lives_at"].size() >= _waves:
		t["final"] = int(t["final"]) + 1                    # the final wave started
	if not bool(res["won"]):
		var key: String = str(int(res["cleared"]) + 1)      # the wave (1 based) the run was lost in
		var died: Dictionary = t["died_at"]
		died[key] = int(died.get(key, 0)) + 1
	if bool(res["won"]):
		t["won"] = int(t["won"]) + 1
		t["lives_sum"] = int(t["lives_sum"]) + int(res["lives"])
		t["ticks_sum"] = int(t["ticks_sum"]) + int(res["ticks"])
		var stars: int = int(res["stars"])
		if (stars & 2) != 0:
			t["two"] = int(t["two"]) + 1
		if (stars & 4) != 0:
			t["rule3"] = int(t["rule3"]) + 1                    # the level's own star 3 rule was met
		if stars == 7:
			t["three"] = int(t["three"]) + 1


# Search.

func _search(ctx: Dictionary, seed_value: int, evals: int, allowed: Array[StringName]) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value + 104729
	var pool: Array = []                                    # [{strat, res, fit}] best first
	var seen: Dictionary = {}
	var played: int = 0
	var wins: int = 0
	var star_counts: Dictionary = {"lost": 0, "1": 0, "2": 0, "3": 0}
	var threes: Array = []
	var best_win: Dictionary = {}
	var first_three: int = -1
	var rule3_wins: int = 0                                 # wins that met the level's star 3 rule, with or without star 2
	var rule3_best_lives: int = -1                          # the most lives left in such a win
	var peak_max: int = 0
	var attempts: int = 0
	var start_count: int = evals / 3
	var level: LevelData = ctx["level"]
	var stop_dry: int = int(_args.get("stop_dry", "0"))
	var stopped_dry: bool = false
	while played < evals and attempts < evals * 20:
		if stop_dry > 0 and played >= stop_dry and wins == 0:
			stopped_dry = true
			break
		attempts += 1
		var strat: Dictionary
		if played < start_count or pool.is_empty() or rng.randf() < 0.1:
			var style: StringName = &"typical" if rng.randf() < 0.4 else &"skilled"
			strat = Bot.random_strategy(ctx, rng, style, allowed)
		else:
			var parent: Dictionary = _tournament(pool, rng)
			strat = Bot.mutate(ctx, parent["strat"], rng, allowed)
		if _args.get("early", "on") == "off":
			strat["early"]["on"] = false
		var sig: String = Bot.signature(strat)
		if seen.has(sig):
			continue
		seen[sig] = true
		played += 1
		var res: Dictionary = Bot.play(ctx, strat, false)
		peak_max = maxi(peak_max, int(res["peak"]))
		var fit: int = Bot.fitness(res)
		if bool(res["won"]):
			wins += 1
			var stars: int = int(res["stars"])
			var key: String = "3" if stars == 7 else ("2" if (stars & 2) != 0 else "1")
			star_counts[key] = int(star_counts[key]) + 1
			if (stars & 4) != 0:
				rule3_wins += 1
				rule3_best_lives = maxi(rule3_best_lives, int(res["lives"]))
			if stars == 7:
				if first_three < 0:
					first_three = played
				threes.append({"strat": strat, "res": _slim(res)})
			if best_win.is_empty() or fit > int(best_win["fit"]):
				best_win = {"fit": fit, "strat": strat, "res": res}
		else:
			star_counts["lost"] = int(star_counts["lost"]) + 1
		pool.append({"strat": strat, "res": res, "fit": fit})
		pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["fit"]) > int(b["fit"]))
		if pool.size() > 40:
			pool.resize(40)
	# The best three star wins first, by lives left, then fewer towers.
	threes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var la: int = int(a["res"]["lives"])
		var lb: int = int(b["res"]["lives"])
		if la != lb:
			return la > lb
		return Bot.signature(a["strat"]) < Bot.signature(b["strat"]))
	var out: Dictionary = {"evals": played, "wins": wins, "outcomes": star_counts, "first_three_star_eval": first_three,
		"three_star_found": threes.size(), "peak_max": peak_max, "allowed": _names(allowed),
		"rule3_wins": rule3_wins, "rule3_best_lives": rule3_best_lives, "stopped_dry": stopped_dry}
	# Tower use across every three star win found: what stood at the end, not what was planned.
	var use: Dictionary = {}
	var mix: Dictionary = {}
	var lives_hist: Dictionary = {}
	var towers_hist: Dictionary = {}
	var early_used: int = 0
	for item: Dictionary in threes:
		var built: Dictionary = item["res"]["built"]
		var parts: Array = []
		for key: String in built:
			use[key] = int(use.get(key, 0)) + 1
			if not (key in ["quickshot", "stone_sling", "prize_pumpkin", "jam_pot"]):
				parts.append("%s:%d" % [key, int(built[key])])
		parts.sort()
		var mix_key: String = ",".join(parts)
		mix[mix_key] = int(mix.get(mix_key, 0)) + 1
		var lives_key: String = str(int(item["res"]["lives"]))
		lives_hist[lives_key] = int(lives_hist.get(lives_key, 0)) + 1
		var towers_key: String = str(int(item["res"]["towers"]))
		towers_hist[towers_key] = int(towers_hist.get(towers_key, 0)) + 1
		if int(item["res"]["early"]) > 0:
			early_used += 1
	out["three_star_builds_using"] = use
	out["three_star_mix"] = mix
	out["three_star_lives"] = lives_hist
	out["three_star_towers"] = towers_hist
	out["three_star_early_used"] = early_used
	var listed: Array = []
	for i: int in mini(threes.size(), 12):
		var strat2: Dictionary = threes[i]["strat"]
		listed.append({"strategy": Bot.to_data(strat2), "result": threes[i]["res"], "inventory": threes[i]["res"]["built"],
			"text": Bot.describe(ctx, strat2)})
	out["three_star_best"] = listed
	var small: Array = []
	for item: Dictionary in threes:
		var placed: Array = item["strat"]["gates"]
		var entry: Dictionary = {"inventory": item["res"]["built"], "lives": item["res"]["lives"], "towers": item["res"]["towers"],
			"early": item["res"]["early"], "gate": String(str(placed[0] if not placed.is_empty() else Bot.NO_CELL))}
		if placed.size() > 1:
			entry["gates"] = Bot.gates_label(placed)
		small.append(entry)
	out["three_star_all"] = small if small.size() <= 400 else small.slice(0, 400)
	if not best_win.is_empty():
		var bs: Dictionary = best_win["strat"]
		out["best_win"] = {"strategy": Bot.to_data(bs), "result": _slim(best_win["res"]), "text": Bot.describe(ctx, bs),
			"inventory": Bot.inventory(ctx, bs)}
	# The best fit even when nothing won: shows how close a restricted search came.
	if not pool.is_empty():
		var top: Dictionary = pool[0]
		out["top"] = {"strategy": Bot.to_data(top["strat"]), "result": _slim(top["res"]), "text": Bot.describe(ctx, top["strat"])}
	out["level_towers"] = _names(level.towers)
	return out


func _tournament(pool: Array, rng: RandomNumberGenerator) -> Dictionary:
	var best: int = rng.randi_range(0, pool.size() - 1)
	for i: int in 2:
		best = mini(best, rng.randi_range(0, pool.size() - 1))
	return pool[best]


func _names(ids: Array[StringName]) -> Array:
	var out: Array = []
	for id: StringName in ids:
		out.append(String(id))
	return out


## The numbers worth keeping from one play.
func _slim(res: Dictionary) -> Dictionary:
	return {"waves": _waves, "won": res["won"], "stars": res["stars"], "lives": res["lives"], "cleared": res["cleared"], "ticks": res["ticks"],
		"peak": res["peak"], "early": res["early"], "towers": res["towers"], "max_tier": res["max_tier"], "kinds": _names(res["kinds"]),
		"gold_at": res["gold_at"], "lives_at": res["lives_at"], "spent_at": res["spent_at"], "wave_ticks": res["wave_ticks"],
		"end_gold": res["end_gold"], "boss_hp": res["boss_hp"], "boss_steps": res["boss_steps"], "digest": res["digest"], "built": res["built"]}


# Recipes.

## Plain recipes. Each is [name, type pattern, depth, spec, spot order]. The pattern is the tower
## ids for spot 1, 2, 3 and so on, repeated. Spot order is "cell" (top row first) or "road" (the
## spots that see the most road first). None of them targets, calls early or buys during waves.
const RECIPES: Array = [
	["sling x all, no upgrades", ["sling_post"], 0, 0, "cell"],
	["sling x all, tier 2", ["sling_post"], 1, 0, "cell"],
	["sling x all, 3 Quickshots", ["sling_post"], 2, 0, "cell"],
	["sling x all, 3 Stone Slings", ["sling_post"], 2, 1, "cell"],
	["catapult x all, no upgrades", ["pumpkin_catapult"], 0, 0, "cell"],
	["catapult x all, tier 2", ["pumpkin_catapult"], 1, 0, "cell"],
	["catapult x all, 3 Prize Pumpkins", ["pumpkin_catapult"], 2, 0, "cell"],
	["catapult x all, 3 Jam Pots", ["pumpkin_catapult"], 2, 1, "cell"],
	["sling, catapult, alternating, road order, Quickshots and Prize Pumpkins on the first 3", ["sling_post", "pumpkin_catapult"], 2, 0, "road"],
	["sling, catapult, alternating, road order, Stone Slings and Jam Pots on the first 3", ["sling_post", "pumpkin_catapult"], 2, 1, "road"],
	["sling, catapult, alternating, no upgrades", ["sling_post", "pumpkin_catapult"], 0, 0, "cell"],
	["sling, catapult, alternating, tier 2", ["sling_post", "pumpkin_catapult"], 1, 0, "cell"],
	["sling, catapult, alternating, road order, no upgrades", ["sling_post", "pumpkin_catapult"], 0, 0, "road"],
	["sling, catapult, alternating, road order, tier 2", ["sling_post", "pumpkin_catapult"], 1, 0, "road"],
	["sling x all, road order, no upgrades", ["sling_post"], 0, 0, "road"],
	["sling x all, road order, tier 2", ["sling_post"], 1, 0, "road"],
]


func _recipes(ctx: Dictionary) -> Dictionary:
	var level: LevelData = ctx["level"]
	var weights: Array[int] = ctx["weights"]
	var gates: Array = [Bot.NO_CELL]
	if int(ctx["gate_count"]) > 0:
		gates.append_array(ctx["gate_options"])
	var rows: Array = []
	for recipe: Array in RECIPES:
		var spots: Array[Vector2i] = level.spots.duplicate()
		if recipe[4] == "road":
			var order: Array = []
			for i: int in spots.size():
				order.append([-weights[i], i])
			order.sort()
			spots = []
			for item: Array in order:
				spots.append(level.spots[int(item[1])])
		var pattern: Array = recipe[1]
		var towers: Array = []
		var seq: Array = []
		for i: int in spots.size():
			var type: StringName = StringName(String(pattern[i % pattern.size()]))
			if not ctx["offered"].has(type):
				type = ctx["offered"][0]
			# A depth 2 recipe takes only its first three towers to tier 3, the rest stop at tier 2.
			var depth: int = mini(int(recipe[2]), 1 if i >= 3 else 2)
			towers.append({"cell": spots[i], "type": type, "depth": depth, "spec": int(recipe[3]), "aim": TowerState.Aim.FIRST})
		# Breadth first: every build, then every tier 2 upgrade, then the tier 3 upgrades.
		for step: int in int(recipe[2]) + 1:
			for i: int in towers.size():
				if int(towers[i]["depth"]) >= step:
					seq.append(i)
		var per_gate: Array = []
		var summary: Dictionary = {}
		for mode: String in ["normal", "relaxed"]:
			var wins: int = 0
			var best: Dictionary = {}
			var worst: Dictionary = {}
			for gate: Vector2i in gates:
				var strat: Dictionary = {"towers": towers, "seq": seq, "gates": Bot.one_gate(gate), "early": {"on": false, "from": 1, "live": 0, "max": 99}, "wave_buy": false}
				var res: Dictionary = Bot.play(ctx, strat, mode == "relaxed")
				if bool(res["won"]):
					wins += 1
				var fit: int = Bot.fitness(res)
				var slim: Dictionary = {"gate": "none" if gate == Bot.NO_CELL else "%d,%d" % [gate.x, gate.y], "won": res["won"], "stars": res["stars"],
					"lives": res["lives"], "cleared": res["cleared"]}
				if best.is_empty() or fit > int(best["fit"]):
					best = {"fit": fit, "res": slim}
				if worst.is_empty() or fit < int(worst["fit"]):
					worst = {"fit": fit, "res": slim}
				per_gate.append({"mode": mode, "gate": slim["gate"], "won": res["won"], "stars": res["stars"], "lives": res["lives"], "cleared": res["cleared"]})
			summary[mode] = {"gates_tried": gates.size(), "wins": wins, "best": best["res"], "worst": worst["res"]}
		rows.append({"recipe": recipe[0], "summary": summary, "per_gate": per_gate})
	return {"recipes": rows, "waves": level.waves.size()}


# The plain mixed recipe (RULES 12.6).

## The recipe is played on Normal and on Relaxed once for every gate placement that seals no entrance.
## Best placement: a win with the most lives left (more stars break a tie), else the loss that clears
## the most waves. Worst is the other end. The first of equals wins in both. "none" is the empty placement.
func _plain(ctx: Dictionary) -> Dictionary:
	var strat: Dictionary = Bot.plain_recipe(ctx)
	if int(_args.get("max_tier", "0")) > 0:
		strat = Bot.cap_tier(strat, int(_args["max_tier"]))
	var rows: Array = []
	var summary: Dictionary = {}
	for mode: String in ["normal", "relaxed"]:
		var wins: int = 0
		var best: Dictionary = {}
		var worst: Dictionary = {}
		var none: Dictionary = {}
		var best_rank: int = -1
		var worst_rank: int = 1 << 60
		for gates: Array in Bot.placements(ctx):
			var typed: Array[Vector2i] = []
			typed.append_array(gates)
			strat["gates"] = typed
			var res: Dictionary = Bot.play(ctx, strat, mode == "relaxed")
			var rank: int = _plain_rank(res)
			var row: Dictionary = {"mode": mode, "gate": Bot.gates_label(gates), "won": res["won"], "stars": res["stars"],
				"lives": res["lives"], "cleared": res["cleared"], "ticks": res["ticks"], "peak": res["peak"],
				"wave_ticks": res["wave_ticks"], "lives_at": res["lives_at"], "boss_hp": res["boss_hp"], "built": res["built"], "digest": res["digest"]}
			rows.append(row)
			if bool(res["won"]):
				wins += 1
			if rank > best_rank:
				best_rank = rank
				best = row
			if rank < worst_rank:
				worst_rank = rank
				worst = row
			if gates.is_empty():
				none = row
		summary[mode] = {"placements": Bot.placements(ctx).size(), "wins": wins, "best": best, "worst": worst, "none": none}
	var no_gates: Array[Vector2i] = []
	strat["gates"] = no_gates
	var sizes: Array[int] = Bot.wave_sizes(ctx)
	var largest: int = 0
	for size: int in sizes:
		largest = maxi(largest, size)
	var out: Dictionary = {"summary": summary, "placements": rows, "wave_sizes": sizes, "largest_wave": largest,
		"flyers": ctx["flyers"], "region": ctx["region"], "offered": _names(ctx["offered"]), "waves": ctx["level"].waves.size(),
		"recipe": Bot.to_data(strat), "recipe_text": Bot.describe(ctx, strat)}
	if String(_args.get("compare_old", "0")) == "1":
		out["old_recipe"] = _compare_old(ctx, rows)
	return out


## A win ranks by lives left (stars break a tie); a loss by waves cleared, then lives.
func _plain_rank(res: Dictionary) -> int:
	if bool(res["won"]):
		return 1000000 + int(res["lives"]) * 8 + int(res["stars"])
	return int(res["cleared"]) * 100 + int(res["lives"])


## The old region 1 recipe against the plain recipe, placement by placement. The old recipe tries
## no gate and one gate on each socket, so a level with several gates compares only those.
func _compare_old(ctx: Dictionary, rows: Array) -> Dictionary:
	var old: Dictionary = {}
	for item: Dictionary in _recipes(ctx)["recipes"]:
		if String(item["recipe"]).begins_with("sling, catapult, alternating, road order, tier 2"):
			old = item
	var compared: int = 0
	var differences: Array = []
	for old_row: Dictionary in old["per_gate"]:
		for row: Dictionary in rows:
			if row["mode"] == old_row["mode"] and row["gate"] == old_row["gate"]:
				compared += 1
				for key: String in ["won", "stars", "lives", "cleared"]:
					if row[key] != old_row[key]:
						differences.append({"mode": row["mode"], "gate": row["gate"], "field": key, "plain": row[key], "old": old_row[key]})
	return {"compared": compared, "differences": differences}


# Which lone-tower searches the check needs (RULES 12.6).

## The cost, in lives, of the flyers and of the walkers in the wave data (count times lives, bosses included, a
## Puffball as itself). A tower that cannot hit flyers lets every flyer through; a tower that cannot hit walkers
## lets every walker through. From 6 lives up, either can never keep 15 lives, so its search is not needed.
func _need(ctx: Dictionary) -> Dictionary:
	var level: LevelData = ctx["level"]
	var catalog: Catalog = ctx["catalog"]
	var air: int = 0
	var ground: int = 0
	for wave: WaveData in level.waves:
		for group: WaveGroup in wave.groups:
			var type: EnemyType = catalog.enemy(group.enemy)
			if type.flying:
				air += group.count * type.lives
			else:
				ground += group.count * type.lives
	# A level whose star 3 bans a tower: that tower can never earn star 3, so it needs no lone search, and the "All three
	# stars" search may use only the other towers (RULES 12.6 as revised by G4).
	var banned: StringName = &""
	if level.star3["kind"] == &"tower_ban":
		banned = level.star3["tower"]
	var rows: Array = []
	var needed: Array = []
	var allowed: Array[String] = []
	for id: StringName in ctx["offered"]:
		if id != banned:
			allowed.append(String(id))
		var tower: TowerType = catalog.tower(id)
		if tower.kind != &"attack":
			continue
		var stats: TowerStats = tower.stats(1, -1)
		var reason: String = ""
		if id == banned:
			reason = "the level's star 3 bans it, so it can never earn star 3"
		elif not stats.hits_air and air >= 6:
			reason = "cannot hit flyers, which cost %d lives" % air
		elif not stats.hits_ground and ground >= 6:
			reason = "cannot hit walkers, which cost %d lives" % ground
		rows.append({"tower": String(id), "search": reason == "", "reason": reason})
		if reason == "":
			needed.append(String(id))
	return {"flyer_cost": air, "walker_cost": ground, "attackers": rows, "search_needed": needed, "banned": String(banned),
		"all_three_only": "any" if banned == &"" else ",".join(PackedStringArray(allowed))}


# Replaying saved strategies.

## Strategies saved in a search result file, or the plain recipe. Each: label, the strategy as saved, and the saved result.
func _saved_strategies(ctx: Dictionary, path: String, pick: String) -> Array:
	var out: Array = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		printerr("cannot read %s" % path)
		return out
	var data: Dictionary = parsed
	var base: String = path.get_file().get_basename()
	if pick in ["best_win", "all"] and data.has("best_win"):
		out.append({"label": base + ":best_win", "strategy": data["best_win"]["strategy"], "saved": data["best_win"]["result"]})
	if pick in ["three_star_best", "all"]:
		var n: int = 0
		for item: Dictionary in data.get("three_star_best", []):
			n += 1
			out.append({"label": "%s:three_star_best_%d" % [base, n], "strategy": item["strategy"], "saved": item["result"]})
	if pick in ["top", "all"] and data.has("top"):
		out.append({"label": base + ":top", "strategy": data["top"]["strategy"], "saved": data["top"]["result"]})
	return out


func _replay(ctx: Dictionary) -> Dictionary:
	var relaxed: bool = String(_args.get("relaxed", "0")) == "1"
	var pick: String = String(_args.get("pick", "best_win"))
	var rows: Array = []
	var items: Array = []
	for path: String in String(_args.get("from", "plain")).split(",", false):
		if path == "plain":
			var plain: Dictionary = Bot.plain_recipe(ctx)
			if int(_args.get("max_tier", "0")) > 0:
				plain = Bot.cap_tier(plain, int(_args["max_tier"]))
			for gates: Array in Bot.placements(ctx):
				var typed: Array[Vector2i] = []
				typed.append_array(gates)
				var one: Dictionary = plain.duplicate(true)
				one["gates"] = typed
				items.append({"label": "plain:" + Bot.gates_label(gates), "strategy": Bot.to_data(one), "saved": {}})
		else:
			items.append_array(_saved_strategies(ctx, path, pick))
	for item: Dictionary in items:
		var watch: Dictionary = {"on": true}
		var strat: Dictionary = Bot.from_data(item["strategy"])
		if int(_args.get("max_tier", "0")) > 0:
			strat = Bot.cap_tier(strat, int(_args["max_tier"]))
		var res: Dictionary = Bot.play(ctx, strat, relaxed, false, -1, watch)
		watch.erase("wave_of")
		watch.erase("on")
		var saved: Dictionary = item["saved"]
		var row: Dictionary = {"label": item["label"], "won": res["won"], "stars": res["stars"], "lives": res["lives"], "cleared": res["cleared"],
			"ticks": res["ticks"], "peak": res["peak"], "built": res["built"], "lives_at": res["lives_at"],
			"leaks": watch.get("leaks", {}), "leaks_wave": watch.get("leaks_wave", {}), "kills": watch.get("kills", {}),
			"bosses": watch.get("bosses", {}).values(), "relaxed": relaxed}
		if not saved.is_empty():
			row["saved"] = {"won": saved["won"], "stars": saved["stars"], "lives": saved["lives"], "cleared": saved["cleared"]}
		# B6: what the expansion's towers and creature rules did. Only where it is new: a level that offers an expansion tower, and
		# a creature rule that fired. Regions 1 to 4 give rows exactly as before.
		var expansion: bool = false
		for tower_id: StringName in ctx["offered"]:
			expansion = expansion or Bot.EXPANSION_TOWERS.has(tower_id)
		if expansion:
			row["shots"] = watch.get("shots", {})
			row["hits"] = watch.get("hits", {})
		if not (watch.get("rule_events", {}) as Dictionary).is_empty():
			row["rule_events"] = watch["rule_events"]
		rows.append(row)
	return {"rows": rows, "pick": pick}


# Exhaustive check of small builds.

## mode=exhaust: every static build of at most `max_towers` towers (default 2) of the allowed kinds,
## on every spot choice, every upgrade depth and tier 3 path for each tower, every
## purchase order, every aim for each tower, every gate choice, buying during waves or not, and early
## calls off or on (from wave 2, when at most 8 creatures are on the map). The builds are numbered;
## `depth_max=N` limits the upgrade depth (0 is tier 1 only) and `aims=first` plays only the default aim.
## `shard=K shards=N` plays only those whose number leaves K when divided by N, so N processes
## cover the whole set together. This is the check behind "no single tower type earns three stars
## alone" for a level whose star 3 limits the number of towers.
func _exhaust(ctx: Dictionary, allowed: Array[StringName], max_towers: int, shard: int, shards: int) -> Dictionary:
	var level: LevelData = ctx["level"]
	var spots: Array[Vector2i] = level.spots
	var gates: Array = [Bot.NO_CELL]
	if int(ctx["gate_count"]) > 0:
		gates.append_array(ctx["gate_options"])
	var depth_max: int = int(_args.get("depth_max", "2"))
	var all_aims: bool = String(_args.get("aims", "all")) == "all"
	var options: Array = []                                      # depth, spec
	for option: Array in [[0, 0], [1, 0], [2, 0], [2, 1]]:
		if int(option[0]) <= depth_max:
			options.append(option)
	var number: int = 0
	var played: int = 0
	var wins: int = 0
	var rule3_wins: int = 0
	var rule3_best_lives: int = -1
	var threes: int = 0
	var best_fit: int = -1
	var best: Dictionary = {}
	for picked: Array in _subsets(spots.size(), max_towers):
		var combos: Array = [[]]                                # per tower: type and (depth, spec)
		for slot: int in picked.size():
			var grown: Array = []
			for partial: Array in combos:
				for type: StringName in allowed:
					for option: Array in options:
						var more: Array = partial.duplicate()
						more.append([type, option[0], option[1]])
						grown.append(more)
			combos = grown
		for combo: Array in combos:
			var counts: Array[int] = []
			for item: Array in combo:
				counts.append(1 + int(item[1]))
			var orders: Array = []
			_orders(counts.duplicate(), [], orders)
			for aim_code: int in (int(pow(3.0, picked.size())) if all_aims else 1):
				for gate: Vector2i in gates:
					for order: Array in orders:
						for wave_buy: bool in [false, true]:
							for early_on: bool in [false, true]:
								number += 1
								if number % shards != shard:
									continue
								var towers: Array = []
								for k: int in picked.size():
									towers.append({"cell": spots[int(picked[k])], "type": combo[k][0], "depth": int(combo[k][1]),
										"spec": int(combo[k][2]), "aim": (aim_code / int(pow(3.0, k))) % 3})
								var strat: Dictionary = {"towers": towers, "seq": order, "gates": Bot.one_gate(gate), "wave_buy": wave_buy,
									"early": {"on": early_on, "from": 1, "live": 8, "max": 99}}
								var res: Dictionary = Bot.play(ctx, strat, false)
								played += 1
								if bool(res["won"]):
									wins += 1
									var stars: int = int(res["stars"])
									if (stars & 4) != 0:
										rule3_wins += 1
										rule3_best_lives = maxi(rule3_best_lives, int(res["lives"]))
									if stars == 7:
										threes += 1
								var fit: int = Bot.fitness(res)
								if bool(res["won"]) and (int(res["stars"]) & 4) != 0 and fit > best_fit:
									best_fit = fit
									best = {"strategy": Bot.to_data(strat), "result": _slim(res), "text": Bot.describe(ctx, strat)}
	return {"builds_in_all": number, "evals": played, "wins": wins, "rule3_wins": rule3_wins, "rule3_best_lives": rule3_best_lives,
		"three_star_found": threes, "max_towers": max_towers, "shard": shard, "shards": shards, "allowed": _names(allowed),
		"best_rule3_win": best}


## Every set of 1 to `most` spot indexes out of `count`, as arrays of indexes in order.
func _subsets(count: int, most: int) -> Array:
	var out: Array = []
	for size: int in range(1, most + 1):
		_choose(count, size, 0, [], out)
	return out


func _choose(count: int, size: int, from: int, cur: Array, out: Array) -> void:
	if cur.size() == size:
		out.append(cur.duplicate())
		return
	for i: int in range(from, count):
		cur.append(i)
		_choose(count, size, i + 1, cur, out)
		cur.pop_back()


## Every distinct order of the purchases: the tower index appears counts[i] times.
func _orders(left: Array[int], cur: Array, out: Array) -> void:
	var done: bool = true
	for i: int in left.size():
		if left[i] > 0:
			done = false
			left[i] -= 1
			cur.append(i)
			_orders(left, cur, out)
			cur.pop_back()
			left[i] += 1
	if done:
		out.append(cur.duplicate())


# Determinism.

func _det(ctx: Dictionary, seed_value: int) -> Dictionary:
	var allowed: Array[StringName] = ctx["offered"].duplicate()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var same: int = 0
	var checked: int = 0
	var restores: int = 0
	var restores_same: int = 0
	var chain: String = ""
	for i: int in 24:
		var style: StringName = Bot.STYLES[i % 3]
		var strat: Dictionary = Bot.random_strategy(ctx, rng, style, allowed)
		var relaxed: bool = i % 4 == 3
		var a: Dictionary = Bot.play(ctx, strat, relaxed)
		var b: Dictionary = Bot.play(ctx, strat, relaxed)
		var c: Dictionary = Bot.play(ctx, Bot.from_data(Bot.to_data(strat)), relaxed, true)
		checked += 1
		for at: int in [300, 900, 1700]:
			var d: Dictionary = Bot.play(ctx, strat, relaxed, false, at)
			restores += 1
			if d["digest"] == a["digest"] and d["stars"] == a["stars"] and d["ticks"] == a["ticks"] and d["lives"] == a["lives"]:
				restores_same += 1
		if a["digest"] == b["digest"] and a["digest"] == c["digest"] and a["ticks"] == b["ticks"] and a["stars"] == b["stars"] \
				and a["lives"] == b["lives"] and a["stars"] == c["stars"] and a["ticks"] == c["ticks"]:
			same += 1
		chain += "%d:%d:%d;" % [a["digest"], a["stars"], a["ticks"]]
	var s1: Dictionary = _search(ctx, seed_value, 60, allowed)
	var s2: Dictionary = _search(ctx, seed_value, 60, allowed)
	var search_same: bool = JSON.stringify(s1) == JSON.stringify(s2)
	return {"plays_checked": checked, "plays_identical": same, "restores_checked": restores, "restores_identical": restores_same,
		"search_repeat_identical": search_same,
		"chain_hash": chain.hash(), "search_hash": JSON.stringify(s1).hash()}
