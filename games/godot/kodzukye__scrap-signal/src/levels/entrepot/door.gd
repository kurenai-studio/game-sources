class_name Door
extends StaticBody2D

@export var required_flag: String = "vrac7_repaired"
@export var locked_sprite: Texture2D
@export var open_sprite: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	GameState.flag_changed.connect(_on_flag_changed)
	_update_state(GameState.get_flag(required_flag))

func _on_flag_changed(flag: String, value: bool) -> void:
	if flag == required_flag:
		_update_state(value)

func _update_state(is_open: bool) -> void:

	collision.disabled = is_open
	sprite.texture = open_sprite if is_open else locked_sprite
	if sprite.texture == open_sprite:
		AudioManager.play_sfx("door_unlock")
