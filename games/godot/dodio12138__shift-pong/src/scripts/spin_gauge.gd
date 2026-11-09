extends Control
## HUD spin gauge. Left: a pseudo-3D ball rolling about its horizontal axis —
## its meridians sweep up for topspin and down for backspin, matching the ↑ / ↓
## icons. Right: the ball seen from above for side spin, spokes turning the real
## way. Both turn at a rate proportional to the rpm, slowed down to follow by eye.

const Icons := preload("res://scripts/icons.gd")
const RATE := 0.035        # displayed rad/s per real rad/s
const MERIDIANS := 6
const MIN_SPIN := 40.0     # below this the gauge reads as a dead ball
const C_INK := Color(0.040, 0.050, 0.100)
const C_WHITE := Color(0.960, 0.960, 0.940)
const C_DIM := Color(0.720, 0.780, 0.860)
const C_BALL := Color(0.15, 0.19, 0.32)

var top := 0.0             # rad/s, + topspin relative to the flight direction
var side := 0.0            # rad/s, + anticlockwise seen from above (left side spin)
var top_color := C_WHITE
var side_color := C_WHITE
var _a := 0.0
var _b := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_a = fposmod(_a + top * RATE * delta, PI)
	_b -= side * RATE * delta
	if modulate.a > 0.0:   # hidden behind the menus: nothing to draw
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(C_INK, 0.8))
	draw_rect(Rect2(Vector2.ZERO, size), C_DIM, false, 2.0)
	var c1 := Vector2(62.0, 52.0)
	var c2 := Vector2(182.0, 52.0)
	rolling_ball(c1, 24.0, _a, top, top_color)
	draw_ball(c2, 22.0, _b, side, side_color, -1.0)

	var k1 := "none"
	if top > MIN_SPIN:
		k1 = "top"
	elif top < -MIN_SPIN:
		k1 = "back"
	badge(Vector2(c1.x - 44.0, size.y - 26.0), k1, absf(top), top_color)
	var k2 := "none"
	if absf(side) > MIN_SPIN:
		k2 = "side_l" if side > 0.0 else "side_r"
	badge(Vector2(c2.x - 44.0, size.y - 26.0), k2, absf(side), side_color)


## Pseudo-3D ball turning about its left-right axis. Each meridian is a great
## circle through the left and right poles, tilted by `phase + k·π/N`; only its
## front half is drawn, brighter the more it faces the viewer. As the phase grows
## the arcs sweep from the bottom over to the top, so topspin reads as rolling up.
func rolling_ball(c: Vector2, r: float, phase: float, spin: float, col: Color) -> void:
	var live := absf(spin) > MIN_SPIN
	draw_circle(c, r, C_BALL)
	draw_circle(c + Vector2(r * 0.08, r * 0.1), r * 0.82, Color(0.12, 0.15, 0.27))   # soft shading
	var arc_col := col if live else C_DIM
	for k in MERIDIANS:
		var phi := fposmod(phase + k * PI / MERIDIANS, PI)
		var facing := sin(phi)                     # 0 at the silhouette, 1 facing us
		var pts := PackedVector2Array()
		for i in 17:
			var t := PI * i / 16.0
			pts.append(c + Vector2(-r * cos(t), r * sin(t) * cos(phi)) * 0.97)
		draw_polyline(pts, Color(arc_col, 0.25 + 0.75 * facing), 1.0 + 2.0 * facing)
	draw_arc(c, r, 0.0, TAU, 32, C_WHITE, 2.0)
	if live:
		# arrow beside the ball: up for topspin, down for backspin
		var dir := -1.0 if spin > 0.0 else 1.0
		var x := c.x + r + 12.0
		draw_line(Vector2(x, c.y - dir * 12.0), Vector2(x, c.y + dir * 8.0), col, 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x, c.y + dir * 15.0), Vector2(x - 6.0, c.y + dir * 7.0), Vector2(x + 6.0, c.y + dir * 7.0)]), col)


## Ball seen from above with spokes turning; `sense` maps the spin sign to the
## on-screen turning direction of `angle`.
func draw_ball(c: Vector2, r: float, angle: float, spin: float, col: Color, sense: float) -> void:
	var live := absf(spin) > MIN_SPIN
	var spoke := col if live else C_DIM
	draw_circle(c, r, C_BALL)
	for k in 3:
		var a := angle + k * TAU / 3.0
		draw_line(c, c + Vector2(cos(a), sin(a)) * (r - 3.0), spoke, 3.0)
	draw_circle(c + Vector2(cos(angle), sin(angle)) * (r - 4.0), 3.5, C_WHITE)
	draw_arc(c, r, 0.0, TAU, 32, C_WHITE, 2.0)
	if not live:
		return
	# curved arrow outside the ball showing the sense of rotation (screen y is down,
	# so a positive angle step is clockwise)
	var dir := signf(spin) * sense
	var start := -PI * 0.85
	var end := -PI * 0.15
	var ar := r + 7.0
	draw_arc(c, ar, start, end, 16, col, 3.0)
	var tip_a := end if dir > 0.0 else start
	var tip := c + Vector2(cos(tip_a), sin(tip_a)) * ar
	var tangent := Vector2(-sin(tip_a), cos(tip_a)) * dir
	var normal := Vector2(cos(tip_a), sin(tip_a))
	draw_colored_polygon(PackedVector2Array([tip + tangent * 8.0, tip + normal * 5.0, tip - normal * 5.0]), col)


## Spin icon plus rpm, or just the "dead ball" icon.
func badge(at: Vector2, kind: String, spin: float, col: Color) -> void:
	var tex := Icons.spin(kind)
	draw_texture_rect(tex, Rect2(at, tex.get_size()), false)
	if kind != "none":
		var font := get_theme_font("font", "Label")
		draw_string(font, at + Vector2(26.0, 15.0), "%d rpm" % int(spin * 60.0 / TAU), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
