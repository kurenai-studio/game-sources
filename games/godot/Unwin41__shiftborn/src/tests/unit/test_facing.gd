extends TestCase


func test_dominant_axis_picks_the_direction() -> void:
	assert_eq(Facing.from_vector(Vector2(5, 1), Facing.DOWN), Facing.RIGHT)
	assert_eq(Facing.from_vector(Vector2(-5, 1), Facing.DOWN), Facing.LEFT)
	assert_eq(Facing.from_vector(Vector2(1, 5), Facing.UP), Facing.DOWN)
	assert_eq(Facing.from_vector(Vector2(1, -5), Facing.DOWN), Facing.UP)


func test_no_movement_keeps_the_previous_facing() -> void:
	assert_eq(Facing.from_vector(Vector2.ZERO, Facing.LEFT), Facing.LEFT)


func test_animation_names_fall_back_without_directional_frames() -> void:
	var directional := preload("res://assets/sprite_frames/spider.tres")
	var strip := preload("res://assets/sprite_frames/tengu.tres")
	assert_eq(Facing.walk_animation(directional, Facing.UP), &"walk_up")
	assert_eq(Facing.walk_animation(strip, Facing.UP), &"run")
	assert_eq(Facing.idle_animation(directional, Facing.LEFT), &"idle_left")
	assert_eq(Facing.idle_animation(strip, Facing.LEFT), &"idle")
