extends Area2D
class_name HurtboxComponent

@export var health_component: Node

var floating_text_scene = preload("res://scenes/ui/floating_text.tscn")


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(other_area: Area2D):
	if not other_area is HitboxComponent:
		return

	if health_component == null:
		return

	var hitbox_component = other_area as HitboxComponent
	var enemy_damage_dealt = hitbox_component.damage
	health_component.damage(enemy_damage_dealt)
	
	var floating_text = floating_text_scene.instantiate() as Node2D
	get_tree().get_first_node_in_group("foreground_layer").add_child(floating_text)
	floating_text.global_position = global_position + (Vector2.UP * 16)
	var format_string = "%0.1f"
	if round(enemy_damage_dealt) == enemy_damage_dealt:
		format_string = "%0.0f"
	
	floating_text.start(format_string % enemy_damage_dealt)
