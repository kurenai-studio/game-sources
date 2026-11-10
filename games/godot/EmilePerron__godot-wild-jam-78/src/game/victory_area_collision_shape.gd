extends CollisionShape2D

const texture = preload("res://game/victory_area_gradient_texture.tres")

func _ready() -> void:
	# Create a sprite to visibly show the victory area
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.position = Vector2(0, 0) 
	sprite.region_enabled = true
	sprite.region_rect = shape.get_rect()
	add_child(sprite)
