extends StaticBody2D
class_name GameContainer

@onready var left_wall: CollisionShape2D = $LeftWall
@onready var right_wall: CollisionShape2D = $RightWall
@onready var floor_shape: CollisionShape2D = $Floor

# Glass styling colors
const COLOR_GLASS_TINT = Color(0.4, 0.75, 1.0, 0.12) # Subtle translucent cyan/blue
const COLOR_GLASS_SHINE = Color(1.0, 1.0, 1.0, 0.25) # White specular reflection
const COLOR_TICK_MARKS = Color(0.9, 0.95, 1.0, 0.5) # Measurement graduation marks

# Returns Vector2(min_x, max_x) for dropper clamping
func get_drop_bounds(margin: float) -> Vector2:
	var left_rect := left_wall.shape as RectangleShape2D
	var right_rect := right_wall.shape as RectangleShape2D
	
	var inner_left := left_wall.global_position.x + (left_rect.size.x / 2.0)
	var inner_right := right_wall.global_position.x - (right_rect.size.x / 2.0)
	
	# Add a margin so kernoj don't spawn clipping inside the wall
	return Vector2(inner_left + margin, inner_right - margin)

# Returns the Y coordinate of the top opening
func get_opening_y() -> float:
	var left_rect := left_wall.shape as RectangleShape2D
	return left_wall.global_position.y - (left_rect.size.y / 2.0)
	
func _draw() -> void:
	# Beaker boundaries (matching your Line2D visual outline)
	var left_x := 430.0
	var right_x := 850.0
	var top_y := 150.0
	var bot_y := 650.0
	var beaker_width := right_x - left_x
	var beaker_height := bot_y - top_y

	# 1. Translucent glass fill inside the beaker
	draw_rect(Rect2(left_x, top_y, beaker_width, beaker_height), COLOR_GLASS_TINT)

	# 2. Specular glass reflections (vertical highlight streaks along the curves)
	# Primary shine along the left wall
	draw_line(Vector2(left_x + 16.0, top_y + 20.0), Vector2(left_x + 16.0, bot_y - 20.0), COLOR_GLASS_SHINE, 3.0)
	# Softer secondary shine next to it
	draw_line(Vector2(left_x + 26.0, top_y + 60.0), Vector2(left_x + 26.0, bot_y - 60.0), Color(1.0, 1.0, 1.0, 0.12), 1.5)
	# Right rim back-reflection
	draw_line(Vector2(right_x - 14.0, top_y + 20.0), Vector2(right_x - 14.0, bot_y - 20.0), Color(1.0, 1.0, 1.0, 0.18), 2.0)

	# 3. Alchemical measurement tick marks (100ml, 200ml, 300ml, 400ml notches)
	var num_ticks := 5
	for i in range(1, num_ticks):
		var tick_y := bot_y - (i * (beaker_height / float(num_ticks)))
		# Draw horizontal notch extending 14px into the beaker from the left wall
		draw_line(Vector2(left_x, tick_y), Vector2(left_x + 14.0, tick_y), COLOR_TICK_MARKS, 2.0)
