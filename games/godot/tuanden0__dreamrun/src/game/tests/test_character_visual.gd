extends "res://tests/test_case.gd"


func test_rig_builds_named_bones() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	tree.root.add_child(player)
	await frames(5)
	var skeleton := player.get_node("Visual/Skeleton")
	for path in ["Hip", "Hip/Head", "Hip/Thigh0/Shin0", "Hip/Thigh1/Shin1/Foot1", "Hip/Head/Eye", "Hip/Arm0/Fore0", "Hip/Arm1/Fore1"]:
		check(skeleton.has_node(path), "missing bone %s" % path)
	player.queue_free()
	await frames(1)


func test_tuning_resource_exposes_values() -> void:
	var tuning := load("res://resources/player_animation_tuning.tres") as AnimationTuning
	check(tuning != null, "tuning .tres must load as AnimationTuning")
	if tuning != null:
		check(tuning.step_max > tuning.step_min and tuning.land_squash > 0.0, "tuning defaults look wrong")
