class_name PauseMenu
extends Control
## In-run pause overlay with resume / settings / quit.

signal resume_requested
signal quit_requested

var _resume: Button
var _content: Control
var _settings: SettingsPanel
var _stats: Label


func _ready() -> void:
	UiKit.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.72)
	UiKit.full_rect(dim)
	add_child(dim)
	var center := CenterContainer.new()
	UiKit.full_rect(center)
	add_child(center)
	_content = center
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	v.add_child(UiKit.label("PAUSED", "TitleLabel", 56, HORIZONTAL_ALIGNMENT_CENTER))
	_stats = UiKit.label("", "MutedLabel", 18, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_stats)
	_resume = UiKit.button("RESUME")
	_resume.pressed.connect(func() -> void: resume_requested.emit())
	var settings := UiKit.button("SETTINGS")
	settings.pressed.connect(_open_settings)
	var quit := UiKit.button("QUIT_TO_MENU")
	quit.pressed.connect(func() -> void: quit_requested.emit())
	for b in [_resume, settings, quit]:
		v.add_child(b)
	UiKit.focus_chain([_resume, settings, quit])
	_settings = SettingsPanel.new()
	add_child(_settings)
	_settings.hide()
	_settings.closed.connect(func() -> void:
		_content.show()
		settings.grab_focus())
	hide()


func open(stats_line: String) -> void:
	_stats.text = stats_line
	_content.show()
	_settings.hide()
	show()
	UiKit.animate_in(_content, 0.0, 0.95)
	_resume.grab_focus.call_deferred()


func _open_settings() -> void:
	_content.hide()
	_settings.open()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _content.visible and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")):
		resume_requested.emit()
		get_viewport().set_input_as_handled()
