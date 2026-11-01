## A stretch of the level with its own ambient mix. When the player walks in, AudioManager fades each ambient layer
## to the volume (dB) listed here; layers not listed fade out. Origin is the floor line, the zone is centred on x.
class_name AudioZone
extends Area2D

signal entered(zone: AudioZone)

@export var size := Vector2(1000.0, 1200.0)
## Layer name -> volume in dB (see AudioManager.LAYER_FILES), e.g. {"wind": -12.0, "drone": -30.0}.
@export var layers: Dictionary = {}


func _ready() -> void:
	add_to_group(&"audio_zone")
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = size
	shape.position = Vector2(0.0, -size.y * 0.5)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		entered.emit(self)
