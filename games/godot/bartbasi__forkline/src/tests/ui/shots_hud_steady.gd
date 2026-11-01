# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Screenshots for step U7: the HUD at the Fold5 cover size in the build phase, with a wave
## running and in the last wave, and the card due labels. The map must sit in the same place
## in every picture. Needs a display, so no --headless:
##
##     godot --path . --script res://tests/ui/shots_hud_steady.gd -- --out=<folder>
##
## Files: hud_<cover|inner>_<ready|calling|last|card_due>.png.

const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const COVER: Vector2 = Vector2(1080.0, 2767.0)
const COVER_SAFE: Rect2 = Rect2(0.0, 96.0, 1080.0, 2500.0)
const INNER: Vector2 = Vector2(1998.0, 2400.0)
const INNER_SAFE: Rect2 = Rect2(0.0, 0.0, 1998.0, 2250.0)

var _out: String = ""
var _theme: Theme


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless" or _out.is_empty():
		printerr("shots_hud_steady.gd needs a display and --out=<folder>.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	_theme = UiTheme.build()
	for pair: Array in [[COVER, COVER_SAFE, "cover"], [INNER, INNER_SAFE, "inner"]]:
		await _shots(pair[0], pair[1], pair[2])
	quit(0)


func _seen(catalog: Catalog) -> Progress:
	var progress: Progress = Progress.new()
	for id: StringName in catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in catalog.enemy_ids():
		progress.mark_seen(id)
	return progress


func _settle(count: int = 20) -> void:
	for i: int in count:
		await process_frame


func _shots(size: Vector2, safe: Rect2, label: String) -> void:
	var waves: Array = [
		{"groups": [Sx.group("scamp", 4), Sx.group("flitter", 2, 2000)]},
		{"groups": [Sx.group("scamp", 6, 0, 1500)]},
	]
	var b: Battle = Tx.battle(Sx.CLUSTER_GRID, waves, {"start_gold": 500})
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
	await _settle(10)
	await _save(host, screen, "hud_%s_ready" % label)
	screen.hud.call_button.tapped.emit()
	await _settle()
	await _save(host, screen, "hud_%s_calling" % label)
	var guard: int = 0
	while b.next_wave_info()["refusal"] == &"still_spawning" and guard < 40000:
		b.step()
		guard += 1
	screen.hud.call_button.tapped.emit()
	await _settle()
	await _save(host, screen, "hud_%s_last" % label)
	screen.hud.show_call_label("Card due next", false, true)
	await _settle()
	await _save(host, screen, "hud_%s_card_due" % label)
	host.queue_free()
	await process_frame


func _save(host: SubViewport, screen: BattleScreen, name: String) -> void:
	await RenderingServer.frame_post_draw
	print("%s: hud %s, map scale %s at %s" % [name, screen.hud.get_global_rect(), screen.map_view.scale, screen.map_view.position])
	var img: Image = host.get_texture().get_image()
	var path: String = _out.path_join("%s.png" % name)
	print("%s %dx%d: %s" % [path, img.get_width(), img.get_height(), error_string(img.save_png(path))])
