# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Layout: the landscape rule of docs/ARCHITECTURE.md 7.4 and the safe area.


func test_landscape_table() -> void:
	# Window size, expected landscape (section 7.4).
	var table: Array[Array] = [
		[Vector2(904, 2316), false],
		[Vector2(1080, 2400), false],
		[Vector2(1080, 1920), false],
		[Vector2(1600, 2560), false],
		[Vector2(1536, 2048), true],
		[Vector2(1812, 2176), true],
		[Vector2(2176, 1812), true],
		[Vector2(1080, 2767), false],
		[Vector2(1998, 2400), true],
	]
	for row: Array in table:
		var size: Vector2 = row[0]
		assert_eq(Layout.is_landscape(size), row[1], "window %s" % size)


func test_the_edge_is_one_and_a_half() -> void:
	assert_false(Layout.is_landscape(Vector2(1000, 1500)), "exactly 1.5 is portrait")
	assert_true(Layout.is_landscape(Vector2(1000, 1499)), "just below 1.5 is landscape")


func test_a_broken_window_size_is_portrait() -> void:
	assert_false(Layout.is_landscape(Vector2.ZERO))
	assert_false(Layout.is_landscape(Vector2(-5, 100)))


func test_min_touch_is_48_dp_on_the_fold5_cover() -> void:
	# 3.14 logical px per dp on the cover screen (section 7.4).
	assert_true(Layout.MIN_TOUCH / 3.14 >= 48.0)


func test_safe_area_maps_into_the_viewport() -> void:
	# A 904 x 2316 window shown as a 1080 x 2767 viewport, with 80 px cut off on top.
	var safe: Rect2 = Layout.safe_in_viewport(Vector2(1080, 2767), Vector2(904, 2316), Vector2.ZERO, Rect2(0, 80, 904, 2236))
	assert_near(safe.position.y, 80.0 * 1080.0 / 904.0, 0.01)
	assert_near(safe.size.x, 1080.0, 0.01)
	assert_near(safe.end.y, 2767.0, 0.01)


func test_safe_area_follows_the_window_position() -> void:
	var safe: Rect2 = Layout.safe_in_viewport(Vector2(1000, 1000), Vector2(500, 500), Vector2(100, 100), Rect2(150, 100, 300, 500))
	assert_near(safe.position.x, 100.0, 0.01)
	assert_near(safe.size.x, 600.0, 0.01)


func test_a_useless_safe_area_gives_the_whole_viewport() -> void:
	var whole: Rect2 = Rect2(0, 0, 1080, 2400)
	assert_eq(Layout.safe_in_viewport(Vector2(1080, 2400), Vector2(432, 960), Vector2.ZERO, Rect2()), whole)
	assert_eq(Layout.safe_in_viewport(Vector2(1080, 2400), Vector2.ZERO, Vector2.ZERO, Rect2(0, 0, 10, 10)), whole)
	assert_eq(Layout.safe_in_viewport(Vector2(1080, 2400), Vector2(432, 960), Vector2.ZERO, Rect2(5000, 5000, 10, 10)), whole)


func test_a_screen_larger_than_the_window_is_clipped() -> void:
	var safe: Rect2 = Layout.safe_in_viewport(Vector2(1080, 2400), Vector2(432, 960), Vector2.ZERO, Rect2(-100, -100, 1000, 2000))
	assert_eq(safe.position, Vector2.ZERO)
	assert_near(safe.size.x, 1080.0, 0.01)


func test_a_sub_viewport_has_no_cutouts() -> void:
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(1080, 2767)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(vp)
	assert_eq(Layout.safe_rect(vp), Rect2(0, 0, 1080, 2767))
	vp.queue_free()


func test_content_width_is_capped_and_never_below_a_touch() -> void:
	assert_near(Layout.content_width(1080.0, Rect2(0, 0, 1080, 2767)), 1080.0 - 2.0 * Layout.PAD, 0.01)
	assert_near(Layout.content_width(1998.0, Rect2(0, 0, 1998, 2400)), Layout.CONTENT_MAX, 0.01)
	assert_true(Layout.content_width(10.0, Rect2(0, 0, 10, 10)) >= Layout.MIN_TOUCH)
