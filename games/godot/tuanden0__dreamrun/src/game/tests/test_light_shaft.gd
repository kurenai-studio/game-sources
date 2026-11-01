extends "res://tests/test_case.gd"


func test_beam_shape() -> void:
	var img := LightShaft.build_image(64, 128, 0.35, 0.6)
	check(img.get_size() == Vector2i(64, 256), "image should be width x 2*half_height, got %s" % img.get_size())
	var top_half := img.get_pixel(32, 64).r
	var upper := img.get_pixel(32, 128 + 20).r
	var lower := img.get_pixel(32, 128 + 110).r
	var outside := img.get_pixel(0, 128 + 20).r
	check(top_half == 0.0, "top half (behind the origin) must be black")
	check(upper > 0.5, "beam centre near origin should be bright, got %s" % upper)
	check(lower < upper, "beam must fade along its length: %s vs %s" % [lower, upper])
	check(outside < 0.05, "outside the beam should be dark, got %s" % outside)


func test_node_builds_texture_and_scale() -> void:
	var shaft := LightShaft.new()
	shaft.length = 512.0
	shaft.width = 256.0
	tree.root.add_child(shaft)
	check(shaft.texture != null, "texture should be built on ready")
	check(is_equal_approx(shaft.texture_scale, 512.0 / 128.0), "texture_scale should map half image to length")
	shaft.queue_free()
	await frames(1)
