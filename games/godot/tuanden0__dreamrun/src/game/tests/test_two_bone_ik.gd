extends "res://tests/test_case.gd"


func _end_effector(a: float, b: float, angles: Vector2) -> Vector2:
	return Vector2.from_angle(angles.x) * a + Vector2.from_angle(angles.x + angles.y) * b


func test_reachable_targets_within_one_pixel() -> void:
	for target in [Vector2(30, 20), Vector2(0, 40), Vector2(-20, 30), Vector2(10, 47), Vector2(0, 5)]:
		var end := _end_effector(24.0, 24.0, TwoBoneIK.solve(24.0, 24.0, target))
		check(end.distance_to(target) < 1.0, "target %s reached %s" % [target, end])


func test_unreachable_target_clamped_toward_target() -> void:
	var end := _end_effector(24.0, 24.0, TwoBoneIK.solve(24.0, 24.0, Vector2(100, 0)))
	check(end.length() <= 48.0, "end effector beyond reach: %s" % end)
	check(end.x > 40.0 and absf(end.y) < 1.0, "should point at target: %s" % end)


func test_knee_points_forward_for_downward_leg() -> void:
	var angles := TwoBoneIK.solve(24.0, 24.0, Vector2(0, 40))
	var knee := Vector2.from_angle(angles.x) * 24.0
	check(knee.x > 0.0, "knee should be in front (+x), got %s" % knee)
