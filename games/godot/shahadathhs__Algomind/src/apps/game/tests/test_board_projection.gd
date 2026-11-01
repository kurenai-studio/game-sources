extends GutTest
## The 2.5D board's camera and projection: pure geometry.

const BOX := Vector2(350.0, 350.0)


func test_the_camera_flattens_and_steepens_as_the_board_grows() -> void:
	var small := BoardProjection.camera_for(5, 5)
	var middle := BoardProjection.camera_for(9, 9)
	var large := BoardProjection.camera_for(12, 10)
	assert_eq(small["pitch"], 62.0)
	assert_almost_eq(float(small["perspective"]), 0.06, 0.0001)
	assert_gt(float(middle["pitch"]), float(small["pitch"]))
	assert_gt(float(large["pitch"]), float(middle["pitch"]))
	assert_eq(large["pitch"], 80.0)
	assert_lt(float(large["perspective"]), float(small["perspective"]))
	assert_eq(BoardProjection.camera_for(3, 3), small, "small boards share one camera")


func test_every_corner_of_the_plate_fits_in_the_box() -> void:
	for size in [Vector2i(5, 5), Vector2i(6, 5), Vector2i(9, 9), Vector2i(12, 10), Vector2i(3, 3)]:
		var view := BoardProjection.new(size.x, size.y, BOX)
		var margin := BoardProjection.PLATE_MARGIN
		for corner in [
			Vector2(-margin, -margin),
			Vector2(size.x + margin, -margin),
			Vector2(-margin, size.y + margin),
			Vector2(size.x + margin, size.y + margin),
		]:
			for z in [BoardProjection.Z_PLATE, BoardProjection.Z_TOP]:
				var point := view.project(corner.x, corner.y, z)
				assert_between(point.x, 0.0, BOX.x, "%s x" % size)
				assert_between(point.y, 0.0, BOX.y, "%s y" % size)


func test_a_higher_point_is_higher_on_the_screen() -> void:
	var view := BoardProjection.new(5, 5, BOX)
	assert_lt(view.project(2.0, 2.0, 0.6).y, view.project(2.0, 2.0, 0.0).y)


func test_a_row_nearer_the_camera_is_lower_on_the_screen_and_painted_later() -> void:
	var view := BoardProjection.new(5, 5, BOX)
	assert_gt(view.project(2.0, 4.0, 0.0).y, view.project(2.0, 0.0, 0.0).y)
	assert_gt(view.depth(2.5, 4.5), view.depth(2.5, 0.5))


func test_the_camera_sees_the_front_of_a_block_and_not_its_back() -> void:
	var view := BoardProjection.new(5, 5, BOX)
	assert_true(view.sees(2.5, 3.0, 0.0, 1.0), "a face looking at the camera is seen")
	assert_false(view.sees(2.5, 2.0, 0.0, -1.0), "a face looking away is not seen")


func test_a_block_left_of_center_shows_its_inner_side() -> void:
	var view := BoardProjection.new(5, 5, BOX)
	assert_true(view.sees(1.0, 2.5, 1.0, 0.0), "the east face of a left block faces the center")
	assert_false(view.sees(1.0, 2.5, -1.0, 0.0), "its west face faces away")
	assert_true(view.sees(4.0, 2.5, -1.0, 0.0), "the west face of a right block faces the center")


func test_the_scale_is_positive_and_a_bigger_box_gives_a_bigger_scale() -> void:
	var small := BoardProjection.new(5, 5, Vector2(200.0, 200.0))
	var big := BoardProjection.new(5, 5, Vector2(400.0, 400.0))
	assert_gt(small.cell_scale, 0.0)
	assert_gt(big.cell_scale, small.cell_scale)
