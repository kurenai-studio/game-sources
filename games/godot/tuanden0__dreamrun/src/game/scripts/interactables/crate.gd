## Pushable/pullable wooden crate. Visual, collision and shadow share one irregular outline.
## The player moves it by matching its velocity while the interact key is held (see PlayerController).
class_name Crate
extends RigidBody2D

@export var size := Vector2(56.0, 56.0)
@export var shape_seed := 3
@export var color := Color(0.02, 0.02, 0.025)
@export var rim_color := Color(0.1, 0.1, 0.12)


var _saved_position := Vector2.ZERO


func _ready() -> void:
	add_to_group(&"grabbable")
	add_to_group(&"resettable")
	_saved_position = global_position
	mass = 8.0
	lock_rotation = true  # slides like a crate in Limbo; pushing never tips it over
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.9
	var outline := SolidProp.build_outline(SolidProp.Kind.SLAB, size, shape_seed, 3.0)
	var body := Polygon2D.new()
	body.name = &"Shape"
	body.polygon = outline
	body.color = color
	body.antialiased = true
	add_child(body)
	var half := size * 0.5
	# Plank seams and a cross brace: lighter strokes so the crate reads as wood, not a block.
	for x in [-size.x / 6.0, size.x / 6.0]:
		_stroke([Vector2(x, -half.y + 4.0), Vector2(x, half.y - 4.0)], 1.5)
	_stroke([Vector2(-half.x + 5.0, -half.y + 5.0), Vector2(half.x - 5.0, half.y - 5.0)], 3.0)
	var collision := CollisionPolygon2D.new()
	collision.name = &"Collision"
	collision.polygon = outline
	add_child(collision)
	var occluder := LightOccluder2D.new()
	occluder.occluder = OccluderPolygon2D.new()
	occluder.occluder.polygon = outline
	add_child(occluder)


func save_checkpoint() -> void:
	_saved_position = global_position


func reset_to_checkpoint() -> void:
	# A RigidBody2D must be moved through the physics server, not by assigning its position.
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, _saved_position))
	linear_velocity = Vector2.ZERO


## While held by the player the crate is frozen and moved by code, so collisions stop it cleanly
## instead of the physics solver ejecting it from whatever it was forced into.
func hold() -> void:
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true


func drop() -> void:
	freeze = false
	linear_velocity = Vector2.ZERO


## Moves sideways by up to dx and returns how far it really got (0 when blocked).
func shove(dx: float) -> float:
	var before := global_position.x
	move_and_collide(Vector2(dx, 0.0))
	return global_position.x - before


## Held crates ignore gravity, so drop them onto whatever is below.
func settle(delta: float) -> void:
	move_and_collide(Vector2(0.0, 600.0 * delta))


func _stroke(points: Array[Vector2], width: float) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array(points)
	line.width = width
	line.default_color = rim_color
	add_child(line)
