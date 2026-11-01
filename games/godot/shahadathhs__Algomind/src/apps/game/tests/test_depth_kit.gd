extends GutTest
## The depth look: the generated palette switches themes, and DepthKit's geometry is sound.


func after_each() -> void:
	DepthPalette.apply(false)


func test_apply_dark_switches_the_ground_but_not_the_signal() -> void:
	var light_ground := DepthPalette.GROUND_TOP
	var light_signal := DepthPalette.SIGNAL
	DepthPalette.apply(true)
	assert_ne(DepthPalette.GROUND_TOP, light_ground)
	assert_eq(DepthPalette.SIGNAL, light_signal, "the accent is the same in both themes")
	DepthPalette.apply(false)
	assert_eq(DepthPalette.GROUND_TOP, light_ground)


func test_every_derived_shade_exists_and_differs_from_its_base() -> void:
	for dark in [false, true]:
		DepthPalette.apply(dark)
		assert_ne(DepthPalette.TILE_LIP, DepthPalette.TILE)
		assert_ne(DepthPalette.SIGNAL_LIP, DepthPalette.SIGNAL)
		assert_ne(DepthPalette.INK_LIP, DepthPalette.INK)
		assert_ne(DepthPalette.WALL_FRONT, DepthPalette.WALL)
		assert_ne(DepthPalette.WALL_SIDE, DepthPalette.WALL_FRONT)
		assert_ne(DepthPalette.FLOOR_EDGE, DepthPalette.FLOOR)


func test_lip_height_is_clamped_to_its_range() -> void:
	assert_eq(DepthKit.lip_height(Rect2(0, 0, 100, 10)), DepthKit.LIP_MIN)
	assert_eq(DepthKit.lip_height(Rect2(0, 0, 100, 400)), DepthKit.LIP_MAX)
	var middle := DepthKit.lip_height(Rect2(0, 0, 100, 50))
	assert_between(middle, DepthKit.LIP_MIN, DepthKit.LIP_MAX)


func test_the_face_leaves_room_for_the_lip() -> void:
	var rect := Rect2(10, 20, 110, 60)
	var face := DepthKit.face_rect(rect)
	assert_eq(face.position, rect.position)
	assert_eq(face.size.x, rect.size.x)
	assert_almost_eq(face.size.y, rect.size.y - DepthKit.lip_height(rect), 0.001)


func test_label_colors_follow_the_key_kind() -> void:
	assert_eq(DepthKit.label_color(DepthKit.Kind.TILE), DepthPalette.INK)
	assert_eq(DepthKit.label_color(DepthKit.Kind.SIGNAL), DepthPalette.ON_SIGNAL)
	assert_eq(DepthKit.label_color(DepthKit.Kind.INK), DepthPalette.ON_INK)


func test_a_soft_shadow_has_one_polygon_per_layer_and_grows_outward() -> void:
	var shape := PackedVector2Array(
		[Vector2(0, 0), Vector2(40, 0), Vector2(40, 20), Vector2(0, 20)]
	)
	var polygons := DepthKit.shadow_polygons(shape, Vector2(0, 4), 8.0, 4)
	assert_eq(polygons.size(), 4)
	# Outermost first: each later polygon is smaller.
	for i in range(1, polygons.size()):
		assert_lt(_area(polygons[i]), _area(polygons[i - 1]))


func test_the_sample_screen_draws_without_errors() -> void:
	DepthPalette.apply(true)
	var sample := DepthKitSample.new()
	sample.size = Vector2(390, 844)
	add_child_autofree(sample)
	await get_tree().process_frame
	assert_not_null(sample)


func _area(polygon: PackedVector2Array) -> float:
	var total := 0.0
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		total += a.x * b.y - b.x * a.y
	return absf(total) / 2.0
