class_name PauseMenu
extends CanvasLayer
## Esc / P / Start during a run: Resume, Settings, Restart, Main Menu.
## Pauses the tree while open. Esc and B go back one step: settings to
## the buttons, the buttons to the game.

signal resumed
signal restart_requested
signal main_menu_requested
signal skip_tutorial_requested

const LAYER := 20
const PAUSE_ACTION := &"pause"
## Space and A are both ui_accept and shift_form; wait for the Resume
## press to expire before gameplay sees input again (see LevelUpMenu).
const RESUME_DELAY_PHYSICS_FRAMES := 2

var _buttons: VBoxContainer
var _settings: SettingsPanel
var _resume_button: Button
var _skip_tutorial_button: Button


## True when a pause menu may open: the run is live and nothing else
## (a level-up) holds the pause.
static func can_open(run_over: bool, tree_paused: bool) -> bool:
	return not run_over and not tree_paused


func _init() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func open() -> void:
	visible = true
	_show_buttons()
	if is_inside_tree():
		get_tree().paused = true


## Shows the Skip Tutorial button while the guided first run is on.
func set_tutorial_active(active: bool) -> void:
	_skip_tutorial_button.visible = active


func is_skip_tutorial_shown() -> bool:
	return _skip_tutorial_button.visible


func is_settings_shown() -> bool:
	return _settings.visible


func show_settings() -> void:
	_buttons.visible = false
	_settings.visible = true
	_settings.focus_first()


## Esc / B: settings back to the buttons, the buttons back to the game.
func go_back() -> void:
	if is_settings_shown():
		_settings.go_back()
	else:
		resume()


func resume() -> void:
	if not visible:
		return
	visible = false
	resumed.emit()
	if not is_inside_tree():
		return
	for frame in RESUME_DELAY_PHYSICS_FRAMES:
		await get_tree().physics_frame
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(PAUSE_ACTION):
		get_viewport().set_input_as_handled()
		go_back()


func _show_buttons() -> void:
	_settings.visible = false
	_buttons.visible = true
	if _resume_button.is_inside_tree():
		UiKit.grab_focus_quietly(_resume_button)


func _build() -> void:
	var stack := VBoxContainer.new()
	_buttons = UiKit.column()
	_buttons.add_child(UiKit.label("Paused", UiKit.HEADER_FONT_SIZE, UiKit.ACCENT_COLOR))
	_resume_button = _add_button("Resume", resume)
	_skip_tutorial_button = _add_button("Skip Tutorial", _skip_tutorial)
	_skip_tutorial_button.visible = false
	_add_button("Settings", show_settings)
	_add_button("Restart", func() -> void: restart_requested.emit())
	_add_button("Main Menu", func() -> void: main_menu_requested.emit())
	stack.add_child(_buttons)
	_settings = SettingsPanel.new()
	_settings.back_pressed.connect(_show_buttons)
	stack.add_child(_settings)
	add_child(UiKit.dimmed_center(UiKit.panel(stack)))


func _skip_tutorial() -> void:
	set_tutorial_active(false)
	skip_tutorial_requested.emit()
	resume()


func _add_button(text: String, on_press: Callable) -> Button:
	var button := UiKit.button(text)
	button.pressed.connect(on_press)
	_buttons.add_child(button)
	return button
