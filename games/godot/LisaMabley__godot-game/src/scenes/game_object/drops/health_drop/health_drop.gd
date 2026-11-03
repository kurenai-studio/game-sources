extends Node2D

@onready var pickup_animation_component = $PickupAnimationComponent


func _ready() -> void:
	pickup_animation_component.collected.connect(_on_collected)


func _on_collected() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		var health_component = player.get_node("HealthComponent") as HealthComponent
		health_component.heal(health_component.max_health * 0.1)
	queue_free()
