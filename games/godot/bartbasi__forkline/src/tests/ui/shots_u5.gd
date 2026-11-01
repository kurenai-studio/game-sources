# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Screenshots for step U5: the creature panel with each status, the Info guide with the new
## towers, creatures, bosses and map features, and the mode screen with the Daily regions
## line, at the Fold5 cover and inner sizes. Needs a display, so no --headless:
##
##     godot --path . --script res://tests/ui/shots_u5.gd -- --out=<folder>
##
## Files: u5_creature_<status>_<size>.png, u5_info_<part>_<size>.png, u5_mode_<size>.png.
## The new content is not in data/stats/ yet, so this uses the sim's test catalog and a
## fixture game whose levels hold every map feature.

const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")
const COVER: Vector2 = Vector2(1080.0, 2767.0)
const INNER: Vector2 = Vector2(1998.0, 2400.0)
const COVER_SAFE: Rect2 = Rect2(0.0, 96.0, 1080.0, 2500.0)
const INNER_SAFE: Rect2 = Rect2(0.0, 0.0, 1998.0, 2250.0)
## Status shots: name, creature, and what to set on it.
const STATUSES: Array[Array] = [
	["frightened", &"mossbud"], ["low", &"flitter"], ["hidden", &"mossbud"], ["out_of_reach", &"mossbud"],
	["awake", &"hootling"], ["napping", &"sleepyhead"], ["dug", &"burrowbelly"], ["grown", &"snowroller"],
]

var _out: String = ""
var _theme: Theme


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless" or _out.is_empty():
		printerr("shots_u5.gd needs a display and --out=<folder>.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	_theme = UiTheme.build()
	for pair: Array in [[COVER, COVER_SAFE, "cover"], [INNER, INNER_SAFE, "inner"]]:
		for status: Array in STATUSES:
			await _creature(pair[0], pair[1], pair[2], status[0], status[1])
		await _info(pair[0], pair[1], pair[2])
		await _mode(pair[0], pair[1], pair[2])
	quit(0)


func _seen(catalog: Catalog) -> Progress:
	var progress: Progress = Progress.new()
	for id: StringName in catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in catalog.enemy_ids():
		progress.mark_seen(id)
	return progress


func _host(size: Vector2) -> Array:
	var host: SubViewport = SubViewport.new()
	host.size = Vector2i(size)
	host.transparent_bg = false
	host.disable_3d = true
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	var holder: Control = Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.theme = _theme
	host.add_child(holder)
	var backdrop: Backdrop = Backdrop.new()
	backdrop.z_index = -10
	holder.add_child(backdrop)
	return [host, holder]


func _creature(size: Vector2, safe: Rect2, label: String, status: String, type: StringName) -> void:
	var catalog: Catalog = Cx.catalog()
	var b: Battle = Cx.battle(Sx.CLUSTER_GRID, [{"groups": [Sx.group(String(type), 1)]}], {"start_gold": 500})
	var made: Array = _host(size)
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(b, null, _seen(catalog), &"hollow_lanes")
	(made[1] as Control).add_child(screen)
	screen.apply_layout(size, safe)
	b.start_next_wave()
	for i: int in 60:
		b.step()
	var e: EnemyState = b.enemies[0]
	match status:
		"frightened":
			e.fright_pct = 25
			e.fright_ticks = 16
		"low":
			e.low_ticks = 50
		"hidden":
			e.hidden = true
		"out_of_reach":
			e.out_of_reach = true
		"awake":
			e.awake = true
		"napping":
			e.health = e.max_health / 2
			e.napped = true
			e.nap_ticks = 34
		"dug":
			e.dig_ticks = 30
			e.out_of_reach = true
		"grown":
			e.max_health += 40
			e.health += 40
	for i: int in 30:
		await process_frame
	screen.hint_banner.dismiss()
	screen.show_enemy(e.id)
	for i: int in 10:
		await process_frame
	# The sim is not stepped, so the flags set above stay as they are.
	screen.enemy_panel.refresh()
	for i: int in 20:
		await process_frame
	await _save(made[0], "u5_creature_%s_%s" % [status, label])
	made[0].queue_free()
	await process_frame


func _fixture_game() -> GameData:
	var game: GameData = GameData.new()
	game.catalog = Cx.catalog()
	var variants: Array[Array] = [["...T...", 2, ""], ["...X...", 3, ""], ["...v...", 4, ""], ["...P...", 2, "...P..."]]
	for i: int in variants.size():
		var grid: Array = Sx.LINE_GRID.duplicate()
		grid[variants[i][1]] = variants[i][0]
		if variants[i][2] != "":
			grid[5] = variants[i][2]
		var id: String = "fx_%d" % i
		game.levels[StringName(id)] = Sx.level(grid, [{"groups": [Sx.group("scamp", 1)]}], {"id": id}, game.catalog)
	return game


func _info(size: Vector2, safe: Rect2, label: String) -> void:
	var game: GameData = _fixture_game()
	var names: Dictionary = {}
	for id: StringName in game.catalog.tower_ids():
		names[id] = game.catalog.tower(id).name
	for id: StringName in game.catalog.enemy_ids():
		names[id] = game.catalog.enemy(id).name
	for part: Array in [["towers", &"towers"], ["creatures", &"creatures"], ["features", &"features"]]:
		var made: Array = _host(size)
		var info: InfoScreen = InfoScreen.new({"refund_pct": 70, "star2_lives": 15, "max_waves_running": 2, "run_stars": 12}, names, InfoContent.from_game(game))
		(made[1] as Control).add_child(info)
		info.apply_layout(size, safe)
		for i: int in 20:
			await process_frame
		for node: Node in info.find_children("*", "InfoArt", true, false):
			if (node as InfoArt).kind == part[1]:
				var art: Control = node as Control
				var top: float = art.global_position.y - info.scroll.global_position.y + float(info.scroll.scroll_vertical)
				info.scroll.scroll_vertical = maxi(0, int(top) - 260)
		for i: int in 20:
			await process_frame
		await _save(made[0], "u5_info_%s_%s" % [part[0], label])
		made[0].queue_free()
		await process_frame


func _mode(size: Vector2, safe: Rect2, label: String) -> void:
	var made: Array = _host(size)
	var mode: ModeScreen = ModeScreen.new()
	mode.set_runs(true, 14, 12, true, "Best today: Won with 14 lives left. Streak: 3 days.", "Regions 1 to 6")
	mode.set_continue("Continue", "Daily 2026-10-28. Wave 2 of 18.")
	(made[1] as Control).add_child(mode)
	mode.apply_layout(size, safe)
	for i: int in 20:
		await process_frame
	await _save(made[0], "u5_mode_%s" % label)
	made[0].queue_free()
	await process_frame


func _save(host: SubViewport, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = host.get_texture().get_image()
	var path: String = _out.path_join("%s.png" % name)
	print("%s %dx%d: %s" % [path, img.get_width(), img.get_height(), error_string(img.save_png(path))])
