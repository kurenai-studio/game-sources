extends "res://tests/test_case.gd"

const BONES := 5
const BONE_LENGTH := 20.0


func _chain() -> PackedVector2Array:
	var joints := PackedVector2Array()
	for i in BONES + 1:
		joints.append(Vector2(i * BONE_LENGTH, 0.0))
	return joints


func _lengths() -> PackedFloat32Array:
	var lengths := PackedFloat32Array()
	for i in BONES:
		lengths.append(BONE_LENGTH)
	return lengths


func test_reachable_targets_are_hit_within_a_pixel() -> void:
	for target in [Vector2(60, 50), Vector2(-40, 70), Vector2(10, -90), Vector2(30, 8)]:
		var joints := FabrikChain.solve(_chain(), _lengths(), Vector2.ZERO, target, 10)
		check(joints[BONES].distance_to(target) < 1.0, "tip %s should reach %s" % [joints[BONES], target])
		check(joints[0] == Vector2.ZERO, "root must stay pinned")
		for i in BONES:
			check(absf(joints[i].distance_to(joints[i + 1]) - BONE_LENGTH) < 0.01, "bone %d length changed" % i)


func test_unreachable_target_stretches_straight_toward_it() -> void:
	var joints := FabrikChain.solve(_chain(), _lengths(), Vector2.ZERO, Vector2(0, 500))
	check(joints[BONES].distance_to(Vector2(0, BONES * BONE_LENGTH)) < 0.01, "tip should be fully stretched at %s" % joints[BONES])


func test_input_is_not_modified() -> void:
	var original := _chain()
	FabrikChain.solve(original, _lengths(), Vector2.ZERO, Vector2(40, 40))
	check(original == _chain(), "solve must return a new array")
