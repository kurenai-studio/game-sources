extends Control
## Hold-strength arc beside your racket: fills as you hold a stroke key, with
## the green band where the incoming ball's spin wants it. White while short of
## the band, green inside it, red once you have gone past (over-hitting).

const C_INK := Color(0.040, 0.050, 0.100)
const C_BAR := Color(0.15, 0.19, 0.32)
const C_WHITE := Color(0.960, 0.960, 0.940)
const C_GOOD := Color(0.35, 0.92, 0.45)
const C_BAD := Color(0.900, 0.080, 0.120)
const RADIUS := 17.0
const A0 := PI * 0.75       # the arc runs from bottom left round the top to bottom right
const A1 := PI * 2.25

var value := 0.0            # 0..1 hold strength
var band := Vector2(-1.0, -1.0)   # the right strength, lo..hi; x < 0 = no ball to answer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(RADIUS * 2.0 + 12.0, RADIUS * 2.0 + 12.0)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	draw_circle(c, RADIUS + 4.0, Color(C_INK, 0.7))
	draw_arc(c, RADIUS, A0, A1, 28, C_BAR, 5.0)
	if band.x >= 0.0:
		draw_arc(c, RADIUS, lerpf(A0, A1, band.x), lerpf(A0, A1, minf(band.y, 1.0)), 12, Color(C_GOOD, 0.45), 5.0)
	var col := C_WHITE
	if band.x >= 0.0:
		col = C_GOOD if value >= band.x and value <= band.y else (C_BAD if value > band.y else C_WHITE)
	if value > 0.0:
		draw_arc(c, RADIUS, A0, lerpf(A0, A1, clampf(value, 0.0, 1.0)), 28, col, 5.0)
