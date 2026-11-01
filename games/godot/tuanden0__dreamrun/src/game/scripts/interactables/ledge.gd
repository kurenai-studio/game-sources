## Invisible climb zone at a platform edge. The player catches the edge when its HANDS reach it while
## jumping (feet still about hand_reach below the top), hangs, pulls up and rolls onto top_position().
class_name Ledge
extends Area2D

@export var size := Vector2(70.0, 110.0)
## Where the player's feet end up, relative to this node.
@export var top_offset := Vector2(30.0, -48.0)
## Feet-to-hands distance with arms raised: while hanging the feet are this far below the edge.
@export var hand_reach := 112.0
## How far (px) the hands may be above or below the edge and still catch it.
@export var grab_tolerance := 24.0
## Where the feet are while the knee gets over the edge, relative to top_position(): against the wall, a bit below the top.
@export var hang_offset := Vector2(-36.0, 28.0)


func _ready() -> void:
	add_to_group(&"ledge")
	var zone := CollisionShape2D.new()
	zone.shape = RectangleShape2D.new()
	zone.shape.size = size
	add_child(zone)


func top_position() -> Vector2:
	return global_position + top_offset


## Feet position while the knee gets over the edge.
func hug_position() -> Vector2:
	return top_position() + hang_offset


## Feet position while hanging from the edge by the hands.
func hang_position() -> Vector2:
	return Vector2(hug_position().x, top_position().y + hand_reach)


## True when the hands are at the edge: feet_y is the player's feet height (global). Standing on top
## puts the hands far above the edge, so it never matches.
func can_grab(feet_y: float) -> bool:
	return absf((feet_y - hand_reach) - top_position().y) <= grab_tolerance
