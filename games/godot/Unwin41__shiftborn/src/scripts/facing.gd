class_name Facing
extends RefCounted
## Four-way facing for the Ninja Adventure sheets: picks the direction
## from a movement vector and the matching animation name. SpriteFrames
## without directional animations (the boss strips) fall back to
## "run" / "idle".

const DOWN := &"down"
const UP := &"up"
const LEFT := &"left"
const RIGHT := &"right"


## Facing for [param movement]; [param previous] when not moving.
static func from_vector(movement: Vector2, previous: StringName) -> StringName:
	if movement.is_zero_approx():
		return previous
	if absf(movement.x) > absf(movement.y):
		return RIGHT if movement.x > 0.0 else LEFT
	return DOWN if movement.y > 0.0 else UP


static func walk_animation(frames: SpriteFrames, facing: StringName) -> StringName:
	var name := StringName("walk_%s" % facing)
	return name if frames.has_animation(name) else &"run"


static func idle_animation(frames: SpriteFrames, facing: StringName) -> StringName:
	var name := StringName("idle_%s" % facing)
	return name if frames.has_animation(name) else &"idle"


static func is_directional(frames: SpriteFrames) -> bool:
	return frames.has_animation(&"walk_down")
