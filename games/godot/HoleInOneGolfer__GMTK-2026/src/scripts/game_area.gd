extends Node2D

@export var grid_size: float = 64.0

@export_category("Background")
@export var draw_background: bool = true
@export var background_color: Color = Color(0.15, 0.15, 0.18, 1.0)

@export_category("Dots")
@export var draw_dots: bool = true
@export var dot_radius: float = 2.0
@export var dot_color: Color = Color(0.2, 0.2, 0.3, 0.5)

@export_category("Lines")
@export var draw_lines: bool = true
@export var line_width: float = 1.0
@export var line_color: Color = Color(0.2, 0.2, 0.3, 0.2)

@export var follow_camera: bool = true

var _last_grid_offset: Vector2 = Vector2.INF

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and follow_camera:
		var cam_pos = cam.get_screen_center_position()
		# Snap the grid position to grid chunks so it only updates when crossing lines
		var current_grid_offset = Vector2(
			floor(cam_pos.x / grid_size),
			floor(cam_pos.y / grid_size)
		)
		
		if current_grid_offset != _last_grid_offset:
			_last_grid_offset = current_grid_offset
			queue_redraw()
	elif not follow_camera:
		set_process(false)

func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	var top_left := Vector2.ZERO
	var screen_size := get_viewport_rect().size
	
	if cam:
		top_left = cam.get_screen_center_position() - (screen_size / 2.0)
	else:
		top_left = global_position
		
	if draw_background:
		draw_rect(Rect2(top_left, screen_size), background_color)
		
	var start_x = floor(top_left.x / grid_size) * grid_size
	var start_y = floor(top_left.y / grid_size) * grid_size
	
	var end_x = top_left.x + screen_size.x + grid_size
	var end_y = top_left.y + screen_size.y + grid_size
	
	if draw_lines:
		var x = start_x
		while x < end_x:
			draw_line(Vector2(x, start_y), Vector2(x, end_y), line_color, line_width)
			x += grid_size
			
		var y = start_y
		while y < end_y:
			draw_line(Vector2(start_x, y), Vector2(end_x, y), line_color, line_width)
			y += grid_size

	if draw_dots:
		var x = start_x
		while x < end_x:
			var y = start_y
			while y < end_y:
				draw_circle(Vector2(x, y), dot_radius, dot_color)
				y += grid_size
			x += grid_size
