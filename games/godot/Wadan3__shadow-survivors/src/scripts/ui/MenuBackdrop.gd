extends Control

var time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("030711"))
	var spacing := 72.0
	var drift := fmod(time * 9.0, spacing)
	for x in range(-72, int(size.x) + 72, int(spacing)):
		draw_line(Vector2(x + drift, 0), Vector2(x + drift, size.y), Color(0.05, 0.48, 0.68, 0.11), 1.0)
	for y in range(-72, int(size.y) + 72, int(spacing)):
		draw_line(Vector2(0, y + drift), Vector2(size.x, y + drift), Color(0.05, 0.48, 0.68, 0.11), 1.0)
	var center := size * Vector2(0.72, 0.5)
	for radius in [310.0, 230.0, 150.0]:
		draw_arc(center, radius + sin(time) * 8.0, time * 0.08, time * 0.08 + PI * 1.4, 64, Color(0.45, 0.08, 0.52, 0.12), 3.0)
	draw_circle(center, 180.0, Color(0.3, 0.02, 0.45, 0.035))

