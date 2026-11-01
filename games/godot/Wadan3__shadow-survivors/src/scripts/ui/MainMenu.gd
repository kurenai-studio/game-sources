extends Control

const UI_STYLE := preload("res://scripts/ui/UiStyles.gd")

var title_label: Label
var how_panel: PanelContainer
var time: float = 0.0

func _ready() -> void:
	get_tree().paused = false
	_build_ui()

func _process(delta: float) -> void:
	time += delta
	if title_label:
		title_label.position.y = sin(time * 1.5) * 4.0

func _build_ui() -> void:
	var backdrop := preload("res://scripts/ui/MenuBackdrop.gd").new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var content := MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 105)
	content.add_theme_constant_override("margin_top", 92)
	content.add_theme_constant_override("margin_bottom", 72)
	add_child(content)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	content.add_child(column)

	title_label = UI_STYLE.label("SHADOW\nSURVIVORS", 66, Color("84f7ff"))
	title_label.custom_minimum_size = Vector2(530, 175)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_STYLE.title(title_label, 66)
	column.add_child(title_label)
	var subtitle := UI_STYLE.label("OUTRUN THE DARK  •  OUTGUN THE SWARM", 15, Color("708ca5"))
	subtitle.custom_minimum_size.y = 42
	column.add_child(subtitle)

	for item in [["PLAY", _play], ["HOW TO PLAY", _show_how], ["QUIT", _quit]]:
		var button := Button.new()
		button.text = item[0]
		UI_STYLE.style_button(button)
		button.pressed.connect(item[1])
		button.mouse_entered.connect(AudioManager.play_ui)
		column.add_child(button)

	var stats := UI_STYLE.label("HIGH SCORE  %07d    •    BEST WAVE  %02d" % [GameManager.high_score, GameManager.best_wave], 14, Color("5e849b"))
	stats.custom_minimum_size.y = 50
	stats.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	column.add_child(stats)

	_build_how_panel()

func _build_how_panel() -> void:
	how_panel = PanelContainer.new()
	how_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	how_panel.position = Vector2(-265, -245)
	how_panel.size = Vector2(530, 490)
	how_panel.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.018, 0.035, 0.075, 0.985), Color("32dfff"), 15))
	how_panel.visible = false
	add_child(how_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	how_panel.add_child(column)
	var heading := UI_STYLE.label("HOW TO PLAY", 32, Color("7df6ff"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var lines := [
		["WASD / ARROW KEYS", "MOVE"], ["MOUSE", "AIM"], ["LEFT CLICK", "FIRE PULSE BLASTER"],
		["SPACE", "DASH"], ["ESC", "PAUSE"]
	]
	for line in lines:
		var row := HBoxContainer.new()
		var key := UI_STYLE.label(line[0], 17, Color("f4d765"))
		key.custom_minimum_size.x = 245
		var action := UI_STYLE.label(line[1], 16)
		row.add_child(key)
		row.add_child(action)
		column.add_child(row)
	var hint := UI_STYLE.label("Collect cores, choose upgrades, and survive every fifth-wave boss.", 15, Color("829db0"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.y = 52
	column.add_child(hint)
	var close := Button.new()
	close.text = "BACK"
	UI_STYLE.style_button(close)
	close.pressed.connect(_hide_how)
	column.add_child(close)

func _play() -> void:
	AudioManager.play_ui()
	get_tree().change_scene_to_file("res://scenes/main/Game.tscn")

func _show_how() -> void:
	AudioManager.play_ui()
	how_panel.visible = true

func _hide_how() -> void:
	AudioManager.play_ui()
	how_panel.visible = false

func _quit() -> void:
	get_tree().quit()
