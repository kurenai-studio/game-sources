# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Screenshots for step U4: the build panel with ten towers and the panel of each new tower,
## at the Fold5 cover and inner sizes. Needs a display, so no --headless:
##
##     godot --path . --script res://tests/ui/shots_u4.gd -- --out=<folder>
##
## Files: u4_build10_<size>.png, u4_<tower>_<size>.png (tier 1, with the upgrade numbers),
## u4_<tower>_paths_<size>.png (tier 2, with the two paths) and u4_bramble_doze_<size>.png.

const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const COVER: Vector2 = Vector2(1080.0, 2767.0)
const INNER: Vector2 = Vector2(1998.0, 2400.0)
const COVER_SAFE: Rect2 = Rect2(0.0, 96.0, 1080.0, 2500.0)
const INNER_SAFE: Rect2 = Rect2(0.0, 0.0, 1998.0, 2250.0)
## The region each new tower belongs to, for the ground behind the panel.
const REGIONS: Dictionary = {
	&"bramble_cottage": &"hollow_lanes", &"scarecrow": &"russet_orchards",
	&"snow_fort": &"frostpine_ridge", &"moth_lantern": &"starglen",
}


## A tower panel whose tower dozes, until S10b gives the sim a doze time.
class DozyPanel extends TowerPanel:
	func _numbers() -> Dictionary:
		var numbers: Dictionary = super()
		numbers["doze_ms"] = 2400
		return numbers


var _out: String = ""
var _theme: Theme


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless" or _out.is_empty():
		printerr("shots_u4.gd needs a display and --out=<folder>.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	_theme = UiTheme.build()
	for pair: Array in [[COVER, COVER_SAFE, "cover"], [INNER, INNER_SAFE, "inner"]]:
		await _build_ten(pair[0], pair[1], pair[2])
		for type: StringName in REGIONS:
			await _tower(pair[0], pair[1], pair[2], type, 1)
			await _tower(pair[0], pair[1], pair[2], type, 2)
		await _doze(pair[0], pair[1], pair[2])
	quit(0)


func _seen() -> Progress:
	var progress: Progress = Progress.new()
	var catalog: Catalog = Tx.catalog()
	for id: StringName in catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in catalog.enemy_ids():
		progress.mark_seen(id)
	return progress


func _battle(gold: int) -> Battle:
	return Tx.battle(Sx.CLUSTER_GRID, [{"groups": [Sx.group("scamp", 6), Sx.group("flitter", 3, 2000)]}], {"start_gold": gold})


func _host(size: Vector2, safe: Rect2, b: Battle, region: StringName, panel: Control = null) -> Array:
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
	screen.setup(b, null, _seen(), region)
	holder.add_child(screen)
	screen.apply_layout(size, safe)
	for i: int in 40:
		await process_frame
	screen.hint_banner.dismiss()
	return [host, screen]


func _build_ten(size: Vector2, safe: Rect2, label: String) -> void:
	var b: Battle = _battle(105)
	var made: Array = await _host(size, safe, b, &"hollow_lanes")
	var screen: BattleScreen = made[1]
	screen.tap_at(b.level.spots[0])
	screen.build_panel.select_tower(&"scarecrow")
	for i: int in 40:
		await process_frame
	await _save(made[0], "u4_build10_%s" % label)
	made[0].queue_free()
	await process_frame


func _tower(size: Vector2, safe: Rect2, label: String, type: StringName, tier: int) -> void:
	var b: Battle = _battle(5000)
	var made: Array = await _host(size, safe, b, REGIONS[type])
	var screen: BattleScreen = made[1]
	var cell: Vector2i = b.level.spots[0]
	Tx.build(b, cell, type, tier)
	if tier == 2:
		Tx.build(b, b.level.spots[3], &"sling_post")
	screen.tap_at(cell)
	for i: int in 40:
		await process_frame
	var name: String = String(type).replace("_cottage", "").replace("_fort", "").replace("_lantern", "")
	await _save(made[0], "u4_%s%s_%s" % [name, "_paths" if tier == 2 else "", label])
	made[0].queue_free()
	await process_frame


## The doze line, with a made up time: the sim gives no doze time until S10b.
func _doze(size: Vector2, safe: Rect2, label: String) -> void:
	var b: Battle = _battle(5000)
	var made: Array = await _host(size, safe, b, &"frostpine_ridge")
	var screen: BattleScreen = made[1]
	var cell: Vector2i = b.level.spots[0]
	Tx.build(b, cell, &"snow_fort")
	var dozy: DozyPanel = DozyPanel.new()
	dozy.setup(b)
	dozy.set_wide(size == COVER)
	(screen.get_parent() as Control).add_child(dozy)
	dozy.show_tower(cell)
	dozy.position = Vector2(16.0, 1300.0) if size == COVER else Vector2(1090.0, 446.0)
	dozy.size = Vector2(1048.0 if size == COVER else 892.0, 100.0)
	for i: int in 40:
		await process_frame
	await _save(made[0], "u4_snowfort_doze_%s" % label)
	made[0].queue_free()
	await process_frame


func _save(host: SubViewport, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = host.get_texture().get_image()
	var path: String = _out.path_join("%s.png" % name)
	print("%s %dx%d: %s" % [path, img.get_width(), img.get_height(), error_string(img.save_png(path))])
