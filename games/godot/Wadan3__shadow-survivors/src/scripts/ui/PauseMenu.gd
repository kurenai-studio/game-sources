extends Control

const UI_STYLE := preload("res://scripts/ui/UiStyles.gd")

signal resume_requested
signal restart_requested
signal main_menu_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.005, 0.008, 0.02, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-190, -230)
	panel.size = Vector2(380, 460)
	panel.add_theme_stylebox_override("panel", UI_STYLE.panel())
	add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var heading := UI_STYLE.label("PAUSED", 42, Color("78efff"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.custom_minimum_size.y = 95
	column.add_child(heading)
	_add_button(column, "RESUME", func(): resume_requested.emit())
	_add_button(column, "RESTART", func(): restart_requested.emit())
	_add_button(column, "MAIN MENU", func(): main_menu_requested.emit())
	_add_button(column, "QUIT", func(): get_tree().quit())

func _add_button(parent: Control, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	UI_STYLE.style_button(button)
	button.pressed.connect(action)
	button.pressed.connect(AudioManager.play_ui)
	parent.add_child(button)
