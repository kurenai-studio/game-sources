extends Control
class_name PourFx
## Overlay animasi tuang: menggambar bola-bola yang sedang terbang
## dari mulut tabung sumber ke mulut tabung tujuan mengikuti busur
## parabola, satu per satu dengan jeda kecil. Tidak menerima input
## (mouse_filter ignore) dan tidak mengubah data game — state baru
## di-commit oleh main.gd setelah signal finished.

signal finished

var active: bool = false
var _t: float = 0.0
var _duration: float = 0.45
var _stagger: float = 0.07
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _colors: Array[int] = []
var _radius: float = 32.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func start_pour(from_mouth: Vector2, to_mouth: Vector2, colors: Array[int], radius: float) -> void:
	_from = from_mouth
	_to = to_mouth
	_colors = colors.duplicate()
	_radius = radius
	_t = 0.0
	active = true
	visible = true
	queue_redraw()


func cancel() -> void:
	active = false
	visible = false
	_colors.clear()


func _process(delta: float) -> void:
	if not active:
		return
	_t += delta
	queue_redraw()
	var total := _duration + float(maxi(0, _colors.size() - 1)) * _stagger
	if _t >= total:
		active = false
		visible = false
		finished.emit()


func _draw() -> void:
	if not active:
		return
	var mid := (_from + _to) * 0.5 + Vector2(0, -140)
	for i in range(_colors.size()):
		var p := clampf((_t - float(i) * _stagger) / _duration, 0.0, 1.0)
		var pos := _quad_bezier(_from, mid, _to, p)
		var color: Color = Tube.COLORS[_colors[i]]
		draw_circle(pos, _radius, color)
		draw_arc(pos, _radius, 0, TAU, 32, color.darkened(0.35), 3.0)
		draw_circle(pos + Vector2(-_radius * 0.3, -_radius * 0.3), _radius * 0.28, Color(1, 1, 1, 0.35))


func _quad_bezier(a: Vector2, c: Vector2, b: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * a + 2.0 * u * t * c + t * t * b
