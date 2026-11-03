extends Node2D

# Surface colors (inviting fantasy dungeon palette)
const COLOR_CEILING = Color("#2c2b3d") # Slate violet
const COLOR_FLOOR = Color("#3e334d")   # Stone purple
const COLOR_WALL_L = Color("#4b435c")  # Left wall shadow
const COLOR_WALL_R = Color("#5a5070")  # Right wall light
const COLOR_BACK = Color("#1e1a29")    # Deep corridor darkness
const COLOR_MORTAR = Color("#181422")  # Stone mortar joints

# Inner doorway percentages (0.0 to 1.0)
const INNER_MIN = Vector2(0.32, 0.25)
const INNER_MAX = Vector2(0.68, 0.75)

func _draw() -> void:
	var screen_size: Vector2 = get_viewport_rect().size

	# 1. Outer screen corners
	var topleft = Vector2.ZERO
	var topright = Vector2(screen_size.x, 0)
	var bottomleft = Vector2(0, screen_size.y)
	var bottomright = screen_size

	# 2. Inner doorway corners
	var _internal_top_left = Vector2(INNER_MIN.x, INNER_MIN.y) * screen_size
	var _internal_top_right = Vector2(INNER_MAX.x, INNER_MIN.y) * screen_size
	var _internal_bottom_left = Vector2(INNER_MIN.x, INNER_MAX.y) * screen_size
	var _internal_bottom_right = Vector2(INNER_MAX.x, INNER_MAX.y) * screen_size

	# 3. Base surface polygons
	draw_polygon(PackedVector2Array([topleft, topright, _internal_top_right, _internal_top_left]), [COLOR_CEILING])
	draw_polygon(PackedVector2Array([_internal_bottom_left, _internal_bottom_right, bottomright, bottomleft]), [COLOR_FLOOR])
	draw_polygon(PackedVector2Array([topleft, _internal_top_left, _internal_bottom_left, bottomleft]), [COLOR_WALL_L])
	draw_polygon(PackedVector2Array([_internal_top_right, topright, bottomright, _internal_bottom_right]), [COLOR_WALL_R])
	draw_polygon(PackedVector2Array([_internal_top_left, _internal_top_right, _internal_bottom_right, _internal_bottom_left]), [COLOR_BACK])

	# 4. Depth rings (horizontal mortar lines for ceiling and floor)
	var depths = [0.4, 0.7]
	for d in depths:
		var ring_tl = topleft.lerp(_internal_top_left, d)
		var ring_tr = topright.lerp(_internal_top_right, d)
		var ring_bl = bottomleft.lerp(_internal_bottom_left, d)
		var ring_br = bottomright.lerp(_internal_bottom_right, d)

		draw_line(ring_tl, ring_tr, COLOR_MORTAR, 2.0) # Ceiling
		draw_line(ring_bl, ring_br, COLOR_MORTAR, 2.0) # Floor

	# 5. Corner seam lines (outer to inner doorway)
	draw_line(topleft, _internal_top_left, COLOR_MORTAR, 3.0)
	draw_line(topright, _internal_top_right, COLOR_MORTAR, 3.0)
	draw_line(bottomleft, _internal_bottom_left, COLOR_MORTAR, 3.0)
	draw_line(bottomright, _internal_bottom_right, COLOR_MORTAR, 3.0)

	# 6. Horizontal stone rows on left and right walls
	var wall_row_heights = [0.33, 0.66]
	for h in wall_row_heights:
		var left_start = topleft.lerp(bottomleft, h)
		var left_end = _internal_top_left.lerp(_internal_bottom_left, h)
		draw_line(left_start, left_end, COLOR_MORTAR, 2.0)

		var right_start = topright.lerp(bottomright, h)
		var right_end = _internal_top_right.lerp(_internal_bottom_right, h)
		draw_line(right_start, right_end, COLOR_MORTAR, 2.0)

	# 7. Staggered vertical seams (subway / Roman block pattern)
	var rows = [
		{"top": 0.0,  "bot": 0.33, "depths": [0.4, 0.7]},
		{"top": 0.33, "bot": 0.66, "depths": [0.20, 0.55, 0.85]},
		{"top": 0.66, "bot": 1.0,  "depths": [0.4, 0.7]}
	]
	for row in rows:
		for d in row.depths:
			draw_wall_joint(d, row.top, row.bot, screen_size)


# Helper: bilinear interpolation to find any 2D point on left or right wall
func get_wall_point(is_left: bool, d: float, h: float, screen_size: Vector2) -> Vector2:
	var _top_left = Vector2.ZERO
	var _top_right = Vector2(screen_size.x, 0)
	var _bottom_left = Vector2(0, screen_size.y)
	var _bottom_right = screen_size

	var _internal_top_left = Vector2(INNER_MIN.x, INNER_MIN.y) * screen_size
	var _internal_top_right = Vector2(INNER_MAX.x, INNER_MIN.y) * screen_size
	var _internal_bottom_left = Vector2(INNER_MIN.x, INNER_MAX.y) * screen_size
	var _internal_bottom_right = Vector2(INNER_MAX.x, INNER_MAX.y) * screen_size

	if is_left:
		var top_at_depth = _top_left.lerp(_internal_top_left, d)
		var bottom_at_depth = _bottom_left.lerp(_internal_bottom_left, d)
		return top_at_depth.lerp(bottom_at_depth, h)
	else:
		var top_at_depth = _top_right.lerp(_internal_top_right, d)
		var bottom_at_depth = _bottom_right.lerp(_internal_bottom_right, d)
		return top_at_depth.lerp(bottom_at_depth, h)


# Helper: draws matching vertical joints on both left and right walls
func draw_wall_joint(d: float, h_top: float, h_bot: float, screen_size: Vector2) -> void:
	for is_left in [true, false]:
		var p_top = get_wall_point(is_left, d, h_top, screen_size)
		var p_bot = get_wall_point(is_left, d, h_bot, screen_size)
		draw_line(p_top, p_bot, COLOR_MORTAR, 2.0)
