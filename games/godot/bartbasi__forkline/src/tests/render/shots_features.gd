# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Screenshots of the sim's fixture maps with map features (step V3) at the Fold5 cover and
## inner sizes, mid-wave with walkers on bridges, in tunnels and on twin steps, and in the build
## phase with route lines. Needs a display, so no --headless:
##
##     godot --path . --script res://tests/render/shots_features.gd -- --out=<folder>
##
## Optional: --only=tunnel|bridge|slide|stump|all (default all), --size=cover or --size=inner.
## Prints the draw calls of each frame it saves, and for a region 1 level for comparison.

const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")

## Name, grid, region (&"" for a run map), a gate to place (or (-1, -1)), and the states to wait for.
const CASES: Array = [
	["tunnel", "TUNNEL_GRID", &"hollow_lanes", Vector2i(-1, -1)],
	["bridge", "BRIDGE_GATE_GRID", &"russet_orchards", Vector2i(4, 1)],
	["slide", "SLIDE_DOWN_GRID", &"frostpine_ridge", Vector2i(-1, -1)],
	["stump", "STUMP_GRID", &"starglen", Vector2i(-1, -1)],
	["all", "FEATURE_GRID", &"", Vector2i(-1, -1)],
]

var _out: String = ""
var _only: String = ""
var _size: String = ""
var _theme: Theme


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
		elif arg.begins_with("--size="):
			_size = arg.trim_prefix("--size=")
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless" or _out.is_empty():
		printerr("shots_features.gd needs a display and --out=<folder>.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	_theme = UiTheme.build()
	for item: Array in CASES:
		if not _only.is_empty() and _only != item[0]:
			continue
		for size: Vector2i in [Fx.COVER, Fx.INNER]:
			var label: String = "cover" if size == Fx.COVER else "inner"
			if _size.is_empty() or _size == label:
				await _shoot(item, size, label)
	if _only.is_empty() or _only == "baseline":
		await _baseline()
	quit(0)


func _host(size: Vector2i) -> SubViewport:
	var host: SubViewport = SubViewport.new()
	host.size = size
	host.transparent_bg = false
	host.disable_3d = true
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	var screen: Control = Control.new()
	screen.size = Vector2(size)
	screen.theme = _theme
	host.add_child(screen)
	screen.add_child(Backdrop.new())
	return host


func _battle(grid: Array, gate: Vector2i) -> Battle:
	var stats: Catalog = Sx.catalog()
	var groups: Array = [Sx.group("scamp", 14, 0, 650), Sx.group("flitter", 2, 3000, 1500)]
	if "".join(PackedStringArray(grid)).contains("2"):
		groups.append(Sx.group("scamp", 10, 300, 650, 2))
	var data: Dictionary = Sx.level_data(grid, [{"groups": groups}], {"gates": 1 if "".join(PackedStringArray(grid)).contains("G") else 0, "start_gold": 5000, "strength": 400})
	var b: Battle = Battle.create(LevelData.from_data(data, stats), stats, false, [])
	for i: int in b.level.spots.size():
		b.place_tower(b.level.spots[i], &"sling_post" if i % 2 == 0 else &"pumpkin_catapult")
	if gate.x >= 0:
		b.place_gate(gate)
	return b


func _rect(size: Vector2i, rows: int) -> Rect2:
	if size.y < int(1.5 * float(size.x)):
		var h: float = float(size.y) - 120.0
		return Rect2(40, 60, h * 7.0 / float(rows), h)
	var w: float = float(size.x)
	return Rect2(0, 236, w, w / 7.0 * float(rows))


func _shoot(item: Array, size: Vector2i, label: String) -> void:
	var grid: Array = Sx.get_script_constant_map()[item[1]]
	var host: SubViewport = _host(size)
	var b: Battle = _battle(grid, item[3])
	var view: MapView = MapView.new()
	host.get_child(0).add_child(view)
	view.setup(b, item[2])
	view.fit(_rect(size, grid.size()))
	var note: Label = Label.new()
	host.get_child(0).add_child(note)
	note.position = Vector2(40.0, 90.0) if size == Fx.COVER else Vector2(_rect(size, grid.size()).end.x + 60.0, 80.0)
	# The build phase: route lines, the gate, a selection.
	view.show_routes(b.routes(b.closed_cells()))
	if not b.level.spots.is_empty():
		view.show_selection(b.level.spots[0])
	for i: int in 20:
		await process_frame
		view.sync(0.0)
	note.text = "%s   %s ground   build phase" % [item[0], view.ground_id()]
	await _save(host, "v3_%s_%s_build" % [item[0], label])
	# Mid-wave: step to the moment with the most states showing at once.
	view.show_routes([])
	view.show_selection(Vector2i(-1, -1))
	b.start_next_wave()
	var best: int = -1
	var best_tick: int = 0
	var states: Dictionary = {}
	var snapshot: String = JSON.stringify(b.to_data())
	var tick: int = 0
	while b.phase == Battle.Phase.WAVE and tick < 2400:
		b.step()
		view.play_events(b.take_events())
		view.sync(1.0)
		states.clear()
		for e: EnemyState in b.enemies:
			var layer: StringName = view.layer_of(e.id)
			var cell: Vector2i = Sim.cell_of(e.pos)
			var feature: LevelData.Feature = b.level.feature_at(cell)
			if layer == &"under" and feature == LevelData.Feature.BRIDGE:
				states["under deck"] = true
			elif layer == &"top" and feature == LevelData.Feature.BRIDGE:
				states["on deck"] = true
			elif layer == &"under" or (layer == &"hidden" and feature == LevelData.Feature.TUNNEL):
				states["in tunnel"] = true
				var a: float = view.creature_alpha(e.id)
				if a > 0.0 and a < 1.0:
					states["fading"] = true
			elif layer == &"hidden":
				states["twin step"] = true
		if states.size() > best:
			best = states.size()
			best_tick = tick
			snapshot = JSON.stringify(b.to_data())
		tick += 1
		if best >= 4 or (best >= 3 and item[0] != "all") or (best >= 2 and item[0] in ["tunnel", "bridge"] and tick > 600):
			break
	var restored: Battle = Battle.from_data(JSON.parse_string(snapshot), b.catalog)
	# Show that moment: a fresh view on the restored battle, drawn after a few frames.
	view.get_parent().remove_child(view)
	view.free()
	view = MapView.new()
	host.get_child(0).add_child(view)
	view.setup(restored, item[2])
	view.fit(_rect(size, grid.size()))
	for i: int in 20:
		await process_frame
		view.sync(0.0)
	view.sync(0.0)
	var counts: Dictionary = {}
	for e: EnemyState in restored.enemies:
		var l: String = String(view.layer_of(e.id))
		counts[l] = int(counts.get(l, 0)) + 1
	note.text = "%s   tick %d   %s" % [item[0], best_tick, JSON.stringify(counts)]
	await _save(host, "v3_%s_%s_wave" % [item[0], label])
	print("   wave moment: tick %d, layers %s" % [best_tick, counts])
	host.queue_free()
	await process_frame


func _save(host: SubViewport, name: String) -> void:
	await RenderingServer.frame_post_draw
	var calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var img: Image = host.get_texture().get_image()
	var path: String = _out.path_join("%s.png" % name)
	print("%s %dx%d draw_calls=%d: %s" % [path, img.get_width(), img.get_height(), calls, error_string(img.save_png(path))])


## Draw calls on a region 1 level with the same kind of defense, mid-wave, for comparison.
func _baseline() -> void:
	for size: Vector2i in [Fx.COVER, Fx.INNER]:
		var label: String = "cover" if size == Fx.COVER else "inner"
		var host: SubViewport = _host(size)
		var b: Battle = Fx.battle("r1_l4")
		Fx.defend(b)
		var view: MapView = MapView.new()
		host.get_child(0).add_child(view)
		view.setup(b)
		view.fit(_rect(size, b.level.rows))
		view.show_routes(b.routes(b.closed_cells()))
		for i: int in 10:
			await process_frame
			view.sync(0.0)
		await _save(host, "v3_baseline_r1_l4_%s_build" % label)
		view.show_routes([])
		Fx.fast_forward(b, 2)
		b.start_next_wave()
		for i: int in 500:
			b.step()
			view.play_events(b.take_events())
			view.sync(1.0)
			if i % 8 == 0:
				await process_frame
		await _save(host, "v3_baseline_r1_l4_%s_wave" % label)
		host.queue_free()
		await process_frame
