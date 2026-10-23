extends Node

@export var interact_enabled := true
@export var interact_max_distance: float = 5.0
@onready var _interact_max_distance2 := (
	interact_max_distance * interact_max_distance)

@export var select_max_distance: float = 100.0
@onready var _select_max_distance2 := (
	select_max_distance * select_max_distance)

@export var select_allow_deselect := false

@onready var player: Node = owner
@onready var highlighter: Node = player.get_node("HIGHLIGHTER")
@onready var character: CharacterBody3D = player.get_node("CharacterBody3D")
@onready var spring_arm: SpringArm3D = character.get_node("SpringArm3D")
@onready var camera: Camera3D = character.get_node("Camera3D")
@onready var sensor: Node3D = character.get_node("PROXIMITY")

const CAMERA_SELECT_DIRECTION_THRESHOLD := deg_to_rad(2.0)
var camera_select_direction := Vector3.ZERO

@onready var input: Node = character.input
func _update_camera_select_mode() -> void:
	if input.input_mode == input.InputMode.JOYPAD:
		camera.select_mode = camera.SelectMode.FIRST_PERSON
	else: camera.select_mode = camera.SelectMode.THIRD_PERSON

# OBJECT: _on_player_interacted(player: Node)
func _handle_input() -> void:
	if Input.is_action_just_pressed("player_select_nearest"):
		if is_object_selectable(sensor.nearest_object, false):
			highlighter.selected_object = sensor.nearest_object
		else: highlighter.selected_object = null
		return

	if Input.is_action_just_pressed("player_select+interact (joy)"):
		if is_object_interactable(camera.selected_object, true):
			if camera.selected_object.has_method("_on_player_interacted"):
				camera.selected_object._on_player_interacted(player)
		return

	if Input.is_action_just_pressed("player_select (mouse)"):
		camera_select_direction = -spring_arm.global_basis.z
	elif Input.is_action_just_released("player_select (mouse)"):
		if (camera_select_direction.angle_to(-spring_arm.global_basis.z)
			>= CAMERA_SELECT_DIRECTION_THRESHOLD): return

		if not is_instance_valid(camera.selected_object):
			if Input.is_action_just_released("player_camera_focus"):
				return

		elif select_allow_deselect:
			if not is_instance_valid(camera.selected_object): pass
			elif highlighter.selected_object == camera.selected_object:
				highlighter.selected_object = null
				return

		if Input.is_action_just_released("player_select+interact (mouse)"):
			if is_object_interactable(camera.selected_object, true):
				if camera.selected_object.has_method("_on_player_interacted"):
					camera.selected_object._on_player_interacted(player)

		if is_object_selectable(camera.selected_object, false):
			highlighter.selected_object = camera.selected_object
		else: highlighter.selected_object = null
		return

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	_handle_input()
	_update_camera_select_mode.call_deferred()
	if not is_object_selectable(highlighter.selected_object, true):
		highlighter.selected_object = null

# OBJECT: is_player_selectable: bool
func is_object_selectable(object: CollisionObject3D, within_distance: bool = false) -> bool:
	if not is_instance_valid(object): return false
	if typeof(object.get("is_player_selectable")) == TYPE_BOOL:
		if not object.is_player_selectable: return false
		if not within_distance: return true
		return (character.global_position.distance_squared_to(
			object.global_position) <= _select_max_distance2)
	return false

# OBJECT: is_player_interactable: bool
func is_object_interactable(object: CollisionObject3D, within_distance: bool = false) -> bool:
	if not interact_enabled: return false
	if not is_instance_valid(object): return false
	if typeof(object.get("is_player_interactable")) == TYPE_BOOL:
		if not object.is_player_interactable: return false
		if not within_distance: return true
		return (character.global_position.distance_squared_to(
			object.global_position) <= _interact_max_distance2)
	return false


func get_selected_object() -> CollisionObject3D:
	if is_instance_valid(highlighter.selected_object):
		return highlighter.selected_object
	return null


func set_selected_object(object) -> bool:
	if is_object_selectable(object, true):
		highlighter.selected_object = object
		return true
	return false


func get_hovered_object() -> CollisionObject3D:
	if is_instance_valid(highlighter.hovered_object):
		return highlighter.hovered_object
	return null


func get_interactable_object() -> CollisionObject3D:
	if is_object_interactable(highlighter.hovered_object, true):
		return highlighter.hovered_object
	return null
