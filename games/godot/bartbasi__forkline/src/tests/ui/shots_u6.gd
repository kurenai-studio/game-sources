# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Screenshots for step U6: Pause with Restart, the Restart question, the battle HUD with the
## sound button on and off, and Settings with its two sound rows,
## at the Fold5 cover and inner sizes. Needs a display, so no --headless:
##
##     godot --path . --script res://tests/ui/shots_u6.gd -- --out=<folder>
##
## Files: ui_req_<part>_<size>.png.

const BattleFixtures: GDScript = preload("res://tests/ui/battle_fixtures.gd")
const COVER: Vector2 = Vector2(1080.0, 2767.0)
const INNER: Vector2 = Vector2(1998.0, 2400.0)
const COVER_SAFE: Rect2 = Rect2(0.0, 96.0, 1080.0, 2500.0)
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
		printerr("shots_u6.gd needs a display and --out=<folder>.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	_theme = UiTheme.build()
	for pair: Array in [[COVER, COVER_SAFE, "cover"], [INNER, INNER_SAFE, "inner"]]:
		await _battle(pair[0], pair[1], pair[2])
		await _settings(pair[0], pair[1], pair[2])
	quit(0)


func _seen(catalog: Catalog) -> Progress:
	var progress: Progress = Progress.new()
	for id: StringName in catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in catalog.enemy_ids():
		progress.mark_seen(id)
	progress.mark_seen(&"r1_l1")
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


func _settle(count: int = 20) -> void:
	for i: int in count:
		await process_frame


func _battle(size: Vector2, safe: Rect2, label: String) -> void:
	var b: Battle = BattleFixtures.battle(&"r1_l1")
	var made: Array = _host(size)
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(b, null, _seen(b.catalog))
	(made[1] as Control).add_child(screen)
	screen.apply_layout(size, safe)
	await _settle(30)
	screen.hint_banner.dismiss()
	await _settle(10)
	screen.set_sound_state(true)
	await _settle(6)
	await _save(made[0], "ui_req_hud_sound_on_%s" % label)
	screen.set_sound_state(false)
	await _settle(6)
	await _save(made[0], "ui_req_hud_sound_off_%s" % label)
	screen.set_sound_state(true)
	screen.pause()
	await _settle(20)
	await _save(made[0], "ui_req_pause_%s" % label)
	var pause: PausePanel = screen._pause_panel
	pause.restart_button.tapped.emit()
	await _settle(20)
	await _save(made[0], "ui_req_restart_question_%s" % label)
	made[0].queue_free()
	await process_frame


func _settings(size: Vector2, safe: Rect2, label: String) -> void:
	var made: Array = _host(size)
	var panel: SettingsPanel = SettingsPanel.new(true, false)
	(made[1] as Control).add_child(panel)
	panel.apply_layout(size, safe)
	await _settle(20)
	await _save(made[0], "ui_req_settings_%s" % label)
	made[0].queue_free()
	await process_frame


func _save(host: SubViewport, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = host.get_texture().get_image()
	var path: String = _out.path_join("%s.png" % name)
	print("%s %dx%d: %s" % [path, img.get_width(), img.get_height(), error_string(img.save_png(path))])
