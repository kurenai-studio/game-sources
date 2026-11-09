extends Control
## Stamina wheel that rides next to a racket, where your eyes already are.
## Fades out when full, shows up as soon as it drains, turns red and blinks when
## low (low stamina = capped power, so heavy balls can't be cancelled).

const C_INK := Color(0.040, 0.050, 0.100)
const C_GOOD := Color(0.980, 0.800, 0.250)
const C_MID := Color(0.960, 0.960, 0.940)
const C_LOW := Color(0.900, 0.080, 0.120)
const RADIUS := 11.0

var value := 1.0           # 0..1
var cap := 1.0             # permanent fatigue ceiling (0..1)
var _alpha := 0.0
var _blink := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(RADIUS * 2.0 + 8.0, RADIUS * 2.0 + 8.0)


func _process(delta: float) -> void:
	var want := 0.0 if value > 0.98 and cap > 0.98 else 1.0
	_alpha = move_toward(_alpha, want, delta * (4.0 if want > _alpha else 1.5))
	_blink += delta
	queue_redraw()


func _draw() -> void:
	if _alpha <= 0.01:
		return
	var c := size * 0.5
	var col := C_GOOD if value > 0.6 else (C_MID if value > 0.3 else C_LOW)
	var a := _alpha
	if value <= 0.3 and fmod(_blink, 0.5) < 0.2:
		a *= 0.35
	draw_circle(c, RADIUS + 3.0, Color(C_INK, 0.75 * _alpha))
	draw_arc(c, RADIUS, 0.0, TAU, 32, Color(0.15, 0.19, 0.32, _alpha), 4.0)
	# the stretch lost to fatigue for good, dark red at the end of the ring
	if cap < 1.0:
		draw_arc(c, RADIUS, -PI * 0.5 + TAU * cap, PI * 1.5, 24, Color(0.45, 0.06, 0.08, _alpha), 4.0)
	# fill clockwise from the top
	draw_arc(c, RADIUS, -PI * 0.5, -PI * 0.5 + TAU * clampf(value, 0.0, 1.0), 32, Color(col, a), 4.0)
