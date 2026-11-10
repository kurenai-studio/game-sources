class_name StadiumView
extends Node2D
## The stadium behind and under the athletes: sky, clouds, the city, the far
## stand's roof and its crowd of hot dog fans (who bounce on the beat), the ad
## boards, the track and the grass, plus whatever an event puts on the track
## (hurdles, the sand pit, the high-jump bar).
##
## The jumps and the put happen in the infield (`venue` "field"): grass, with
## the far straight of the track across it, and on the grass the event's own
## ground: a runway strip of tartan (`runways`), the high jump's fan, the
## put's concrete circle and its sector lines.
##
## World x is in metres along the track; `cam` is the metre at the left edge of
## the screen. Things further back move slower (parallax). The far lanes are
## drawn a little to the right of the near ones, as if seen from a little to
## the side (OBLIQUE pixels across for every pixel up), and so is anything that
## stands across the lanes.

const ART := "res://assets/art/stadium/"
const PX := 24.0                 ## pixels per metre along the track
const OBLIQUE := 0.4
const PX_UP := 22.0              ## pixels per metre upward

var cam := 0.0                   ## metres at the screen's left edge
var beat := 0.0                  ## beats since the music's first (fractional)
var excite := 0.2                ## 0 calm .. 1 on its feet
var dusk := 0.0                  ## 0 afternoon .. 1 evening (the floodlights come on)
var props: Array = []            ## [{tex, x (m), lane (float), dy, flip}] drawn on the track
var lines: Array = []            ## [{x (m), kind}] start, finish, board
var markers: Array = []          ## [{x (m), text}] distance boards in the infield
var pit: Dictionary = {}         ## {from, to} metres: sand pit along the near lanes
var pits: Array = []             ## more pits: [{from, to, tex}] (the steeplechase's water)
var cam_y := 0.0                 ## the camera risen this many pixels (a high vault)
var venue := "track"             ## track, field (the infield) or pool (water for lanes, a poolside for the grass)
var runways: Array = []          ## [{from, to, far, near (lanes)}] tartan on the infield's grass
var sector := false              ## the put's sector lines, fanning out from its circle
var time := 0.0

var _tex: Dictionary = {}
var _meta: Dictionary = {}
var _fans: Texture2D
var _fan_meta: Dictionary = {}
var _boards: Dictionary = {}


func _ready() -> void:
	for n in ["sky", "sky_dusk", "clouds", "city", "roof", "stands", "wall", "track", "infield", "sandpit", "board",
			"hurdle", "hurdle_down", "finish_post", "barrier", "water_pit", "springboard", "meatball", "swim_lanes",
			"pool_deck", "field", "infield_plain"]:
		var p: String = ART + String(n) + ".png"
		if ResourceLoader.exists(p):
			_tex[n] = load(p)
	var f := FileAccess.open(ART + "stadium.json", FileAccess.READ)
	_meta = JSON.parse_string(f.get_as_text()) if f else {}
	_fans = load("res://assets/art/crowd/fans.png")
	var g := FileAccess.open("res://assets/art/crowd/fans.json", FileAccess.READ)
	_fan_meta = JSON.parse_string(g.get_as_text()) if g else {}
	for m in range(10, 120, 10):
		var p: String = ART + ("dist_%d.png" % m)
		if ResourceLoader.exists(p):
			_boards[m] = load(p)


func size() -> Vector2:
	return get_viewport_rect().size


# -- where things are ---------------------------------------------------------------

func infield_y() -> float:
	return size().y - float(_meta.get("infield_h", 48)) + cam_y


func track_y() -> float:
	return infield_y() - float(_meta.get("track_h", 64))


func wall_y() -> float:
	return track_y() - float(_meta.get("wall_h", 18))


func stands_y() -> float:
	return wall_y() - float(_meta.get("stands_h", 64))


func roof_y() -> float:
	return stands_y() - 60.0


## Screen y of the middle of a lane (0 = far lane .. 3 = near lane); fractional
## lanes are fine (the pit, the high-jump bar).
func lane_y(lane: float) -> float:
	var c: Array = _meta.get("lane_centres", [9.0, 22.0, 37.0, 54.0])
	var i := clampi(int(floor(lane)), 0, c.size() - 1)
	var j := clampi(i + 1, 0, c.size() - 1)
	var f := clampf(lane - i, 0.0, 1.0)
	return track_y() + lerpf(float(c[i]), float(c[j]), f)


## How far right the far lanes sit (pixels), for a screen y.
func oblique(y: float) -> float:
	return (infield_y() - y) * OBLIQUE


## Screen x of a world metre at a screen y.
func screen_x(m: float, y: float) -> float:
	return (m - cam) * PX + oblique(y)


# -- drawing ----------------------------------------------------------------------

func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _tile(tex: Texture2D, offset: float, y: float, mod := Color.WHITE) -> void:
	if tex == null:
		return
	var w := float(tex.get_width())
	var x := -fposmod(offset, w)
	var sw := size().x
	while x < sw:
		draw_texture(tex, Vector2(roundf(x), roundf(y)), mod)
		x += w


func _draw() -> void:
	var s := size()
	var camp := cam * PX
	# sky: the afternoon one, with evening laid over it as the day goes
	var sky: Texture2D = _tex.get("sky")
	if sky:
		draw_texture_rect(sky, Rect2(0, minf(0.0, stands_y() - 200.0), s.x, maxf(stands_y() + 4, 204.0)), false)
	if dusk > 0.0 and _tex.has("sky_dusk"):
		draw_texture_rect(_tex.sky_dusk, Rect2(0, minf(0.0, stands_y() - 200.0), s.x, maxf(stands_y() + 4, 204.0)), false,
			Color(1, 1, 1, dusk))
	if roof_y() > 0.0:
		draw_rect(Rect2(0, 0, s.x, roof_y()), Color(0, 0, 0, 0))
	_tile(_tex.get("clouds"), camp * 0.04 + time * 3.0, roof_y() - 36.0, Color(1, 1, 1, 1.0 - dusk * 0.5))
	_tile(_tex.get("city"), camp * 0.08, roof_y() - 18.0, Color(1, 1, 1).lerp(Color(0.6, 0.5, 0.8), dusk))
	var shade := Color(1, 1, 1).lerp(Color(0.62, 0.6, 0.8), dusk)
	_tile(_tex.get("roof"), camp * 0.35, roof_y(), shade)
	_tile(_tex.get("stands"), camp * 0.35, stands_y(), shade)
	_draw_crowd(camp * 0.35, shade)
	if dusk > 0.05:
		_draw_floodlights(camp * 0.35, dusk)
	_tile(_tex.get("wall"), camp * 0.95, wall_y())
	_tile(_tex.get({"pool": "swim_lanes", "field": "field"}.get(venue, "track")), camp, track_y())
	for r in runways:
		_draw_runway(r)
	if sector:
		_draw_sector()
	if not pit.is_empty():
		_draw_pit(pit.from, pit.to, _tex.get("sandpit"))
	for pt in pits:
		_draw_pit(float(pt.from), float(pt.to), _tex.get(String(pt.get("tex", "water_pit"))))
	for l in lines:
		_draw_line(l)
	_tile(_tex.get({"pool": "pool_deck", "field": "infield_plain"}.get(venue, "infield")), camp, infield_y())
	for m in markers:
		_draw_marker(m)
	var sorted := props.duplicate()
	sorted.sort_custom(func(a, b): return float(a.get("lane", 0)) < float(b.get("lane", 0)))
	for p in sorted:
		_draw_prop(p)


func _draw_crowd(offset: float, shade: Color) -> void:
	if _fans == null:
		return
	var cell: Array = _fan_meta.get("cell", [14, 22])
	var cols := int(_fan_meta.get("cols", 16))
	var count := int(_fan_meta.get("fans", 24))
	var foot: Array = _fan_meta.get("foot", [7, 20])
	var rows: Array = _meta.get("stand_rows", [])
	var gap := 13.0
	var s := size()
	var tint := Color(0.72, 0.72, 0.88).lerp(Color(0.9, 0.9, 1.0), excite * 0.5) * shade
	var y0 := stands_y()
	var beat_f := fposmod(beat, 1.0)
	for r in rows.size():
		var ry := y0 + float(rows[r])
		var first := int(floor(offset / gap)) - 1
		var col := first
		while true:
			var x := col * gap - offset + (r % 2) * 6.0
			if x > s.x:
				break
			col += 1
			var h := _hash(col, r)
			if h % 100 < 34:
				continue                      # an empty seat
			var fan := (h / 7) % count
			var kind := 0
			var hop := 0.0
			var lively := (h / 13) % 100 < int(25 + excite * 70)
			if lively:
				var ph := float((h / 3) % 4) * 0.25 if excite < 0.6 else 0.0
				var bf := fposmod(beat_f + ph, 1.0)
				if bf < 0.12:
					kind = 1
				elif bf < 0.5:
					kind = 2 if excite > 0.5 else 0
					hop = sin(bf / 0.5 * PI) * (1.0 + excite * 3.0)
				if excite > 0.7 and (h / 17) % 3 == 0:
					kind = 3 if kind == 0 else kind
			var idx := fan * 4 + kind
			var src := Rect2((idx % cols) * float(cell[0]), (idx / cols) * float(cell[1]), float(cell[0]), float(cell[1]))
			var at := Vector2(roundf(x - float(foot[0])), roundf(ry - float(foot[1]) - hop))
			draw_texture_rect_region(_fans, Rect2(at, Vector2(float(cell[0]), float(cell[1]))), src, tint)


static func _hash(a: int, b: int) -> int:
	var h := (a * 73856093) ^ (b * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


func _draw_line(l: Dictionary) -> void:
	var top := track_y() + float(_meta.get("track_edge", 3))
	var bot := infield_y()
	var x0 := screen_x(float(l.x), bot)
	var x1 := screen_x(float(l.x), top)
	var col := Color(1, 0.98, 0.94)
	var kind := String(l.get("kind", "line"))
	var w := 2.0
	if kind == "board":
		col = Color(1, 0.98, 0.94)
		w = 4.0
	elif kind == "box":
		col = Color("f7d331")
	elif kind == "circle":
		_draw_circle(float(l.x))
		return
	elif kind == "mark":
		col = Color(1, 0.98, 0.94, 0.6)
		w = 1.0
	elif kind == "record" or kind == "qual":
		col = Color("ffd25a") if kind == "record" else Color(1, 0.98, 0.94, 0.85)
		w = 1.0
		# only across the near lanes (where the jumping and putting happens), with a flag
		var fy := lane_y(1.0) - 6.0
		var fx := screen_x(float(l.x), fy)
		var n := int(bot - fy)
		for i in n:
			var y2 := bot - i - 1
			if kind == "qual" and (i / 2) % 2 == 0:
				continue
			draw_rect(Rect2(roundf(lerpf(screen_x(float(l.x), bot), fx, float(i) / n)), y2, 1, 1), col)
		draw_rect(Rect2(roundf(fx), roundf(fy - 12), 1, 12), Color("e0e0ee"))
		draw_rect(Rect2(roundf(fx) + 1, roundf(fy - 12), 9, 6), col)
		var f := Kit.font("small")
		draw_string(f, Vector2(roundf(fx) + 11, roundf(fy - 6)), String(l.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)
		return
	var steps := int(bot - top)
	for i in steps:
		var y := bot - i - 1
		var x := lerpf(x0, x1, float(i) / steps)
		if kind == "mark" and (i / 3) % 2 == 0:
			continue
		if kind == "finish" and (i / 2) % 2 == 0:
			draw_rect(Rect2(roundf(x), y, w + 2, 1), Color(0.14, 0.08, 0.18))
		else:
			draw_rect(Rect2(roundf(x), y, w, 1), col)
	if kind == "finish" and _tex.has("finish_post"):
		var post: Texture2D = _tex.finish_post
		draw_texture(post, Vector2(roundf(x1 - 4), roundf(top - post.get_height() + 2)))


func _draw_pit(a: float, b: float, tex: Texture2D) -> void:
	if tex == null:
		return
	var top := lane_y(1.0) - 6.0
	# the pit is drawn row by row so its ends lean with the lanes
	for row in tex.get_height():
		var y := top + row
		var x0 := screen_x(a, y)
		var x1 := screen_x(b, y)
		if x1 < 0 or x0 > size().x:
			continue
		var cx0 := maxf(x0, 0.0)
		var cx1 := minf(x1, size().x)
		var u := fposmod(cx0 - x0, float(tex.get_width()))
		var x := cx0
		while x < cx1:
			var span := minf(float(tex.get_width()) - u, cx1 - x)
			draw_texture_rect_region(tex, Rect2(roundf(x), y, span, 1), Rect2(u, row, span, 1))
			x += span
			u = 0.0
		draw_rect(Rect2(roundf(x0) - 2, y, 2, 1), Color(0.6, 0.37, 0.23))
		draw_rect(Rect2(roundf(x1), y, 2, 1), Color(0.6, 0.37, 0.23))


func _draw_marker(m: Dictionary) -> void:
	if m.has("text"):
		var f := Kit.font("small")
		var txt := String(m.text)
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 6
		var y := infield_y() + 8.0
		var x := roundf(screen_x(float(m.x), infield_y()) - w / 2.0)
		if x < -40 or x > size().x + 40:
			return
		draw_rect(Rect2(x + w / 2 - 1, y + 10, 2, 11), Color("a0a0b8"))
		draw_rect(Rect2(x, y, w, 11), Color("24152e"))
		draw_rect(Rect2(x + 1, y + 1, w - 2, 9), Color("fffaf0"))
		draw_string(f, Vector2(x + 3, y + 9), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("24152e"))
		return
	var tex: Texture2D = _boards.get(int(m.get("m", 0)))
	if tex == null:
		return
	var y := infield_y() + 8.0
	var x := screen_x(float(m.x), infield_y()) - tex.get_width() / 2.0
	if x < -40 or x > size().x + 40:
		return
	draw_texture(tex, Vector2(roundf(x), roundf(y)))


func _draw_prop(p: Dictionary) -> void:
	if p.get("kind", "") == "high":
		_draw_high(p)
		return
	var tex: Texture2D = p.get("tex")
	if tex == null:
		tex = _tex.get(String(p.get("name", "")))
	if tex == null:
		return
	var y := lane_y(float(p.get("lane", 3.0))) + float(p.get("dy", 0.0))
	var x := screen_x(float(p.x), y) + float(p.get("dx", 0.0))
	if x < -60 or x > size().x + 60:
		return
	var foot: Vector2 = p.get("foot", Vector2(7, tex.get_height() - 2))
	draw_texture(tex, Vector2(roundf(x - foot.x), roundf(y - foot.y)), p.get("mod", Color.WHITE))


## The high jump: the blue landing mat, two uprights and the bar between them.
func _draw_high(p: Dictionary) -> void:
	var bar := float(p.bar)
	var near := lane_y(3.4)
	var far := lane_y(1.4)
	var mat_from := float(p.get("mat_from", 0.3))
	var mat_to := float(p.get("mat_to", 4.6))
	var mh := float(p.get("mat_h", 0.7)) * PX_UP
	if p.has("board_x") and _tex.has("springboard"):
		var sb: Texture2D = _tex.springboard
		var by := lane_y(2.5)
		draw_texture(sb, Vector2(roundf(screen_x(float(p.board_x), by) - 4), roundf(by - sb.get_height() + 3)))
	var blue := [Color("141a4a"), Color("233a96"), Color("3a5ad2"), Color("6a8af0"), Color("a4baff")]
	# the mat: its top, then its front face
	var y := far
	while y <= near:
		var x0 := screen_x(mat_from, y)
		var x1 := screen_x(mat_to, y)
		var lit := 3 if y < far + 3 else 2
		draw_rect(Rect2(roundf(x0), roundf(y - mh), roundf(x1 - x0), 1), blue[lit])
		y += 1.0
	var fx0 := screen_x(mat_from, near)
	var fx1 := screen_x(mat_to, near)
	draw_rect(Rect2(roundf(fx0), roundf(near - mh), roundf(fx1 - fx0), roundf(mh)), blue[1])
	draw_rect(Rect2(roundf(fx0), roundf(near - mh), roundf(fx1 - fx0), 1), blue[4])
	draw_rect(Rect2(roundf(fx0), roundf(near), roundf(fx1 - fx0), 1), blue[0])
	for k in range(int(fx0) + 6, int(fx1) - 2, 12):
		draw_rect(Rect2(k, roundf(near - mh + 4), 1, roundf(mh - 6)), blue[0])
	# uprights and bar
	var h := bar * PX_UP
	var top := h + 10.0
	var steel := [Color("1e1e2e"), Color("6a6a86"), Color("e0e0ee")]
	for yy in [far, near]:
		var x := screen_x(-0.05, yy)
		if yy == near:
			continue
		draw_rect(Rect2(roundf(x) - 1, roundf(yy - top), 3, roundf(top)), steel[0])
		draw_rect(Rect2(roundf(x), roundf(yy - top), 1, roundf(top)), steel[2])
	var a := Vector2(screen_x(-0.05, near), near - h)
	var b := Vector2(screen_x(-0.05, far), far - h)
	if p.get("down", false):
		a = Vector2(screen_x(0.6, near), near - mh - 1)
		b = Vector2(screen_x(0.2, far), far - mh - 1)
	var n := int(a.distance_to(b))
	for i in n + 1:
		var q := a.lerp(b, float(i) / maxf(n, 1)).round()
		var striped := (i / 4) % 2 == 0
		draw_rect(Rect2(q, Vector2(1, 2)), Color("fffaf0") if striped else Color("e0383a"))
		draw_rect(Rect2(q + Vector2(0, 2), Vector2(1, 1)), Color("24152e"))
	var xn := screen_x(-0.05, near)
	draw_rect(Rect2(roundf(xn) - 1, roundf(near - top), 3, roundf(top)), steel[0])
	draw_rect(Rect2(roundf(xn), roundf(near - top), 1, roundf(top)), steel[2])
	# the height, on a little board by the near upright
	var f := Kit.font("small")
	var txt := "%.2fm" % bar
	draw_rect(Rect2(roundf(xn) - 14, roundf(near - top - 12), 30, 11), Color("24152e"))
	draw_string(f, Vector2(roundf(xn) - 12, roundf(near - top - 3)), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("ffd060"))


## A strip of tartan on the grass, row by row so its ends lean with the
## view, with a white line down each edge.
func _draw_runway(r: Dictionary) -> void:
	var y0 := roundf(lane_y(float(r.get("far", 1.9))))
	var y1 := roundf(lane_y(float(r.get("near", 3.1))))
	var tartan := [Color("8e3434"), Color("bc4c3c"), Color("d86a48")]
	for y in range(int(y0), int(y1) + 1):
		var x0 := roundf(screen_x(float(r.from), y))
		var x1 := roundf(screen_x(float(r.to), y))
		if x1 < 0 or x0 > size().x:
			continue
		var edge := y == int(y0) or y == int(y1)
		draw_rect(Rect2(x0, y, x1 - x0, 1), Color("fffaf0") if edge else tartan[1])
		if edge:
			continue
		# its grain: a sprinkle of darker and lighter, fixed to the ground
		var m0 := int(floor(cam * PX)) - 2
		for k in range(int(maxf(x0, 0.0)), int(minf(x1, size().x)), 3):
			var hsh := _hash(k + m0, y)
			if hsh % 13 == 0:
				draw_rect(Rect2(k, y, 1, 1), tartan[0])
			elif hsh % 17 == 0:
				draw_rect(Rect2(k, y, 1, 1), tartan[2])


## The put's sector: two dotted lines fanning out from the circle across the
## grass.
func _draw_sector() -> void:
	var c := Vector2(screen_x(-1.07, lane_y(2.5)), lane_y(2.5))
	for far_lane in [0.6, 4.4]:
		var fl: float = far_lane
		var end_y: float = lane_y(clampf(fl, 0.0, 3.0)) + (fl - clampf(fl, 0.0, 3.0)) * 22.0
		var end := Vector2(screen_x(30.0, end_y), end_y)
		var n := int(c.distance_to(end))
		for i in range(0, n, 3):
			var p := c.lerp(end, float(i) / n).round()
			if p.x > size().x or p.y < track_y():
				continue
			draw_rect(Rect2(p, Vector2(2, 1)), Color(1, 0.98, 0.94, 0.85))


## The meatball put's circle, painted on the ground where the thrower stands
## (its front edge at x), on its concrete pad.
func _draw_circle(x: float) -> void:
	var y := lane_y(2.5)
	var r := 1.07 * PX
	var c := Vector2(screen_x(x - 1.07, y), y)
	var pad: PackedVector2Array = []
	for i in 32:
		var a := TAU * i / 32
		pad.append((c + Vector2(cos(a) * (r + 6), sin(a) * (r + 6) * 0.3)).round())
	draw_colored_polygon(pad, Color("a8a6ba"))
	var inner: PackedVector2Array = []
	for i in 32:
		var a := TAU * i / 32
		inner.append((c + Vector2(cos(a) * r, sin(a) * r * 0.3)).round())
	draw_colored_polygon(inner, Color("7a7690"))
	var n := 64
	for i in n:
		var a := TAU * i / n
		var p := (c + Vector2(cos(a) * r, sin(a) * r * 0.3)).round()
		draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 0.98, 0.94))
	draw_rect(Rect2(roundf(c.x + r - 1), roundf(y - 4), 2, 8), Color(1, 0.98, 0.94))   # the stop board


func _draw_floodlights(offset: float, k: float) -> void:
	var ry := roof_y()
	var sw := size().x
	var pitch := 180.0
	var first := int(floor(offset / pitch)) - 1
	var col := Color(1.0, 0.96, 0.8, 0.08 * k)
	for i in range(first, first + int(sw / pitch) + 3):
		var lx := roundf(i * pitch - offset + 40.0)
		var pts := PackedVector2Array([
			Vector2(lx - 8, ry + 2),
			Vector2(lx + 8, ry + 2),
			Vector2(lx + 54, track_y()),
			Vector2(lx - 54, track_y()),
		])
		draw_colored_polygon(pts, col)
