extends Node2D

@onready var pickup_animation_component = $PickupAnimationComponent


func _ready() -> void:
	pickup_animation_component.collected.connect(_on_collected)


func _on_collected():
	GameEvents.emit_experience_gem_collected(1)
	queue_free()
