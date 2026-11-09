# loading_zone.gd
extends Area2D

@export var target_scene: String = "res://levels/atelier/atelier.tscn"
@export var fade_duration: float = 0.6

@onready var fade_rect: ColorRect = $TransitionLayer/FadeRect

var _transitioning: bool = false

func _ready() -> void:
	fade_rect.modulate.a = 0.0
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _transitioning:
		return
	if body.is_in_group("player"):
		_transitioning = true
		_start_transition()

func _start_transition() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(target_scene)
	)
