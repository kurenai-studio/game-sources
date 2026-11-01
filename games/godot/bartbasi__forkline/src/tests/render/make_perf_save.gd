# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Writes a game_level.json that stops in the build phase just before a level's largest wave,
## for the phone frame time test (docs/ARCHITECTURE.md 9.4, docs/render/perf-fold5-2026-10-26.md).
##
##   godot --headless --path . --script res://tests/render/make_perf_save.gd -- levels=r2_l2,r4_l3 out=C:/path/in/TEMP [seeds=60]
##
## For each level a bot (tools/balance/bot.gd) plays a seeded random strategy up to the build phase
## before the largest wave. Then the rest of the level is played with an early call as soon as one is
## allowed, as a player would to get two waves on the map. Of the seeds that still win, the one with
## the most live creatures is kept (a weaker defense gives a bigger crowd). The save goes through
## SaveStore into a folder under user://tests/render/, is loaded back and checked against the battle,
## and is then copied to out/<level>/game_level.json. Prints one RESULT line per level.

const Bot: GDScript = preload("res://tools/balance/bot.gd")
const SAVE_ROOT: String = "user://tests/render/perf_saves/"
const STYLES: Array[StringName] = [&"casual", &"typical", &"typical"]


func _initialize() -> void:
	var args: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.split("=", true, 1)
		if parts.size() == 2:
			args[parts[0]] = parts[1]
	var out_dir: String = String(args.get("out", ""))
	var seeds: int = int(String(args.get("seeds", "60")))
	if out_dir.is_empty() or not args.has("levels"):
		printerr("usage: levels=r2_l2,r4_l3 out=DIR [seeds=60]")
		quit(2)
		return
	var game: GameData = GameData.load_from("res://data")
	if not game.problems.is_empty():
		printerr("bad data")
		quit(2)
		return
	var failed: bool = false
	for id_text: String in String(args["levels"]).split(",", false):
		var level_id: StringName = StringName(id_text)
		if not game.levels.has(level_id) or not _make(game, level_id, seeds, out_dir):
			failed = true
	quit(1 if failed else 0)


func _make(game: GameData, level_id: StringName, seeds: int, out_dir: String) -> bool:
	var ctx: Dictionary = Bot.context(game, level_id)
	if ctx.has("bad"):
		return false
	var sizes: Array[int] = Bot.wave_sizes(ctx)
	var target: int = 0
	for i: int in sizes.size():
		if sizes[i] > sizes[target]:
			target = i
	var best_seed: int = -1
	var best_peak: int = -1
	var best_won: bool = false
	for s: int in seeds:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 7700 + s
		var strat: Dictionary = Bot.random_strategy(ctx, rng, STYLES[s % STYLES.size()], ctx["offered"])
		var b: Battle = _play_to(ctx, strat, target)
		if b == null:
			continue
		var tail: Dictionary = _tail(ctx, b)
		var won: bool = bool(tail["won"])
		var peak: int = int(tail["peak"])
		# A win beats a loss; then the bigger crowd.
		if (won and not best_won) or (won == best_won and peak > best_peak):
			best_seed = s
			best_peak = peak
			best_won = won
	if best_seed < 0:
		printerr("%s: no seed reached wave %d" % [level_id, target + 1])
		return false
	var rng2: RandomNumberGenerator = RandomNumberGenerator.new()
	rng2.seed = 7700 + best_seed
	var strat2: Dictionary = Bot.random_strategy(ctx, rng2, STYLES[best_seed % STYLES.size()], ctx["offered"])
	var battle: Battle = _play_to(ctx, strat2, target)
	var saved: SavedGame = SavedGame.new()
	saved.mode = SavedGame.LEVEL
	saved.level_id = level_id
	saved.battle = battle
	var dir: String = SAVE_ROOT + String(level_id)
	var store: SaveStore = SaveStore.new(dir)
	store.delete_game(SavedGame.LEVEL)
	if not store.save_game(saved):
		printerr("%s: SaveStore refused the game" % level_id)
		return false
	# Load it back through a new store, the way the game does on launch.
	var back: Array[SavedGame] = SaveStore.new(dir).load_games(game)
	if back.size() != 1 or back[0].level_id != level_id or back[0].battle.phase != Battle.Phase.BUILD \
			or back[0].battle.waves_started != target \
			or JSON.stringify(back[0].battle.to_data()) != JSON.stringify(battle.to_data()):
		printerr("%s: the save did not load back the same" % level_id)
		return false
	var text: String = FileAccess.get_file_as_string(dir + "/game_level.json")
	var target_dir: String = out_dir.path_join(String(level_id))
	DirAccess.make_dir_recursive_absolute(target_dir)
	var file: FileAccess = FileAccess.open(target_dir.path_join("game_level.json"), FileAccess.WRITE)
	if file == null:
		printerr("cannot write to %s" % target_dir)
		return false
	file.store_string(text)
	file.close()
	var info: Dictionary = {"level": String(level_id), "wave": target + 1, "waves": battle.wave_count(), "wave_size": sizes[target],
		"seed": 7700 + best_seed, "tail_peak": best_peak, "tail_won": best_won, "towers": battle.towers.size(),
		"lives": battle.lives, "gold": battle.gold, "bytes": text.length()}
	print("RESULT " + JSON.stringify(info))
	return true


## Plays the strategy until the build phase before wave index `target`. Null when the level is lost
## first. Buys what the strategy allows, as the bot does.
func _play_to(ctx: Dictionary, strat: Dictionary, target: int) -> Battle:
	var b: Battle = Battle.create(ctx["level"], ctx["catalog"], false, ctx["twist"])
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


## Plays on from a build phase with an early call as soon as one is allowed, on a copy.
func _tail(ctx: Dictionary, b: Battle) -> Dictionary:
	var copy: Battle = Battle.from_data(b.to_data(), ctx["catalog"])
	var peak: int = 0
	while (copy.phase == Battle.Phase.BUILD or copy.phase == Battle.Phase.WAVE) and copy.tick < Bot.TICK_CAP:
		if copy.next_wave_info()["refusal"] == &"":
			copy.start_next_wave()
		if copy.phase == Battle.Phase.WAVE:
			copy.step()
			peak = maxi(peak, copy.enemies.size())
	return {"won": copy.phase == Battle.Phase.WON, "peak": peak, "lives": copy.lives}
