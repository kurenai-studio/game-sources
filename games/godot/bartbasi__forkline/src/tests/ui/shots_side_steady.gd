# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Screenshots for step U6b: the landscape layout with a tower panel (a tier 2 Snow Fort, whose
## panel is tall and used to widen the side column) closed and open, at the Fold5 inner size
## and at a narrow landscape window. The map must look the same in both. Needs a display, so
## no --headless:
##
##     godot --path . --script res://tests/ui/shots_side_steady.gd -- --out=<folder>
##
## Files: side_<closed|open>_<inner|narrow>.png.

const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const INNER: Vector2 = Vector2(1998.0, 2400.0)
const INNER_SAFE: Rect2 = Rect2(0.0, 0.0, 1998.0, 2250.0)
const NARROW: Vector2 = Vector2(1300.0, 1700.0)
const NARROW_SAFE: Rect2 = Rect2(0.0, 0.0, 1300.0, 1600.0)

var _out: String = ""
var _theme: Theme


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless" or _out.is_empty():
		printerr("shots_side_steady.gd needs a display and --out=<folder>.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	_theme = UiTheme.build()
	for pair: Array in [[INNER, INNER_SAFE, "inner"], [NARROW, NARROW_SAFE, "narrow"]]:
		await _shots(pair[0], pair[1], pair[2])
	quit(0)


func _seen(catalog: Catalog) -> Progress:
	var progress: Progress = Progress.new()
	for id: StringName in catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in catalog.enemy_ids():
		progress.mark_seen(id)
	return progress


func _settle(count: int = 30) -> void:
	for i: int in count:
		await process_frame


func _shots(size: Vector2, safe: Rect2, label: String) -> void:
	var waves: Array = [{"groups": [Sx.group("scamp", 6), Sx.group("flitter", 3, 2000)]}]
	var b: Battle = Tx.battle(Sx.CLUSTER_GRID, waves, {"start_gold": 5000})
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
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(b, null, _seen(b.catalog), &"hollow_lanes")
	holder.add_child(screen)
	screen.apply_layout(size, safe)
	await _settle()
	screen.hint_banner.dismiss()
	var cell: Vector2i = b.level.spots[0]
	Tx.build(b, cell, &"snow_fort", 2)
	await _settle(10)
	await _save(host, "side_closed_%s" % label)
	screen.tap_at(cell)
	await _settle()
	print("%s: map scale %s at %s, side column %.0f wide" % [label, screen.map_view.scale, screen.map_view.position, screen._side.size.x])
	await _save(host, "side_open_%s" % label)
	host.queue_free()
	await process_frame


func _save(host: SubViewport, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = host.get_texture().get_image()
	var path: String = _out.path_join("%s.png" % name)
	print("%s %dx%d: %s" % [path, img.get_width(), img.get_height(), error_string(img.save_png(path))])
