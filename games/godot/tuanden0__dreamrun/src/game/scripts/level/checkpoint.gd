## A checkpoint: a stump with a candle that lights when the player first touches it. The manager
## saves the world state then. Origin is the floor line; the player respawns at spawn_position().
class_name Checkpoint
extends Area2D

signal activated(checkpoint: Checkpoint)

@export var size := Vector2(120.0, 200.0)
@export var spawn_offset := Vector2.ZERO
@export var color := Color(0.02, 0.02, 0.025)

var is_active := false

var _light: PointLight2D
var _tween: Tween


func _ready() -> void:
	add_to_group(&"checkpoint")
	var stump := Polygon2D.new()
	stump.polygon = SolidProp.build_outline(SolidProp.Kind.BOULDER, Vector2(34.0, 30.0), 5, 3.0)
	stump.color = color
	stump.antialiased = true
	add_child(stump)
	var candle := Line2D.new()
	candle.points = PackedVector2Array([Vector2(0.0, -26.0), Vector2(0.0, -40.0)])
	candle.width = 5.0
	candle.default_color = color
	add_child(candle)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_light = PointLight2D.new()
	_light.texture = texture
	_light.texture_scale = 2.4
	_light.energy = 0.0
	_light.position = Vector2(0.0, -46.0)
	add_child(_light)
	var zone := CollisionShape2D.new()
	zone.shape = RectangleShape2D.new()
	zone.shape.size = size
	zone.position = Vector2(0.0, -size.y * 0.5)
	add_child(zone)
	body_entered.connect(_on_body_entered)


func spawn_position() -> Vector2:
	return global_position + spawn_offset


func _on_body_entered(body: Node2D) -> void:
	if not is_active and body.is_in_group(&"player"):
		is_active = true
		if _tween != null:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(_light, "energy", 0.8, 0.6)
		activated.emit(self)
