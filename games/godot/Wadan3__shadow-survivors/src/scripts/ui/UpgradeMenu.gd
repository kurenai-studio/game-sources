extends Control

const UI_STYLE := preload("res://scripts/ui/UiStyles.gd")

signal upgrade_selected(id: String)

const UPGRADES := [
	{"id":"damage", "name":"OVERCHARGED CELLS", "desc":"+20% projectile damage", "icon":"DMG"},
	{"id":"speed", "name":"KINETIC SERVOS", "desc":"+15% movement speed", "icon":"SPD"},
	{"id":"fire_rate", "name":"PHASE CYCLER", "desc":"+20% fire rate", "icon":"RPM"},
	{"id":"projectile", "name":"FORKED PULSE", "desc":"+1 projectile", "icon":"+1"},
	{"id":"health", "name":"REINFORCED CORE", "desc":"+20 max health and healing", "icon":"HP"},
	{"id":"bullet_speed", "name":"RAIL ACCELERATOR", "desc":"+20% bullet speed", "icon":"VEL"},
	{"id":"dash", "name":"BLINK CAPACITOR", "desc":"-20% dash cooldown", "icon":"DSH"}
]

var cards: HBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.005, 0.012, 0.03, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 65
	column.offset_right = -65
	column.offset_top = 80
	column.offset_bottom = -75
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 32)
	add_child(column)
	var heading := UI_STYLE.label("SYSTEM EVOLUTION", 43, Color("79f6ff"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var sub := UI_STYLE.label("LEVEL UP  •  SELECT ONE AUGMENT", 15, Color("7192a8"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(sub)
	cards = HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 22)
	cards.custom_minimum_size.y = 330
	column.add_child(cards)

func present() -> void:
	for child in cards.get_children():
		child.queue_free()
	var options := UPGRADES.duplicate()
	options.shuffle()
	for i in 3:
		_add_card(options[i])
	visible = true

func _add_card(data: Dictionary) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(330, 310)
	button.text = "%s\n\n%s\n\n%s" % [data.icon, data.name, data.desc]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("dffbff"))
	button.add_theme_stylebox_override("normal", UI_STYLE.panel(Color(0.025, 0.055, 0.10, 0.98), Color(0.15, 0.65, 0.82, 0.5), 12))
	button.add_theme_stylebox_override("hover", UI_STYLE.panel(Color(0.04, 0.16, 0.20, 1), Color("5df4ff"), 12))
	button.add_theme_stylebox_override("pressed", UI_STYLE.panel(Color(0.04, 0.25, 0.28, 1), Color.WHITE, 12))
	button.pressed.connect(_select.bind(String(data.id)))
	button.mouse_entered.connect(AudioManager.play_ui)
	cards.add_child(button)

func _select(id: String) -> void:
	visible = false
	AudioManager.play_ui()
	upgrade_selected.emit(id)
