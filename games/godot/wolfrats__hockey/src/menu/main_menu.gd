extends Control

var Joy: VirtualJoystick
var Shoot: TouchScreenButton
var Swap: TouchScreenButton
var Slash: TouchScreenButton
var Pass: TouchScreenButton
var Grab: TouchScreenButton
var Back: TouchScreenButton
var Holder: Control
var BackHolder: Control

func _ready() -> void:
	Joy = VirtualJoystick.new()
	Joy.action_left = &"skate_left"
	Joy.action_right = &"skate_right"
	Joy.action_up = &"skate_up"
	Joy.action_down = &"skate_down"
	Joy.joystick_mode = VirtualJoystick.JOYSTICK_DYNAMIC
	Joy.visibility_mode = VirtualJoystick.VISIBILITY_ALWAYS
	Joy.joystick_size = 150.0
	Joy.tip_size = 60.0
	Joy.deadzone_ratio = 0.2
	Joy.custom_minimum_size = Vector2(100, 100)
	Shoot = TouchScreenButton.new()
	Shoot.action = &"shoot"
	Shoot.texture_normal = preload("res://sprites/shoot-button.svg")
	Swap = TouchScreenButton.new()
	Swap.action = &"swap"
	Swap.texture_normal = preload("res://sprites/swap-button.svg")
	Slash = TouchScreenButton.new()
	Slash.action = &"check"
	Slash.texture_normal = preload("res://sprites/slash-button.svg")
	Pass = TouchScreenButton.new()
	Pass.action = &"pass"
	Pass.texture_normal = preload("res://sprites/pass-button.svg")
	Grab = TouchScreenButton.new()
	Grab.action = &"grab"
	Grab.texture_normal = preload("res://sprites/grab-button.svg")
	Back = TouchScreenButton.new()
	Back.action = &"ui_cancel"
	Back.texture_normal = preload("res://sprites/red-button.svg") # Using red-button.svg for Back

	Holder = Control.new()
	Holder.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 50)
	Holder.add_child(Swap)
	Holder.add_child(Shoot)
	Holder.add_child(Slash)
	Holder.add_child(Pass)
	Holder.add_child(Grab)

	BackHolder = Control.new()
	BackHolder.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 50)
	BackHolder.add_child(Back)

	Swap.position = Vector2(-100, -300)
	Swap.scale = Vector2.ONE*(128.0/320.0)
	Shoot.position = Vector2(-100, -100)
	Shoot.scale = Vector2.ONE*(128.0/320.0)
	Slash.position = Vector2(-175, -200)
	Slash.scale = Vector2.ONE*(128.0/320.0)
	Pass.position = Vector2(-25, -200)
	Pass.scale = Vector2.ONE*(128.0/320.0)
	Grab.position = Vector2(-25, -300)
	Grab.scale = Vector2.ONE*(128.0/320.0)

	Back.position = Vector2(20, 20)
	Back.scale = Vector2.ONE*(128.0/320.0)
	%JoystickToggle.set_pressed_no_signal(Globals.use_onscreen_controls)
	$CenterContainer/VBoxContainer/Practice.grab_focus()
	if not Globals.menu_opened:
		Globals.menu_opened = true
		if Globals.use_onscreen_controls:
			_on_joystick_toggled(true)



func _on_practice_pressed() -> void:
	get_tree().change_scene_to_file("res://objects/environment/practice_rink.tscn")


func _on_match_pressed() -> void:
		get_tree().change_scene_to_file("res://menu/team_setup.tscn")

func _on_setup_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/player_setup.tscn")

func _on_joystick_toggled(toggled_on: bool) -> void:
	if Globals.get_node_or_null("Holder") == null && toggled_on:
		Joy.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 150)
		Holder.name = "Holder"
		Globals.add_child(Holder)
		BackHolder.name = "BackHolder"
		Globals.add_child(BackHolder)
		Joy.name = "Joy"
		Globals.add_child(Joy)
	elif not toggled_on:
		if Globals.has_node("Holder"):
			Globals.remove_child(Globals.get_node("Holder"))
		if Globals.has_node("BackHolder"):
			Globals.remove_child(Globals.get_node("BackHolder"))
		if Globals.has_node("Joy"):
			Globals.remove_child(Globals.get_node("Joy"))
	Globals.use_onscreen_controls = toggled_on
	Globals.save_settings()

func _on_season_pressed() -> void:
	Season.load_season()
	if Season.has_saved_season():
		get_tree().change_scene_to_file("res://menu/season_hub.tscn")
	else:
		get_tree().change_scene_to_file("res://menu/season_team_setup.tscn")
