extends Control

const UI_STYLE := preload("res://scripts/ui/UiStyles.gd")

signal restart_requested
signal main_menu_requested

var stats_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.0, 0.025, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-275, -290)
	panel.size = Vector2(550, 580)
	panel.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.06, 0.015, 0.06, 0.98), Color("ff3f91"), 16))
	add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 13)
	panel.add_child(column)
	var heading := UI_STYLE.label("GAME OVER", 48, Color("ff5ba8"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.custom_minimum_size.y = 95
	UI_STYLE.title(heading, 48, Color("ff5ba8"))
	column.add_child(heading)
	stats_label = UI_STYLE.label("", 19, Color("d9e4ee"))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.custom_minimum_size.y = 185
	column.add_child(stats_label)
	_add_button(column, "RESTART", func(): restart_requested.emit())
	_add_button(column, "MAIN MENU", func(): main_menu_requested.emit())
	_add_button(column, "QUIT", func(): get_tree().quit())

func show_results() -> void:
	stats_label.text = "FINAL SCORE     %07d\nWAVE REACHED    %02d\nENEMIES DEFEATED  %d\nSURVIVAL TIME   %s\n\nHIGH SCORE      %07d" % [GameManager.score, GameManager.wave, GameManager.kills, GameManager.format_time(GameManager.survival_time), GameManager.high_score]
	visible = true

func _add_button(parent: Control, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	UI_STYLE.style_button(button, Color("ff4fa3"))
	button.pressed.connect(action)
	button.pressed.connect(AudioManager.play_ui)
	parent.add_child(button)
