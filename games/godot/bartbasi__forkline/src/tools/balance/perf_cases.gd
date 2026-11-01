# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## The survey for the benchmark's largest wave (docs/ARCHITECTURE.md B5): how many creatures each wave of the game spawns,
## with no play at all. Campaign levels and their Twists (the Twist's own counts included), and every run pack wave with
## each risk card (RunPacks.spawn_total, a Puffball counts as itself and its 3 Puffs, as RULES 14.3 counts).
##
##   godot --headless --path . --script res://tools/balance/perf_cases.gd -- out=PATH [jobs=N] [tier=N] [fixture=1]
##
## B6: tier=N counts only the packs of that tier and below (RULES 14.9), and fixture=1 reads the test catalog, the fixture levels and the
## fixture run tiers (tools/balance/fixtures.gd). With neither, it is the survey it was.
##
## jobs=N also prints the perf_peak.gd job lines (OUTDIR for the folder) for the N biggest run waves with a risk card and
## the N biggest pairs (a risk card wave and the next wave).
##
## Prints markdown (the biggest single waves, and the biggest pairs of waves that can be on the map together, since two
## waves may overlap) and writes the rows as JSON.

const Bot: GDScript = preload("res://tools/balance/bot.gd")
const Fixtures: GDScript = preload("res://tools/balance/fixtures.gd")
const TOP: int = 12


func _initialize() -> void:
	var tier: int = 0
	var fixture: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("tier="):
			tier = int(argument.trim_prefix("tier="))
		if argument == "fixture=1":
			fixture = true
	var game: GameData = Fixtures.game() if fixture else GameData.load_from("res://data")
	if game == null or not game.problems.is_empty() or game.run == null or tier < 0 or tier > game.run.tiers.size():
		printerr("data problems")
		quit(2)
		return
	var rows: Array = []
	var ids: Array[String] = []
	for key: Variant in game.levels.keys():
		ids.append(String(key))
	ids.sort()
	for id: String in ids:
		var level: LevelData = game.levels[StringName(id)]
		for twist: bool in [false, true]:
			if twist and level.twist_name.is_empty():
				continue
			var ctx: Dictionary = Bot.context(game, StringName(id), twist)
			if ctx.has("bad"):
				continue
			var sizes: Array[int] = Bot.wave_sizes(ctx)
			rows.append({"kind": "level", "label": "%s%s" % [id, " Twist" if twist else ""], "level": id, "twist": twist, "sizes": sizes})
	var risk_cards: Array[Dictionary] = []
	for card: Dictionary in game.run.cards:
		if card["kind"] == &"risk":
			risk_cards.append(card)
	for pack: Dictionary in game.run.packs:
		if int(pack["tier"]) > tier:
			continue
		var sizes_by: Dictionary = {}
		var names: Array[String] = ["none"]
		for card: Dictionary in risk_cards:
			names.append(String(card["id"]))
		for name: String in names:
			var effects: Array[Dictionary] = []
			if name != "none":
				for card: Dictionary in risk_cards:
					if String(card["id"]) == name:
						effects.append_array(card["effects"])
			var list: Array[int] = []
			for w: int in 3:
				list.append(RunPacks.spawn_total(pack["waves"][w]["groups"], game.catalog, effects))
			sizes_by[name] = list
		rows.append({"kind": "pack", "label": String(pack["id"]), "pack": String(pack["id"]), "band": int(pack["band"]), "sizes_by": sizes_by})
	_print(rows)
	var out: String = ""
	var jobs: int = 0
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("out="):
			out = argument.trim_prefix("out=")
		if argument.begins_with("jobs="):
			jobs = int(argument.trim_prefix("jobs="))
	if jobs > 0:
		_print_jobs(rows, jobs)
	if out != "":
		var file: FileAccess = FileAccess.open(out, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"rows": rows}))
			file.close()
	quit(0)


func _print(rows: Array) -> void:
	# One entry for each (case, wave): {"label", "wave" (1-based), "size", "next" (the next wave's size with no card)}.
	var singles: Array = []
	for row: Dictionary in rows:
		if row["kind"] == "level":
			var sizes: Array = row["sizes"]
			for w: int in sizes.size():
				singles.append({"label": row["label"], "wave": w + 1, "size": int(sizes[w]), "next": int(sizes[w + 1]) if w + 1 < sizes.size() else 0, "card": "-"})
		else:
			var by: Dictionary = row["sizes_by"]
			for name: String in by.keys():
				for k: int in 3:
					var wave: int = (int(row["band"]) - 1) * 3 + k + 1
					# A risk card cannot change the boss wave (14.4).
					if name != "none" and wave > 17:
						continue
					var next: int = 0
					if k + 1 < 3:
						next = int(by["none"][k + 1])
					singles.append({"label": row["label"], "wave": wave, "size": int(by[name][k]), "next": next, "card": name})
	print("\n### Biggest single waves (creatures spawned, Puffs counted)\n")
	singles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["size"]) > int(b["size"]))
	print("| Case | Wave | Risk card | Creatures |")
	print("|---|---|---|---|")
	for i: int in mini(TOP, singles.size()):
		var e: Dictionary = singles[i]
		print("| %s | %d | %s | %d |" % [e["label"], e["wave"], e["card"], e["size"]])
	print("\n### Biggest pairs of waves (a wave and the next one, which a player can call early)\n")
	singles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["size"]) + int(a["next"]) > int(b["size"]) + int(b["next"]))
	print("| Case | Wave | Risk card | Creatures, wave and next |")
	print("|---|---|---|---|")
	for i: int in mini(TOP, singles.size()):
		var e: Dictionary = singles[i]
		print("| %s | %d | %s | %d + %d = %d |" % [e["label"], e["wave"], e["card"], e["size"], e["next"], int(e["size"]) + int(e["next"])])


## perf_peak.gd job lines for the run pack waves: the biggest single waves with a risk card, and the biggest pairs.
func _print_jobs(rows: Array, count: int) -> void:
	var cases: Array = []
	for row: Dictionary in rows:
		if row["kind"] != "pack":
			continue
		var by: Dictionary = row["sizes_by"]
		for name: String in by.keys():
			if name == "none":
				continue
			for k: int in 3:
				var wave: int = (int(row["band"]) - 1) * 3 + k + 1
				if wave < 2 or wave > 17:
					continue
				var next: int = int(by["none"][k + 1]) if k + 1 < 3 else 0
				cases.append({"pack": row["pack"], "wave": wave, "card": name, "size": int(by[name][k]), "pair": int(by[name][k]) + next})
	var chosen: Dictionary = {}
	for key: String in ["size", "pair"]:
		cases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a[key]) > int(b[key]))
		for i: int in mini(count, cases.size()):
			var e: Dictionary = cases[i]
			chosen["%s:%d:%s" % [e["pack"], e["wave"], e["card"]]] = e
	for key: String in chosen.keys():
		var e2: Dictionary = chosen[key]
		print("JOB run=%s wave=%d card=%s seeds=10 out=OUTDIR/perf_run_%s_w%d_%s.json" % [e2["pack"], e2["wave"], e2["card"], e2["pack"], e2["wave"], e2["card"]])
