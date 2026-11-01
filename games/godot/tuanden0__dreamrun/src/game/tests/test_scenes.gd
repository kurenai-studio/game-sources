extends "res://tests/test_case.gd"


func test_test_room_instantiates_with_lights_and_layers() -> void:
	var room := (load("res://scenes/test_room.tscn") as PackedScene).instantiate()
	tree.root.add_child(room)
	await frames(3)
	check(room.has_node("Darkness") and room.has_node("Player/Lantern"), "room needs CanvasModulate and lantern")
	check(room.get_node("FarLayer").get_child_count() > 0, "silhouette layer should generate shapes")
	check(room.has_node("PostProcess/FilmGrainVignette"), "post-process rect missing")
	check(room.has_node("Fog/FogOverlay") and room.get_node("ShaftA").texture != null, "fog overlay or shaft missing")
	check(room.has_node("FarBlur") and room.get_node("ForeLayer").get_child_count() > 0, "depth blur or soft foreground trunks missing")
	room.queue_free()
	await frames(1)
