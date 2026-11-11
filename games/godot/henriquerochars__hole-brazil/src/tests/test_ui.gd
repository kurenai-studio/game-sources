extends SceneTree
## UI state, pointer activation, saved settings, and responsive scroll regressions.
const MainScene = preload("res://scenes/main.tscn")
var main: Node
var failures := 0
var checks := 0
var had_settings := false
var saved_settings := PackedByteArray()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	had_settings = FileAccess.file_exists("user://settings.cfg")
	if had_settings:
		saved_settings = FileAccess.get_file_as_bytes("user://settings.cfg")
	var config := ConfigFile.new()
	config.set_value("game", "best_score", [])
	config.set_value("game", "candidate", {"bad": true})
	config.set_value("audio", "muted", "not a bool")
	config.save("user://settings.cfg")
	main = MainScene.instantiate()
	root.add_child(main)
	await _settle()
	_check(main.best_score == 0 and main.selected_candidate == 0 and not main.muted, "Malformed settings recover to defaults")
	main.free()
	await _settle()
	config.set_value("game", "best_score", 1234)
	config.set_value("game", "candidate", 1)
	config.set_value("audio", "muted", true)
	config.save("user://settings.cfg")
	main = MainScene.instantiate()
	root.add_child(main)
	await _settle()
	_check(main.best_score == 1234 and main.selected_candidate == 1, "Best score and candidate load")
	_check(main.muted and not main.gameplay.sound_enabled, "Muted startup disables gameplay audio")
	var play_button := _button(main.ui_root, "ABRIR O BURACO")
	_check(play_button != null, "Play button exists")
	if play_button != null:
		await _touch_button(play_button)
	_check(main.screen == "game" and main.gameplay.active, "Touch release activates native play button")
	_check(not main.gameplay.sound_enabled, "Mute persists into new game")
	main.show_pause()
	await _settle()
	_check(main.screen == "pause" and main.gameplay.paused, "Pause screen stops gameplay")
	main._toggle_audio()
	await _settle()
	_check(not main.muted and main.gameplay.sound_enabled and main.screen == "pause", "Pause audio toggle updates both engines and preserves screen")
	main._toggle_audio()
	main.start_game(2)
	await _settle()
	_check(main.muted and not main.gameplay.sound_enabled and main.gameplay.candidate == 2, "Muted replay applies new candidate")
	main.show_selection()
	await _settle()
	_check(main.screen == "selection" and main.gameplay.paused, "Selection pauses active simulation")
	for dimensions in [Vector2i(360, 640), Vector2i(960, 540), Vector2i(540, 960)]:
		root.size = dimensions
		main.show_menu()
		await _settle()
		await _check_scroll_target("ABRIR O BURACO", dimensions)
		main.show_selection()
		await _settle()
		await _check_scroll_target("CONFIRMA", dimensions)
		main.show_results({"score": 100, "level": 2, "radius": 42.0, "absorbed": 12})
		await _settle()
		await _check_scroll_target("NOVA ELEIÇÃO", dimensions)
	main.free()
	await _settle()
	if had_settings:
		var restore := FileAccess.open("user://settings.cfg", FileAccess.WRITE)
		restore.store_buffer(saved_settings)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.cfg"))
	print("UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _check_scroll_target(prefix: String, dimensions: Vector2i) -> void:
	var target := _button(main.ui_root, prefix)
	var scroll := _scroll(main.ui_root)
	_check(target != null and scroll != null, "Responsive page exposes action and scroll container")
	if target == null or scroll == null:
		return
	scroll.ensure_control_visible(target)
	await _settle()
	var viewport_rect := root.get_visible_rect()
	var button_rect := target.get_global_rect()
	_check(viewport_rect.encloses(button_rect), "%s is reachable at %s" % [prefix, dimensions])
	_check(button_rect.size.y >= 48.0, "%s has a 48px logical touch target" % prefix)

func _touch_button(button: Button) -> void:
	var scroll := _scroll(main.ui_root)
	if scroll != null:
		scroll.ensure_control_visible(button)
	await _settle()
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = button.get_global_rect().get_center()
	touch.pressed = true
	Input.parse_input_event(touch)
	await process_frame
	touch = touch.duplicate()
	touch.pressed = false
	Input.parse_input_event(touch)
	await _settle()

func _button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):
		return node
	for child in node.get_children():
		var result := _button(child, prefix)
		if result != null:
			return result
	return null

func _scroll(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node
	for child in node.get_children():
		var result := _scroll(child)
		if result != null:
			return result
	return null

func _settle() -> void:
	for _i in range(5):
		await process_frame

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
