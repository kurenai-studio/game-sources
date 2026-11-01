## Floor lever. The player presses interact next to it; it flips with a weighty overshoot and emits toggled.
## Origin is the floor line.
class_name Lever
extends Area2D

signal toggled(on: bool)

@export var swing_deg := 35.0
@export var shape_seed := 14
@export var color := Color(0.02, 0.02, 0.025)

var is_on := false

var _handle: Node2D
var _tween: Tween


var _saved_on := false


func _ready() -> void:
	add_to_group(&"usable")
	add_to_group(&"resettable")
	var base := Polygon2D.new()
	base.polygon = SolidProp.build_outline(SolidProp.Kind.BOULDER, Vector2(46.0, 22.0), shape_seed, 3.0)
	base.color = color
	base.antialiased = true
	add_child(base)
	_handle = Node2D.new()
	_handle.position = Vector2(0.0, -14.0)
	_handle.rotation_degrees = -swing_deg
	add_child(_handle)
	var arm := Line2D.new()
	arm.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, -36.0)])
	arm.width = 5.0
	arm.default_color = color
	arm.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_handle.add_child(arm)
	var knob := Polygon2D.new()
	var points := PackedVector2Array()
	for k in 10:
		points.append(Vector2(0.0, -38.0) + Vector2.from_angle(TAU * k / 10.0) * 6.0)
	knob.polygon = points
	knob.color = color
	knob.antialiased = true
	_handle.add_child(knob)
	var reach := CollisionShape2D.new()
	reach.shape = RectangleShape2D.new()
	reach.shape.size = Vector2(60.0, 70.0)
	reach.position = Vector2(0.0, -35.0)
	add_child(reach)


func save_checkpoint() -> void:
	_saved_on = is_on


func reset_to_checkpoint() -> void:
	if _tween != null:
		_tween.kill()
	is_on = _saved_on
	_handle.rotation_degrees = swing_deg if is_on else -swing_deg
	toggled.emit(is_on)  # whatever the lever drives must follow


## Called by the player on the interact key.
func interact() -> void:
	is_on = not is_on
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_handle, "rotation_degrees", swing_deg if is_on else -swing_deg, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toggled.emit(is_on)
