extends Control
class_name Tube
## Satu tabung Ball Sort: gambar tabung kaca + bola-bola di dalamnya.
## balls: Array[int] warna, indeks 0 = paling bawah, terakhir = paling atas.
## Tap (sentuh/mouse) -> signal tapped.
## Tabung terpilih naik sedikit + border emas; tabung selesai berkilau emas.

signal tapped(tube: Control)

const CAPACITY: int = 4
const COLORS: Array[Color] = [
	Color(1.00, 0.32, 0.32),
	Color(0.27, 0.85, 0.45),
	Color(0.30, 0.65, 1.00),
	Color(1.00, 0.80, 0.20),
	Color(0.68, 0.45, 0.95),
	Color(1.00, 0.60, 0.20),
	Color(0.25, 0.85, 0.90),
]

var balls: Array[int] = []
var hidden_top: int = 0
var selected: bool = false
var base_x: float = 0.0
var base_y: float = 0.0
var tube_style: StyleBoxFlat


func _ready() -> void:
	custom_minimum_size = Vector2(96, 360)
	mouse_filter = Control.MOUSE_FILTER_STOP
	base_x = position.x
	base_y = position.y
	tube_style = StyleBoxFlat.new()
	tube_style.bg_color = Color(1, 1, 1, 0.07)
	tube_style.set_corner_radius_all(16)
	tube_style.set_border_width_all(3)
	tube_style.border_color = Color(1, 1, 1, 0.5)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		tapped.emit(self)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tapped.emit(self)
		accept_event()


func set_balls(arr: Array) -> void:
	balls.clear()
	for v in arr:
		balls.append(int(v))
	hidden_top = 0
	_refresh_border()
	queue_redraw()


## Sembunyikan N bola teratas saat sedang diterbangkan oleh PourFx.
## Data balls tidak berubah — hanya gambar yang disembunyikan.
func set_hidden_top(n: int) -> void:
	hidden_top = n
	queue_redraw()


func set_selected(value: bool) -> void:
	selected = value
	position.y = base_y - 18.0 if selected else base_y
	_refresh_border()
	queue_redraw()


func _refresh_border() -> void:
	if tube_style == null:
		return
	if selected or is_complete():
		tube_style.border_color = Color(1, 0.85, 0.2, 1)
	else:
		tube_style.border_color = Color(1, 1, 1, 0.5)


func is_empty() -> bool:
	return balls.is_empty()


func is_full() -> bool:
	return balls.size() >= CAPACITY


func top_color() -> int:
	if balls.is_empty():
		return -1
	return balls[balls.size() - 1]


func top_run() -> int:
	if balls.is_empty():
		return 0
	var color := balls[balls.size() - 1]
	var run := 0
	for i in range(balls.size() - 1, -1, -1):
		if balls[i] == color:
			run += 1
		else:
			break
	return run


func is_complete() -> bool:
	if balls.size() != CAPACITY:
		return false
	for v in balls:
		if v != balls[0]:
			return false
	return true


func _draw_star(center: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var angle := -PI / 2.0 + float(i) * PI / 5.0
		var rad := r if i % 2 == 0 else r * 0.45
		points.append(center + Vector2(cos(angle), sin(angle)) * rad)
	draw_colored_polygon(points, color)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var ball_r := (w * 0.5) - 8.0
	var step := ball_r * 2.0 + 6.0
	# Tabung kaca (sudut membulat)
	draw_style_box(tube_style, Rect2(4, 20, w - 8, h - 24))
	if selected:
		# Panah penanda tabung terpilih
		var cx := w * 0.5
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 12, 2), Vector2(cx + 12, 2), Vector2(cx, 14)]), Color(1, 0.85, 0.2, 1))
	if is_complete() and not balls.is_empty():
		# Bintang emas di atas tabung yang selesai
		_draw_star(Vector2(w * 0.5 - 14, 10), 7, Color(1, 0.85, 0.2, 1))
		_draw_star(Vector2(w * 0.5 + 14, 6), 5, Color(1, 0.9, 0.5, 1))
	# Bola-bola, dari bawah ke atas (lewati yang sedang diterbangkan)
	for i in range(balls.size() - hidden_top):
		var center := Vector2(w * 0.5, h - 16.0 - ball_r - float(i) * step)
		var color: Color = COLORS[balls[i]]
		draw_circle(center, ball_r, color)
		draw_arc(center, ball_r, 0, TAU, 32, color.darkened(0.35), 3.0)
		draw_circle(center + Vector2(-ball_r * 0.3, -ball_r * 0.3), ball_r * 0.28, Color(1, 1, 1, 0.35))
