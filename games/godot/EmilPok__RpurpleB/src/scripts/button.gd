extends Area2D

var hold_button_text = preload("res://art/misc/Buttons/hold_button.png")

@onready var main = get_tree().current_scene

@export var can_blue = true
@export var can_red = true

@export var hold = false
@export var time_hold = 0.5

@export var object: Node2D
@export var second_object : Node2D
@export var third_object : Node2D

@onready var Sprite = $Sprite

var can_press = true
var one_timer = false

var touching_characters = []

func _ready() -> void:
	if hold:
		$Sprite.texture = hold_button_text
		$Sprite.modulate = Color(0.8, 0.8, 0.8, 1.0)
	
	$Time_pressed.wait_time = time_hold
	
	if not (can_blue and can_red):
		if can_blue:
			set_collision_layer_value(6, false)
			set_collision_mask_value(4, false)
		else:
			set_collision_mask_value(5, false)
	

func _iam_button():
	if not can_press:
		return
	
	one_timer = true
	
	var first_object_moving = false
	if object.has_method("_moving_platform"):
		first_object_moving = true
	var did_two_objects = false
	
	$Pressed.play()
	object.no_sound = false
	object._active()
	if second_object:
		second_object.no_sound = false
		if first_object_moving and second_object.has_method("_moving_platform"):
			second_object.no_sound = true
		elif not first_object_moving and not second_object.has_method("_moving_platform"):
			second_object.no_sound = true
			did_two_objects = true
		second_object._active()
	if third_object:
		third_object.no_sound = false
		if did_two_objects:
			third_object.no_sound = true
		elif first_object_moving and third_object.has_method("_moving_platform"):
			second_object.no_sound = true
		elif not first_object_moving and not third_object.has_method("_moving_platform"):
			second_object.no_sound = true
		third_object._active()
	
	$Sprite.frame = 1
	
	
	can_press = false
	
	if touching_characters.is_empty():
		$Time_pressed.start()

func _on_time_pressed_timeout() -> void:
	if not one_timer:
		return
	one_timer = false
	can_press = true
	if hold:
		object._active()
	$Sprite.frame = 0
	$Unpressed.play()
	
	
func _on_body_exited(body: Node2D) -> void:
	if not main.active_button:
		return
	
	
	touching_characters.remove_at(touching_characters.find(body))
	
	if touching_characters.is_empty() and $Sprite.frame == 1:
		if $Time_pressed.is_inside_tree():
			$Time_pressed.start()

func _on_body_entered(body: Node2D) -> void:
	if not main.active_button:
		return
	
	touching_characters.append(body)
	_iam_button()
	
