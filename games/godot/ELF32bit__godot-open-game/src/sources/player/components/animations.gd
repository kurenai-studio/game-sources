extends Node

signal interact_animation_finished(player: Node, success: bool)

@onready var character: CharacterBody3D = get_parent()
@onready var animation_player: AnimationPlayer = $"ANIMATIONS"


func _ready() -> void:
	_validate_animations()
	_connect_signals()


func _validate_animations() -> void:
	assert(animation_player.has_animation("idle"))
	assert(animation_player.has_animation("walk"))
	assert(animation_player.has_animation("swim"))
	assert(animation_player.has_animation("interact"))


func _connect_signals() -> void:
	animation_player.animation_finished.connect(
		_on_animation_finished)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	var velocity := character.velocity.length()
	if character.movement_mode == 1: play("swim")
	elif velocity > 0.1: play("walk")
	elif animation_player.assigned_animation != "interact":
		play("idle")


func _on_animation_finished(animation_name: StringName) -> void:
	match animation_name:
		"interact":
			interact_animation_finished.emit(owner, true)
			play("idle")


func play(animation: StringName, restart: bool = false) -> void:
	if restart or animation_player.current_animation != animation:
		animation_player.play(animation)
