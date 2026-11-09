class_name Collectible
extends Area2D

enum Type { TREASURE, HAZARD }

@export var possible_items: Array[CollectibleData] = []

@onready var sprite_2d: Sprite2D = $Sprite2D # Make sure your child node name matches

var item_type: Type = Type.TREASURE
var point_value: int = 10

func _ready() -> void:
	add_to_group("collectibles")
	body_entered.connect(_on_body_entered)
	
	if possible_items.size() > 0:
		var chosen_item = possible_items.pick_random()
		item_type = chosen_item.item_type
		point_value = chosen_item.point_value
		sprite_2d.texture = chosen_item.texture

func _on_body_entered(body: Node2D) -> void:
	if item_type == Type.HAZARD:
		if body.has_method("die"):
			body.die()
		else:
			GameManager.score = max(0, GameManager.score - abs(point_value))
	else:
		GameManager.score += point_value
		
	queue_free()
