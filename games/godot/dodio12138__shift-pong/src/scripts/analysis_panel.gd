extends Control
## Game analysis (数据分析面板), opened with I during a match and after each game:
## where both players stood when they hit (heat maps of each half), where
## their balls landed (a top view of the table), a head-to-head of the match's
## technical stats, what strokes they played (forehand / backhand, timing,
## stroke mix) and how the score went point by point. Reads the game's data
## straight off the main script (`main.gstats`, `main.mstats`).

const C_INK := Color(0.040, 0.050, 0.100)
const C_PANEL := Color(0.070, 0.090, 0.200)
const C_BAR := Color(0.15, 0.19, 0.32)
const C_WHITE := Color(0.960, 0.960, 0.940)
const C_DIM := Color(0.720, 0.780, 0.860)
const C_YELLOW := Color(0.980, 0.800, 0.250)
const C_RED := Color(0.900, 0.080, 0.120)
const C_BLUE := Color(0.420, 0.820, 0.980)
const C_TABLE := Color(0.100, 0.330, 0.660)
const C_FLOOR := Color(0.360, 0.070, 0.085)
const W := 920.0
const H := 540.0

var main
var embedded := false     # shown inside the coach's tablet: no "close" hint


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var m = main
	var gs: Dictionary = m.gstats
	if gs.is_empty():
		return
	var font := get_theme_font("font", "Label")
	var o := ((size - Vector2(W, H)) * 0.5).floor()
	draw_rect(Rect2(Vector2.ZERO, size), Color(C_INK, 0.55))
	draw_rect(Rect2(o, Vector2(W, H)), Color(C_INK, 0.95))
	draw_rect(Rect2(o, Vector2(W, H)), C_DIM, false, 2.0)
	var P: int = m.PLAYER
	var A: int = m.AI
	var names := [str(m.pname[P]), str(m.pname[A])]
	_text(font, o + Vector2(16.0, 28.0), "第 %d 局 · 数据分析" % (m.games[P] + m.games[A] + (0 if m.game_over or gs.get("done", false) else 1)), 24, C_YELLOW)
	_text(font, o + Vector2(330.0, 26.0), "%s  %d : %d  %s" % [names[0], m.score[P], m.score[A], names[1]], 12, C_WHITE)
	if not embedded:
		_text(font, o + Vector2(W - 150.0, 26.0), "按 I / Esc 关闭", 12, C_DIM)

	# ---- left column: where they stood, where it landed
	_text(font, o + Vector2(16.0, 58.0), "站位热力图（击球时的位置）", 12, C_YELLOW)
	_heat(o + Vector2(16.0, 66.0), Vector2(200.0, 120.0), gs.pos[A], A, names[1], C_BLUE, font)
	_heat(o + Vector2(16.0, 196.0), Vector2(200.0, 120.0), gs.pos[P], P, names[0], C_RED, font)
	_text(font, o + Vector2(236.0, 58.0), "落点分布", 12, C_YELLOW)
	_landings(o + Vector2(236.0, 66.0), Vector2(150.0, 250.0), gs.land, P, A)
	draw_circle(o + Vector2(240.0, 330.0), 3.5, C_RED)
	_text(font, o + Vector2(248.0, 334.0), "%s 的落点" % names[0], 12, C_DIM)
	draw_circle(o + Vector2(318.0, 330.0), 3.5, C_BLUE)
	_text(font, o + Vector2(326.0, 334.0), "%s" % names[1], 12, C_DIM)
	# score flow
	_text(font, o + Vector2(16.0, 362.0), "比分走势（领先分差）", 12, C_YELLOW)
	_flow(o + Vector2(16.0, 370.0), Vector2(370.0, 150.0), gs.flow, font)

	# ---- right column: head to head
	var x := o.x + 410.0
	var y := o.y + 58.0
	_text(font, Vector2(x, y), "技术对比（本场）", 12, C_YELLOW)
	_text(font, Vector2(x + 150.0, y), names[0], 12, C_RED)
	_text(font, Vector2(x + 400.0, y), names[1], 12, C_BLUE)
	var ms: Dictionary = m.mstats
	var rows := []
	if not ms.is_empty():
		rows = [["得分", ms[P].pts, ms[A].pts, ""],
				["主动得分", ms[P].winners, ms[A].winners, ""],
				["失误送分", ms[P].errors, ms[A].errors, ""],
				["发球轮得分率", _pct(ms[P].serve_w, ms[P].serve_n), _pct(ms[A].serve_w, ms[A].serve_n), "%"],
				["接发轮得分率", _pct(ms[P].recv_w, ms[P].recv_n), _pct(ms[A].recv_w, ms[A].recv_n), "%"]]
	rows.append(["平均球速", _avg(gs.speed[P]), _avg(gs.speed[A]), "m/s"])
	rows.append(["最快球速", _max(gs.speed[P]), _max(gs.speed[A]), "m/s"])
	rows.append(["平均转速", _avg(gs.spin[P]), _avg(gs.spin[A]), "rpm"])
	for i in rows.size():
		_versus(font, Vector2(x, y + 12.0 + i * 22.0), rows[i])
	y += 12.0 + rows.size() * 22.0 + 14.0
	_text(font, Vector2(x, y), "击球构成（本局）", 12, C_YELLOW)
	y += 8.0
	for k in 2:
		var side: int = P if k == 0 else A
		var col: Color = C_RED if k == 0 else C_BLUE
		var wg: Dictionary = gs.wing[side]
		var tm: Dictionary = gs.timing[side]
		var n_w: int = wg.fh + wg.bh
		_text(font, Vector2(x, y + 14.0), names[k], 12, col)
		_split(font, Vector2(x + 70.0, y + 4.0), 220.0, [["正手", wg.fh], ["反手", wg.bh]], [col, col.darkened(0.45)])
		_split(font, Vector2(x + 300.0, y + 4.0), 200.0, [["上升", tm.early], ["高点", tm.peak], ["下降", tm.late]],
				[C_YELLOW, C_WHITE, C_DIM])
		var shots: Dictionary = gs.shots[side]
		var keys := shots.keys()
		keys.sort_custom(func(a, b): return shots[a] > shots[b])
		var parts := []
		for s in keys.slice(0, 5):
			parts.append("%s %d" % [s, shots[s]])
		_text(font, Vector2(x + 70.0, y + 34.0), "  ".join(PackedStringArray(parts)) if n_w > 0 else "还没有击球", 12, C_DIM)
		y += 48.0
	if gs.has("skills") and (gs.skills[P] > 0 or gs.skills[A] > 0):
		_text(font, Vector2(x, y + 12.0), "技能使用  %s %d 次 · %s %d 次" % [names[0], gs.skills[P], names[1], gs.skills[A]], 12, C_DIM)
	# the coach's takeaway, for a game you played yourself
	if gs.has("lost") and m.is_human(P):
		var ty := o.y + H - 74.0
		draw_rect(Rect2(Vector2(x - 6.0, ty - 16.0), Vector2(W - 410.0 - 10.0, 64.0)), Color(C_PANEL, 0.9))
		_text(font, Vector2(x, ty), "教练提示", 12, C_YELLOW)
		draw_multiline_string(font, Vector2(x, ty + 18.0), m.coach_tip(), HORIZONTAL_ALIGNMENT_LEFT, W - 410.0 - 24.0, 12, 3, C_WHITE)


func _text(font: Font, at: Vector2, s: String, size_: int, col: Color) -> void:
	draw_string(font, at, tr(s), HORIZONTAL_ALIGNMENT_LEFT, -1, size_, col)


## Heat map of one half: 8 x 5 cells over x -1.6..1.6 and 0.3..3.0 m behind the
## table end; the table edge drawn on the side nearest the net.
func _heat(at: Vector2, sz: Vector2, pts: Array, side: int, title: String, col: Color, font: Font) -> void:
	draw_rect(Rect2(at, sz), C_FLOOR)
	var cols := 8
	var rows := 5
	var grid := []
	grid.resize(cols * rows)
	grid.fill(0)
	var peak := 1
	for p in pts:
		var cx := clampi(int((p.x + 1.6) / 3.2 * cols), 0, cols - 1)
		var depth: float = absf(p.y) - 0.3
		var cy := clampi(int(depth / 2.7 * rows), 0, rows - 1)
		if side < 0:
			cy = rows - 1 - cy   # far side: the net is at the bottom of its map
		var i := cy * cols + cx
		grid[i] += 1
		peak = maxi(peak, grid[i])
	var cw := sz.x / cols
	var ch := sz.y / rows
	for i in grid.size():
		if grid[i] > 0:
			draw_rect(Rect2(at + Vector2((i % cols) * cw, (i / cols) * ch), Vector2(cw - 1.0, ch - 1.0)), Color(col, 0.2 + 0.8 * grid[i] / peak))
	# the table end, on the net side
	var ty := at.y if side > 0 else at.y + sz.y - 3.0
	draw_rect(Rect2(Vector2(at.x + sz.x * 0.26, ty), Vector2(sz.x * 0.48, 3.0)), C_TABLE)
	draw_rect(Rect2(at, sz), C_DIM, false, 1.0)
	draw_string(font, at + Vector2(4.0, 14.0 if side < 0 else sz.y - 4.0), tr("%s · %d 次" % [title, pts.size()]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_WHITE)


## Top view of the table: your balls land on the far half (top), theirs on
## the near half (bottom).
func _landings(at: Vector2, sz: Vector2, land: Dictionary, P: int, A: int) -> void:
	draw_rect(Rect2(at, sz), C_TABLE)
	draw_rect(Rect2(at, sz), C_WHITE, false, 2.0)
	draw_line(at + Vector2(sz.x * 0.5, 0.0), at + Vector2(sz.x * 0.5, sz.y), C_WHITE, 1.0)
	draw_rect(Rect2(at + Vector2(-4.0, sz.y * 0.5 - 1.0), Vector2(sz.x + 8.0, 3.0)), C_DIM)   # the net
	for side in [P, A]:
		for p in land[side]:
			var u := Vector2((p.x + 0.7625) / 1.525, (p.y + 1.37) / 2.74)   # z -1.37 (far) .. 1.37 (near)
			draw_circle(at + u * sz, 3.0, C_RED if side == P else C_BLUE)


## The lead (your points minus theirs) after every point.
func _flow(at: Vector2, sz: Vector2, flow: Array, font: Font) -> void:
	draw_rect(Rect2(at, sz), Color(C_PANEL, 0.8))
	var mid := at.y + sz.y * 0.5
	draw_line(Vector2(at.x, mid), Vector2(at.x + sz.x, mid), C_BAR, 1.0)
	if flow.is_empty():
		draw_string(font, at + Vector2(8.0, 20.0), tr("还没有得分"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_DIM)
		return
	var span := 4
	for d in flow:
		span = maxi(span, absi(d))
	var step := sz.x / maxf(flow.size(), 1.0)
	var prev := Vector2(at.x, mid)
	for i in flow.size():
		var p := Vector2(at.x + (i + 1) * step, mid - float(flow[i]) / span * (sz.y * 0.45))
		draw_line(prev, p, C_RED if flow[i] > 0 else (C_BLUE if flow[i] < 0 else C_WHITE), 2.0)
		prev = p
	draw_string(font, at + Vector2(4.0, 14.0), tr("领先"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_RED)
	draw_string(font, at + Vector2(4.0, sz.y - 4.0), tr("落后"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_BLUE)


## One head-to-head row: label, both values and a split bar.
func _versus(font: Font, at: Vector2, row: Array) -> void:
	var a: float = row[1]
	var b: float = row[2]
	var unit: String = row[3]
	draw_string(font, at + Vector2(0.0, 12.0), tr(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_DIM)
	var fmt := "%.0f" if unit in ["", "%", "rpm"] else "%.1f"
	draw_string(font, at + Vector2(110.0, 12.0), tr((fmt % a) + unit), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_WHITE)
	draw_string(font, at + Vector2(440.0, 12.0), tr((fmt % b) + unit), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_WHITE)
	var r := Rect2(at + Vector2(190.0, 3.0), Vector2(240.0, 9.0))
	draw_rect(r, C_BAR)
	if a + b > 0.0:
		var k := a / (a + b)
		draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), C_RED)
		draw_rect(Rect2(r.position + Vector2(r.size.x * k, 0.0), Vector2(r.size.x * (1.0 - k), r.size.y)), C_BLUE)


## A stacked bar of shares with their labels.
func _split(font: Font, at: Vector2, width: float, parts: Array, cols: Array) -> void:
	var total := 0
	for p in parts:
		total += int(p[1])
	draw_rect(Rect2(at, Vector2(width, 12.0)), C_BAR)
	if total == 0:
		return
	var x := at.x
	for i in parts.size():
		var wv: float = width * float(parts[i][1]) / total
		if wv <= 0.0:
			continue
		draw_rect(Rect2(Vector2(x, at.y), Vector2(wv, 12.0)), cols[i])
		var lab := "%s %d%%" % [parts[i][0], int(round(100.0 * parts[i][1] / total))]
		if wv > font.get_string_size(tr(lab), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 4.0:
			draw_string(font, Vector2(x + 2.0, at.y + 11.0), tr(lab), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_INK)
		x += wv


static func _pct(w: int, n: int) -> float:
	return 100.0 * w / n if n > 0 else 0.0


static func _avg(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s := 0.0
	for v in a:
		s += float(v)
	return s / a.size()


static func _max(a: Array) -> float:
	var best := 0.0
	for v in a:
		best = maxf(best, float(v))
	return best
