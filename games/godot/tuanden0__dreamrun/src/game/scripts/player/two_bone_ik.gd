## Analytic 2-bone IK (law of cosines). Deterministic, no engine modification stack.
class_name TwoBoneIK
extends RefCounted


## Returns Vector2(root_angle, mid_angle): the root bone angle and the second bone's angle
## relative to the first, in radians, for a chain pointing along +x. Unreachable targets are clamped.
## bend = +1 puts the joint on the counter-clockwise side of the root->target line, which is the knee
## pointing forward (+x) for a leg aimed downward; -1 mirrors it.
static func solve(len_a: float, len_b: float, target: Vector2, bend: float = 1.0) -> Vector2:
	var dist := clampf(target.length(), absf(len_a - len_b) + 0.01, len_a + len_b - 0.01)
	var cos_root := clampf((len_a * len_a + dist * dist - len_b * len_b) / (2.0 * len_a * dist), -1.0, 1.0)
	var aim := target.angle()
	var root := aim - bend * acos(cos_root)
	var joint := Vector2.from_angle(root) * len_a
	var end := Vector2.from_angle(aim) * dist
	return Vector2(root, (end - joint).angle() - root)
