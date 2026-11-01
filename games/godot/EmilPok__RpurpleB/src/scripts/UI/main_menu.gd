extends Control

var hover_dark = 0.6
var hover_dark_color = Color(hover_dark, hover_dark, hover_dark, 1.0)

func _ready() -> void:
	$GameTitle.hide()
	
	var cables = [
		$LevelSelector/Level1/LevelConnector,
		$LevelSelector/Level2/LevelConnector,
		$LevelSelector/Level3/LevelConnector,
		$LevelSelector/Level4/LevelConnector,
		$LevelSelector/Level5/LevelConnector,
		$LevelSelector/Level6/LevelConnector,
		$LevelSelector/Level7/LevelConnector,
		$LevelSelector/Level8/LevelConnector,
		$LevelSelector/Level9/LevelConnector
	]
	var levels = [
		$LevelSelector/Level1,
		$LevelSelector/Level2,
		$LevelSelector/Level3,
		$LevelSelector/Level4,
		$LevelSelector/Level5,
		$LevelSelector/Level6,
		$LevelSelector/Level7,
		$LevelSelector/Level8,
		$LevelSelector/Level9
	]
	
	var last_cable = 1
	
	if Global.levels_completed <= Global.last_levels_completed:
		last_cable = 0

	for i in cables.size():
		if i < Global.levels_completed - last_cable:
			cables[i].set_connector()
			if i + 1 < levels.size():
				levels[i + 1].get_node("MostlyPurpleLevel").visible = true
	
	if Global.finished:
		$Transition_Background_2.show()
		
		$AnimationPlayer.play("level_selector_half")
		
		await $AnimationPlayer.animation_finished
		
		if Global.levels_completed > Global.last_levels_completed:
			Global.last_levels_completed = Global.levels_completed
			var i = Global.levels_completed - 1
			cables[i].connect_levels()
			if not Global.levels_completed == 9:
				$Loading_timer.start()
			await cables[i].get_node("AnimationPlayer").animation_finished
			if not Global.levels_completed == 9:
				$Collect.play()
			if i + 1 < levels.size():
				levels[i + 1].get_node("MostlyPurpleLevel").visible = true
	
	Global.finished = false
	
	if Global.do_anim:
		Global.do_anim = false
		$AnimationPlayer.play("level_selector_half")
	
	if $MainButtons.visible and not $Transition_Animations.is_playing() and not $AnimationPlayer.is_playing():
		_on_start_anim_timeout()
	

func _on_play_pressed() -> void:
	$Click.play()
	$Transition_Animations.play("level_selector_on")

func _on_options_pressed() -> void:
	$Click.play()
	$Transition_Animations.play("options_on")

func _on_credits_pressed() -> void:
	$Click.play()
	$Transition_Animations.play("credits_on")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_back_button_pressed() -> void:
	$Click.play()
	$Credits_Smooth_Movement_Handl/BackButton.modulate = Color.WHITE
	$Options/CreditsTitle/BackButton_options.modulate = Color.WHITE
	$LevelSelector/BackButton2.modulate = Color.WHITE
	
	
	if $Credits_Smooth_Movement_Handl.visible:
		$Transition_Animations.play("credits_off")
	if $LevelSelector.visible:
		$Transition_Animations.play("level_selector_off")
	if $Options.visible:
		$Transition_Animations.play("options_off")
	if $Start_name_anim.is_stopped():
		$Start_name_anim.start()
	
	

func _start_transition(num):
	$Click.play()
	if Global.levels_completed < num - 1:
		return
	
	Global.selected_level = num
	
	$AnimationPlayer.play("circle")
	$Circle_trans_time.start()

func _on_circle_trans_time_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_button_pressed() -> void:
	_start_transition(1)
func _on_button_2_pressed() -> void:
	_start_transition(2)
func _on_button_3_pressed() -> void:
	_start_transition(3)
func _on_button_4_pressed() -> void:
	_start_transition(4)
func _on_button_5_pressed() -> void:
	_start_transition(5)
func _on_button_6_pressed() -> void:
	_start_transition(6)
func _on_button_7_pressed() -> void:
	_start_transition(7)
func _on_button_8_pressed() -> void:
	_start_transition(8)
func _on_button_9_pressed() -> void:
	_start_transition(9)

func _on_play_mouse_entered() -> void:
	$MainButtons/Play.modulate = hover_dark_color
func _on_play_mouse_exited() -> void:
	$MainButtons/Play.modulate = Color.WHITE
func _on_options_mouse_entered() -> void:
	$MainButtons/HBoxContainer/Options.modulate = hover_dark_color
func _on_options_mouse_exited() -> void:
	$MainButtons/HBoxContainer/Options.modulate = Color.WHITE
func _on_credits_mouse_entered() -> void:
	$MainButtons/HBoxContainer/Credits.modulate = hover_dark_color
func _on_credits_mouse_exited() -> void:
	$MainButtons/HBoxContainer/Credits.modulate = Color.WHITE
func _on_exit_mouse_entered() -> void:
	$MainButtons/HBoxContainer/Exit.modulate = hover_dark_color
func _on_exit_mouse_exited() -> void:
	$MainButtons/HBoxContainer/Exit.modulate = Color.WHITE
func _on_back_button_mouse_entered() -> void:
	$Credits_Smooth_Movement_Handl/BackButton.modulate = hover_dark_color
func _on_back_button_mouse_exited() -> void:
	$Credits_Smooth_Movement_Handl/BackButton.modulate = Color.WHITE
func _on_back_button_2_mouse_entered() -> void:
	$LevelSelector/BackButton2.modulate = hover_dark_color
func _on_back_button_2_mouse_exited() -> void:
	$LevelSelector/BackButton2.modulate = Color.WHITE

func _on_play_button_down() -> void:
	$MainButtons/Play.modulate = Color.WHITE
func _on_options_button_down() -> void:
	$MainButtons/HBoxContainer/Options.modulate = Color.WHITE
func _on_credits_button_down() -> void:
	$MainButtons/HBoxContainer/Credits.modulate = Color.WHITE
func _on_exit_button_down() -> void:
	$MainButtons/HBoxContainer/Credits.modulate = Color.WHITE


func _on_back_button_button_down() -> void:
	$Credits_Smooth_Movement_Handl/BackButton.modulate = Color(0.4, 0.4, 0.4, 1.0)
func _on_back_button_2_button_down() -> void:
	$LevelSelector/BackButton2.modulate  = Color(0.4, 0.4, 0.4, 1.0)

func _on_loading_timer_timeout() -> void:
	$Loading.play()


func _change_audio(bus, value):
	value /= 100.0
	var bus_index = AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


func _on_h_slider_value_changed(value: float) -> void:
	_change_audio("Music", value)
func _on_h_slider_2_value_changed(value: float) -> void:
	_change_audio("sfx", value)


func _on_back_button_options_button_down() -> void:
	$Options/CreditsTitle/BackButton_options.modulate = Color(0.4, 0.4, 0.4, 1.0)
func _on_back_button_options_mouse_entered() -> void:
	$Options/CreditsTitle/BackButton_options.modulate = hover_dark_color
func _on_back_button_options_mouse_exited() -> void:
	$Options/CreditsTitle/BackButton_options.modulate = Color.WHITE


func _on_h_slider_drag_started() -> void:
	$Click_start.play()

func _on_h_slider_2_drag_started() -> void:
	$Click_start.play()

func _on_h_slider_drag_ended(_value_changed: bool) -> void:
	$Click_end.play()
func _on_h_slider_2_drag_ended(_value_changed: bool) -> void:
	$Click_end.play()


func _on_start_anim_timeout() -> void:
	var tween = create_tween()
	$GameTitle.position.y = 30.0
	$GameTitle.show()
	tween.tween_property($GameTitle, "position:y", 90.0, 1.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	
	
	
