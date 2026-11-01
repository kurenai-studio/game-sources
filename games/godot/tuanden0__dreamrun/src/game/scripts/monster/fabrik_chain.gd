## FABRIK inverse kinematics for a chain of joints: root pinned, tip pulled toward the target,
## bone lengths preserved. Plain math, no engine IK, so it is deterministic and unit-testable.
class_name FabrikChain
extends RefCounted


## joints[0] is the root. Returns the new joint positions; the inputs are not modified.
## ponytail: a perfectly straight chain with a target exactly on its own line folds in place instead of
## bending sideways; seed the joints with a slight bend (a moving tentacle already has one).
static func solve(joints: PackedVector2Array, lengths: PackedFloat32Array, root: Vector2, target: Vector2, iterations: int = 6) -> PackedVector2Array:
	var count := joints.size()
	var pts := joints.duplicate()
	var reach := 0.0
	for length in lengths:
		reach += length
	if root.distance_to(target) >= reach:
		# Out of reach: stretch straight toward the target.
		var dir := (target - root).normalized()
		pts[0] = root
		for i in range(1, count):
			pts[i] = pts[i - 1] + dir * lengths[i - 1]
		return pts
	for iteration in iterations:
		pts[count - 1] = target
		for i in range(count - 2, -1, -1):
			pts[i] = pts[i + 1] + _toward(pts[i], pts[i + 1]) * lengths[i]
		pts[0] = root
		for i in range(1, count):
			pts[i] = pts[i - 1] + _toward(pts[i], pts[i - 1]) * lengths[i - 1]
	return pts


## Unit vector from `anchor` to `point`; a fixed fallback when they coincide.
static func _toward(point: Vector2, anchor: Vector2) -> Vector2:
	var d := point - anchor
	return d.normalized() if d.length_squared() > 0.000001 else Vector2.RIGHT
