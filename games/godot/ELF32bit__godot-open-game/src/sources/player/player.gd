extends Node3D

@onready var character: CharacterBody3D = $"CharacterBody3D"
@onready var animations: Node = $"CharacterBody3D/MeshInstance3D"
@onready var camera: Camera3D = $"CharacterBody3D/Camera3D"
@onready var selector: Node = $"SELECTOR"


func _ready() -> void:
	GameState.player = self

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	_update_swim_areas_screen_effect.call_deferred()
	_update_selector_objects.call_deferred()


func _update_swim_areas_screen_effect() -> void:
	if character.is_swimming_deep:
		GameState.player_swim_area_type = character.swim_area_type
	else: GameState.player_swim_area_type = -1


func _update_selector_objects() -> void:
	GameState.player_hovered_object = selector.get_hovered_object()
	GameState.player_selected_object = selector.get_selected_object()
	GameState.player_interactable_object = selector.get_interactable_object()


func can_interact() -> bool:
	if character.is_swimming: return true
	elif not character.is_on_floor(): return false
	else: return true

# OBJECT: _on_player_finished_interacting(player: Node, success: bool)
func interact_with_collectable(node: Node3D) -> void: # TODO: gameplay checks
	if not is_instance_valid(node): return
	var callable := Callable(node, "_on_player_finished_interacting")
	if not animations.is_connected("interact_animation_finished", callable):
		animations.interact_animation_finished.connect(callable,
			CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	animations.play("interact")


func push(velocity: Vector3) -> void:
	character.push(velocity)


func teleport(to: Transform3D, push_speed: float = 0.0) -> void:
	character.teleport(to, push_speed)
