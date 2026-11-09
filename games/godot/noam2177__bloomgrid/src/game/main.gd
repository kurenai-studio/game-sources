extends Control
## מה שהשחקן רואה ונוגע. אין כאן חוקי ניקוד — רק קריאות ל-GameSession.
## ציור ידני (draw_*) כדי לא למשוך אסטים מהרשת.

const BloomPaint := preload("res://game/bloom_paint.gd")
const LocalSave := preload("res://game/local_save.gd")
const Starfield := preload("res://game/starfield.gd")
const SfxBus := preload("res://game/sfx_bus.gd")
const LayoutFit := preload("res://game/layout_fit.gd")
const GAP := 5
const COLORS := [
	Color(0.10, 0.12, 0.18),
	Color(0.93, 0.24, 0.30),
	Color(0.20, 0.70, 0.98),
	Color(1.0, 0.76, 0.20),
	Color(0.22, 0.86, 0.52),
	Color(0.64, 0.36, 0.98),
	Color(0.98, 0.40, 0.66),
]

var session: GameSession
var selected: int = -1
var hover: Vector2i = Vector2i(-1, -1)
var dragging: bool = false
var pointer: Vector2 = Vector2.ZERO
var cell: int = 64
var origin: Vector2 = Vector2(48, 150)
var shake: float = 0.0
var flash: float = 0.0
var combo_pop: float = 0.0
var combo_label: String = ""
var sparks: Array[Dictionary] = []
var best: int = 0
var sfx: SfxBus
var field: Starfield
var clear_t: float = 0.0
var clear_rows: Array = []
var clear_cols: Array = []
var clear_cross: bool = false
var pop_t: float = 0.0
var pop_cells: Array[Vector2i] = []
var last_score: int = 0
var top_scores: Array = []
var run_rank: int = 0
var is_new_record: bool = false
var recorded: bool = false
var show_scores: bool = false
var show_privacy: bool = false
var muted: bool = false
var blasts: Array[Dictionary] = []
var shards: Array[Dictionary] = []
var floaters: Array[Dictionary] = []
var play_mode: String = "classic"
var time_pop: float = 0.0
var time_pop_text: String = ""
var name_box: LineEdit
var player_name: String = ""
var _inset_l: float = 0.0
var _inset_t: float = 0.0
var _inset_r: float = 0.0
var _inset_b: float = 0.0
var _tray_box_w: float = 210.0


func _ready() -> void:
	session = GameSession.new(int(Time.get_ticks_msec()) | 1, play_mode)
	best = LocalSave.best()
	last_score = LocalSave.last()
	top_scores = LocalSave.top_entries()
	muted = LocalSave.is_muted()
	player_name = LocalSave.player_name()
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	field = Starfield.new()
	field.z_index = -8
	add_child(field)
	field.rebuild(size if size.x > 1.0 else Vector2(720, 1280))
	sfx = SfxBus.new()
	add_child(sfx)
	sfx.set_muted(muted)
	_make_name_box()
	set_process(true)


func _make_name_box() -> void:
	name_box = LineEdit.new()
	name_box.placeholder_text = "name (optional)"
	name_box.max_length = LocalSave.NAME_MAX
	name_box.text = player_name
	name_box.flat = true
	name_box.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_box.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	name_box.add_theme_color_override("font_placeholder_color", Color(0.48, 0.58, 0.70))
	name_box.add_theme_color_override("caret_color", Color(0.70, 0.90, 1.0))
	name_box.text_changed.connect(_on_name_changed)
	name_box.text_submitted.connect(_on_name_submitted)
	name_box.focus_exited.connect(_commit_name)
	add_child(name_box)
	_layout_name_box()


func _layout_name_box() -> void:
	if name_box == null:
		return
	name_box.position = Vector2(size.x - _inset_r - 214.0, _inset_t + 18.0)
	name_box.size = Vector2(198, 34)
	name_box.visible = true
	name_box.z_index = 20


func _on_name_changed(t: String) -> void:
	player_name = LocalSave.sanitize_name(t)


func _on_name_submitted(_t: String) -> void:
	_commit_name()
	if name_box:
		name_box.release_focus()


func _commit_name() -> void:
	player_name = LocalSave.set_player_name(name_box.text if name_box else player_name)
	if name_box and name_box.text != player_name:
		name_box.text = player_name
	if recorded and last_score > 0:
		top_scores = LocalSave.set_name_on_score(last_score, player_name)
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if field:
			field.rebuild(size)
		_layout_name_box()


func _process(delta: float) -> void:
	shake = maxf(shake - delta * 18.0, 0.0)
	flash = maxf(flash - delta * 2.2, 0.0)
	combo_pop = maxf(combo_pop - delta * 0.85, 0.0)
	clear_t = maxf(clear_t - delta, 0.0)
	pop_t = maxf(pop_t - delta * 2.4, 0.0)
	sparks = _tick_fx(sparks, delta)
	shards = _tick_fx(shards, delta)
	var live_b: Array[Dictionary] = []
	for b in blasts:
		b["age"] = float(b["age"]) + delta
		if float(b["age"]) < float(b["life"]):
			live_b.append(b)
	blasts = live_b
	var live_f: Array[Dictionary] = []
	for f in floaters:
		f["p"] = f["p"] + Vector2(0, -46.0 * delta)
		f["life"] = float(f["life"]) - delta
		if float(f["life"]) > 0.0:
			live_f.append(f)
	floaters = live_f
	time_pop = maxf(time_pop - delta * 1.1, 0.0)
	var was_over := session.over
	session.tick(delta)
	if session.over and not was_over:
		_record_run()
		sfx.game_over()
	queue_redraw()


func _tick_fx(items: Array[Dictionary], delta: float) -> Array[Dictionary]:
	var live: Array[Dictionary] = []
	for it in items:
		it["p"] = it["p"] + it["v"] * delta
		it["life"] = float(it["life"]) - delta
		if float(it["life"]) > 0.0:
			live.append(it)
	return live


func _safe_margins() -> Vector4:
	var m := Vector4(0.0, 0.0, 0.0, 0.0)
	var vp := get_viewport()
	if vp == null or size.x < 1.0 or size.y < 1.0:
		return m
	var vr := vp.get_visible_rect()
	if vr.size.x < 1.0 or vr.size.y < 1.0:
		return m
	var safe := DisplayServer.get_display_safe_area()
	var sx: float = size.x / vr.size.x
	var sy: float = size.y / vr.size.y
	m.x = maxf(0.0, (safe.position.x - vr.position.x) * sx)
	m.y = maxf(0.0, (safe.position.y - vr.position.y) * sy)
	m.z = maxf(0.0, (vr.end.x - safe.end.x) * sx)
	m.w = maxf(0.0, (vr.end.y - safe.end.y) * sy)
	return m


func _layout() -> void:
	var sm := _safe_margins()
	_inset_l = sm.x
	_inset_t = sm.y
	_inset_r = sm.z
	_inset_b = sm.w
	var fit: Dictionary = LayoutFit.compute(size, _inset_l, _inset_t, _inset_r, _inset_b)
	cell = int(fit["cell"])
	origin = fit["origin"]
	_tray_box_w = float(fit["box_w"])
	if shake > 0.0:
		origin += Vector2(sin(shake * 40.0) * shake * 8.0, cos(shake * 33.0) * shake * 6.0)
	_layout_name_box()


func _chrome_row1_y() -> float:
	return size.y - _inset_b - 132.0


func _chrome_row2_y() -> float:
	return size.y - _inset_b - 78.0


func _font() -> Font:
	return ThemeDB.fallback_font


func _draw() -> void:
	_layout()
	_draw_hud()
	_draw_board()
	_draw_tray()
	_draw_drag_piece()
	_draw_blasts()
	_draw_sparks()
	_draw_shards()
	_draw_floaters()
	if show_privacy and not session.over:
		_draw_privacy_panel()
	elif show_scores and not session.over:
		_draw_scores_panel()
	if session.over:
		_draw_game_over()
	else:
		_draw_restart()
		_draw_chrome_buttons()
	if flash > 0.0:
		var fc := Color(1.0, 0.55, 0.18, flash * 0.34) if clear_cross else Color(1.0, 0.62, 0.22, flash * 0.28)
		draw_rect(Rect2(Vector2.ZERO, size), fc)


func _draw_hud() -> void:
	var panel := Rect2(18, 12, size.x - 36.0, 132.0)
	BloomPaint.glass_panel(self, panel, Color(0.06, 0.09, 0.16, 0.72), Color(0.45, 0.72, 1.0, 0.45))
	var mode_name := "RACE" if play_mode == "race" else "CLASSIC"
	draw_string(_font(), Vector2(36, 42), "BLOOMGRID  ·  %s" % mode_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.86, 0.94, 1.0))
	draw_string(_font(), Vector2(36, 72), "score  %s" % session.score, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.95, 0.88, 0.55))
	draw_string(_font(), Vector2(36, 96), "best  %s   spin %s/2" % [best, session.rotates_left], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.62, 0.72, 0.88))
	if play_mode == "race":
		var tmax := Rules.race_start_time()
		var tbar := Rect2(36, 112, size.x - 240.0, 16.0)
		draw_rect(tbar, Color(0.08, 0.10, 0.16, 0.95))
		var tw: float = tbar.size.x * clampf(session.time_left / tmax, 0.0, 1.0)
		var hot := session.time_left < 10.0
		draw_rect(Rect2(tbar.position, Vector2(tw, tbar.size.y)), Color(1.0, 0.35, 0.25, 0.9) if hot else Color(0.35, 0.92, 0.55, 0.9))
		draw_rect(tbar, Color(0.70, 0.90, 1.0, 0.4), false, 1.0)
		draw_string(_font(), Vector2(tbar.end.x + 10.0, 126), "%ss" % int(ceil(session.time_left)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.45) if hot else Color(0.75, 0.95, 0.80))
	if time_pop > 0.0:
		draw_string(_font(), Vector2(size.x * 0.5 - 40.0, 150.0), time_pop_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.45, 1.0, 0.62, time_pop))
	var occ: int = session.board.occupied()
	var bar := Rect2(size.x - 232.0, 58.0, 198.0, 10.0)
	draw_rect(bar, Color(0.08, 0.10, 0.16, 0.9))
	var fill_w: float = bar.size.x * (float(occ) / 64.0)
	draw_rect(Rect2(bar.position, Vector2(fill_w, bar.size.y)), Color(0.42, 0.78, 1.0, 0.85))
	draw_rect(bar, Color(0.55, 0.75, 1.0, 0.4), false, 1.0)
	draw_string(_font(), Vector2(bar.position.x, 86), "fill %s/64" % occ, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.55, 0.66, 0.82))
	if session.combo > 0:
		var pill := Rect2(size.x - 232.0, 96.0, 198.0, 26.0)
		BloomPaint.glass_panel(self, pill, Color(0.28, 0.16, 0.06, 0.8), Color(1.0, 0.78, 0.32, 0.7))
		draw_string(_font(), pill.position + Vector2(16, 21), "COMBO  x%s" % session.combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.88, 0.45))
	if is_new_record:
		draw_string(_font(), Vector2(36, 128), "NEW RECORD", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.78, 0.35))
	if combo_pop > 0.0:
		var a := clampf(combo_pop, 0.0, 1.0)
		var scale_px := 26 + int((1.0 - a) * 10.0)
		var col := Color(1.0, 0.92, 0.45, a) if clear_cross else Color(0.75, 0.95, 1.0, a)
		draw_string(_font(), Vector2(size.x * 0.5 - 120.0, 138.0), combo_label, HORIZONTAL_ALIGNMENT_LEFT, -1, scale_px, col)


func _cell_rect(x: int, y: int) -> Rect2:
	return Rect2(origin + Vector2(x, y) * (cell + GAP), Vector2(cell, cell))


func _draw_board() -> void:
	var board_w: float = float(Board.SIZE) * float(cell + GAP)
	var frame := Rect2(origin - Vector2(12, 12), Vector2(board_w + 18.0, board_w + 18.0))
	draw_rect(frame.grow(10.0), Color(0.25, 0.55, 1.0, 0.10))
	BloomPaint.glass_panel(self, frame, Color(0.05, 0.07, 0.13, 0.55), Color(0.40, 0.70, 1.0, 0.40))
	_draw_corners(frame, Color(0.55, 0.85, 1.0, 0.85))
	for y in range(Board.SIZE):
		for x in range(Board.SIZE):
			var r := _cell_rect(x, y)
			var v := session.board.get_cell(x, y)
			var pulse := 0.0
			if pop_t > 0.0:
				for pc in pop_cells:
					if pc.x == x and pc.y == y:
						pulse = pop_t
						break
			if v > 0:
				BloomPaint.gem(self, r, COLORS[clampi(v, 1, 6)], true, pulse)
			else:
				BloomPaint.gem(self, r, COLORS[0], false, 0.0)
	if clear_t > 0.0:
		_draw_clear_overlay()
	if selected >= 0 and hover.x >= 0 and not session.over:
		var key = session.tray[selected]
		if key != null:
			var rot := session.rot_of(selected)
			var ok := session.board.can_place(str(key), hover.x, hover.y, rot)
			var ghost: Color = Color(0.35, 0.95, 0.62, 0.55) if ok else Color(1.0, 0.28, 0.32, 0.5)
			for c in PieceCatalog.cells_of(str(key), rot):
				BloomPaint.gem(self, _cell_rect(hover.x + c.x, hover.y + c.y), ghost, true, 0.35 if ok else 0.0)


func _draw_corners(r: Rect2, col: Color) -> void:
	var n := 16.0
	var w := 2.2
	draw_line(r.position, r.position + Vector2(n, 0), col, w)
	draw_line(r.position, r.position + Vector2(0, n), col, w)
	draw_line(Vector2(r.end.x, r.position.y), Vector2(r.end.x - n, r.position.y), col, w)
	draw_line(Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.position.y + n), col, w)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.position.x + n, r.end.y), col, w)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.position.x, r.end.y - n), col, w)
	draw_line(r.end, r.end + Vector2(-n, 0), col, w)
	draw_line(r.end, r.end + Vector2(0, -n), col, w)


func _draw_clear_overlay() -> void:
	var a: float = clampf(clear_t / 0.45, 0.0, 1.0)
	var col := Color(1.0, 0.92, 0.45, a * 0.72) if clear_cross else Color(0.75, 0.92, 1.0, a * 0.62)
	for y in clear_rows:
		var r0 := _cell_rect(0, int(y))
		var sweep := Rect2(r0.position, Vector2(float(Board.SIZE) * float(cell + GAP) - GAP, cell))
		draw_rect(sweep, col)
	for x in clear_cols:
		var c0 := _cell_rect(int(x), 0)
		var sweep := Rect2(c0.position, Vector2(cell, float(Board.SIZE) * float(cell + GAP) - GAP))
		draw_rect(sweep, col)


func _tray_origin() -> Vector2:
	return Vector2(origin.x, origin.y + float(Board.SIZE) * float(cell + GAP) + 26.0)


func _tray_box(i: int) -> Rect2:
	var o := _tray_origin()
	var box_w: float = _tray_box_w
	return Rect2(o + Vector2(i * (box_w + 12.0), 0), Vector2(box_w, box_w))


func _draw_tray() -> void:
	for i in range(3):
		var box := _tray_box(i)
		var rim := Color(0.55, 0.85, 1.0, 0.75) if i == selected else Color(0.35, 0.55, 0.80, 0.40)
		var fill := Color(0.10, 0.16, 0.28, 0.88) if i == selected else Color(0.06, 0.09, 0.16, 0.82)
		BloomPaint.glass_panel(self, box, fill, rim)
		_draw_corners(box, rim)
		var key = session.tray[i]
		if key == null:
			draw_string(_font(), box.position + Vector2(box.size.x * 0.5 - 8.0, box.size.y * 0.52), "·", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.35, 0.45, 0.58, 0.6))
			continue
		if dragging and i == selected:
			continue
		var col: Color = COLORS[clampi(PieceCatalog.color_of(str(key)), 1, 6)]
		BloomPaint.centered_piece(self, box, str(key), col, 0.15 if i == selected else 0.0, session.rot_of(i))


func _draw_drag_piece() -> void:
	if not dragging or selected < 0 or session.over:
		return
	var key = session.tray[selected]
	if key == null:
		return
	var col: Color = COLORS[clampi(PieceCatalog.color_of(str(key)), 1, 6)]
	var rot := session.rot_of(selected)
	var cells: Array = PieceCatalog.cells_of(str(key), rot)
	var wh: Vector2i = PieceCatalog.size_of(str(key), rot)
	var step: float = float(cell)
	var gap := float(GAP)
	var pw: float = float(wh.x) * (step + gap) - gap
	var ph: float = float(wh.y) * (step + gap) - gap
	var o := pointer - Vector2(pw * 0.5, ph + 18.0)
	for c in cells:
		var p: Vector2 = o + Vector2(float(c.x), float(c.y)) * (step + gap)
		BloomPaint.gem(self, Rect2(p, Vector2(step, step)), col, true, 0.45)


func _restart_rect() -> Rect2:
	return Rect2(Vector2(_inset_l + 16.0, _chrome_row1_y()), Vector2(140, 44))


func _scores_rect() -> Rect2:
	return Rect2(Vector2(_inset_l + 164.0, _chrome_row1_y()), Vector2(130, 44))


func _mute_rect() -> Rect2:
	return Rect2(Vector2(_inset_l + 302.0, _chrome_row1_y()), Vector2(110, 44))


func _privacy_rect() -> Rect2:
	return Rect2(Vector2(size.x - _inset_r - 136.0, _chrome_row1_y()), Vector2(120, 44))


func _classic_rect() -> Rect2:
	return Rect2(Vector2(_inset_l + 16.0, _chrome_row2_y()), Vector2(140, 44))


func _race_rect() -> Rect2:
	return Rect2(Vector2(_inset_l + 164.0, _chrome_row2_y()), Vector2(130, 44))


func _rotate_rect() -> Rect2:
	return Rect2(Vector2(_inset_l + 302.0, _chrome_row2_y()), Vector2(200, 44))


func _again_rect() -> Rect2:
	return Rect2(Vector2(size.x * 0.5 - 140.0, size.y * 0.78), Vector2(280, 64))


func _draw_restart() -> void:
	var r := _restart_rect()
	BloomPaint.glass_panel(self, r, Color(0.10, 0.18, 0.30, 0.88), Color(0.55, 0.80, 1.0, 0.55))
	draw_string(_font(), r.position + Vector2(36, 34), "Restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.92, 0.96, 1.0))


func _draw_chrome_buttons() -> void:
	var sc := _scores_rect()
	BloomPaint.glass_panel(self, sc, Color(0.12, 0.14, 0.24, 0.88), Color(0.80, 0.70, 0.35, 0.55))
	draw_string(_font(), sc.position + Vector2(22, 30), "Scores", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.90, 0.55))
	var mu := _mute_rect()
	BloomPaint.glass_panel(self, mu, Color(0.12, 0.14, 0.24, 0.88), Color(0.55, 0.80, 1.0, 0.45))
	draw_string(_font(), mu.position + Vector2(18, 30), "Mute" if not muted else "Sound", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.90, 0.94, 1.0))
	var pr := _privacy_rect()
	BloomPaint.glass_panel(self, pr, Color(0.10, 0.16, 0.22, 0.88), Color(0.55, 0.85, 0.75, 0.5))
	draw_string(_font(), pr.position + Vector2(16, 30), "Privacy", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.85, 0.96, 0.90))
	var cl := _classic_rect()
	var on_c := play_mode == "classic"
	BloomPaint.glass_panel(self, cl, Color(0.10, 0.18, 0.30, 0.9) if on_c else Color(0.08, 0.10, 0.16, 0.85), Color(0.55, 0.85, 1.0, 0.7) if on_c else Color(0.35, 0.45, 0.6, 0.4))
	draw_string(_font(), cl.position + Vector2(22, 30), "Classic", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.92, 0.96, 1.0))
	var rc := _race_rect()
	var on_r := play_mode == "race"
	BloomPaint.glass_panel(self, rc, Color(0.28, 0.12, 0.08, 0.92) if on_r else Color(0.08, 0.10, 0.16, 0.85), Color(1.0, 0.55, 0.28, 0.75) if on_r else Color(0.35, 0.45, 0.6, 0.4))
	draw_string(_font(), rc.position + Vector2(28, 30), "Race", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.86, 0.55))
	var rt := _rotate_rect()
	var can_spin := session.rotates_left > 0
	BloomPaint.glass_panel(self, rt, Color(0.18, 0.10, 0.28, 0.92) if can_spin else Color(0.08, 0.08, 0.12, 0.8), Color(0.85, 0.55, 1.0, 0.7) if can_spin else Color(0.3, 0.3, 0.4, 0.35))
	draw_string(_font(), rt.position + Vector2(18, 30), "Spin  %s/2" % session.rotates_left, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.92, 0.80, 1.0) if can_spin else Color(0.45, 0.45, 0.55))


func _draw_score_rows(origin_p: Vector2, highlight: int) -> void:
	if top_scores.is_empty():
		draw_string(_font(), origin_p, "no scores yet", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.55, 0.62, 0.74))
		return
	for i in range(top_scores.size()):
		var e: Variant = top_scores[i]
		var n := 0
		var nm := ""
		if e is Dictionary:
			n = int(e.get("score", 0))
			nm = str(e.get("name", ""))
		else:
			n = int(e)
		if nm.strip_edges() == "":
			nm = "—"
		var y: float = origin_p.y + float(i) * 26.0
		var col := Color(1.0, 0.86, 0.40) if n == highlight and highlight > 0 else Color(0.78, 0.86, 0.98)
		draw_string(_font(), Vector2(origin_p.x, y), "%s.  %s   %s" % [i + 1, nm, n], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)


func _draw_privacy_panel() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.07, 0.5))
	var card := Rect2(24.0, size.y * 0.12, size.x - 48.0, size.y * 0.62)
	BloomPaint.glass_panel(self, card, Color(0.05, 0.08, 0.12, 0.95), Color(0.45, 0.85, 0.70, 0.55))
	var x := card.position.x + 28.0
	var y := card.position.y + 48.0
	draw_string(_font(), Vector2(x, y), "PRIVACY", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.80, 0.98, 0.88))
	var lines := [
		"Scores, mute, and an optional name",
		"stay on this device only.",
		"No account. No ads in this version.",
		"No analytics. Nothing is uploaded.",
		"Uninstall or clear app data to delete.",
		"You can play without a name.",
	]
	for i in range(lines.size()):
		draw_string(_font(), Vector2(x, y + 40.0 + float(i) * 28.0), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.78, 0.86, 0.92))
	draw_string(_font(), Vector2(x, card.end.y - 36.0), "tap to close", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.50, 0.62, 0.70))


func _draw_scores_panel() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.07, 0.45))
	var card := Rect2(size.x * 0.5 - 200.0, size.y * 0.22, 400.0, 420.0)
	BloomPaint.glass_panel(self, card, Color(0.06, 0.08, 0.14, 0.94), Color(0.90, 0.75, 0.35, 0.65))
	draw_string(_font(), card.position + Vector2(48, 56), "LOCAL RECORDS", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1.0, 0.90, 0.50))
	var who := player_name if player_name != "" else "guest"
	draw_string(_font(), card.position + Vector2(48, 88), "best %s   last %s   %s" % [best, last_score, who], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.70, 0.78, 0.90))
	_draw_score_rows(card.position + Vector2(56, 130), session.score)
	draw_string(_font(), card.position + Vector2(48, 390), "tap to close", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.50, 0.58, 0.70))


func _draw_game_over() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.07, 0.62))
	var card := Rect2(size.x * 0.5 - 210.0, size.y * 0.10, 420.0, size.y * 0.64)
	BloomPaint.glass_panel(self, card, Color(0.06, 0.08, 0.14, 0.92), Color(1.0, 0.45, 0.42, 0.55))
	var lost := "TIME UP" if session.timed_out else "SIGNAL LOST"
	draw_string(_font(), card.position + Vector2(40, 54), lost, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(1.0, 0.48, 0.45))
	var title := "NEW RECORD" if is_new_record else ("RANK  #%s" % run_rank if run_rank > 0 else "run saved")
	draw_string(_font(), card.position + Vector2(40, 92), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.84, 0.40))
	var who := player_name if player_name != "" else "guest"
	draw_string(_font(), card.position + Vector2(40, 118), who, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.70, 0.82, 0.95))
	draw_string(_font(), card.position + Vector2(40, 148), "score  %s" % last_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.95, 0.88, 0.55))
	draw_string(_font(), card.position + Vector2(40, 180), "best   %s" % best, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.65, 0.75, 0.90))
	draw_string(_font(), card.position + Vector2(40, 208), "lines  %s" % session.lines_cleared, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.55, 0.66, 0.80))
	_draw_score_rows(card.position + Vector2(48, 232), last_score)
	var btn := _again_rect()
	BloomPaint.glass_panel(self, btn, Color(0.16, 0.28, 0.42, 0.95), Color(0.70, 0.90, 1.0, 0.75))
	draw_string(_font(), btn.position + Vector2(58, 42), "Play again", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)


func _draw_sparks() -> void:
	for sp in sparks:
		var a: float = clampf(float(sp["life"]) / 0.55, 0.0, 1.0)
		var col: Color = sp["c"]
		col.a = a
		draw_circle(sp["p"], 2.4 + a * 3.6, col)
		if a > 0.6:
			draw_circle(sp["p"], 1.2, Color(1, 1, 1, a))


func _draw_shards() -> void:
	for sh in shards:
		var a: float = clampf(float(sh["life"]) / 0.5, 0.0, 1.0)
		var col: Color = sh["c"]
		col.a = a
		var s: float = float(sh["s"])
		draw_rect(Rect2(sh["p"], Vector2(s, s * 0.55)), col)


func _draw_blasts() -> void:
	for b in blasts:
		var t: float = clampf(float(b["age"]) / float(b["life"]), 0.0, 1.0)
		var rad: float = lerpf(8.0, float(b["max_r"]), t)
		var a: float = 1.0 - t
		var col: Color = b["col"]
		col.a = a * 0.85
		var c: Vector2 = b["origin"]
		draw_arc(c, rad, 0.0, TAU, 48, col, 3.2)
		draw_arc(c, rad * 0.62, 0.0, TAU, 36, Color(1, 1, 1, a * 0.35), 1.6)
		draw_circle(c, rad * 0.12, Color(1.0, 0.92, 0.55, a * 0.45))


func _draw_floaters() -> void:
	for f in floaters:
		var a: float = clampf(float(f["life"]) / 0.9, 0.0, 1.0)
		var col: Color = f["c"]
		col.a = a
		draw_string(_font(), f["p"], str(f["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		pointer = event.position
		if event.pressed:
			_press(event.position)
		else:
			_release(event.position)
	elif event is InputEventScreenDrag:
		pointer = event.position
		hover = _board_cell(event.position)
		queue_redraw()
	elif event is InputEventMouseButton:
		pointer = event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press(event.position)
			else:
				_release(event.position)
	elif event is InputEventMouseMotion:
		pointer = event.position
		hover = _board_cell(event.position)
		queue_redraw()


func _board_cell(p: Vector2) -> Vector2i:
	_layout()
	var local := p - origin
	var step := float(cell + GAP)
	var x := int(floor(local.x / step))
	var y := int(floor(local.y / step))
	if x < 0 or y < 0 or x >= Board.SIZE or y >= Board.SIZE:
		return Vector2i(-1, -1)
	return Vector2i(x, y)


func _press(p: Vector2) -> void:
	# שדה השם הוא LineEdit אמיתי — לא לגנוב לו את הלחיצה.
	if _name_box_rect().has_point(p):
		return
	if session.over:
		if _again_rect().has_point(p):
			_restart()
		return
	if show_privacy:
		show_privacy = false
		queue_redraw()
		return
	if show_scores:
		if name_box and _name_box_rect().has_point(p):
			return
		show_scores = false
		_layout_name_box()
		queue_redraw()
		return
	if _restart_rect().has_point(p):
		_restart()
		return
	if _scores_rect().has_point(p):
		show_scores = true
		_layout_name_box()
		queue_redraw()
		return
	if _mute_rect().has_point(p):
		muted = not muted
		LocalSave.set_muted(muted)
		sfx.set_muted(muted)
		queue_redraw()
		return
	if _privacy_rect().has_point(p):
		show_privacy = true
		show_scores = false
		queue_redraw()
		return
	if _classic_rect().has_point(p):
		_start_mode("classic")
		return
	if _race_rect().has_point(p):
		_start_mode("race")
		return
	if _rotate_rect().has_point(p):
		_try_rotate()
		return
	for i in range(3):
		if _tray_box(i).has_point(p) and session.tray[i] != null:
			selected = i
			dragging = true
			pointer = p
			sfx.select_piece()
			queue_redraw()
			return


func _release(p: Vector2) -> void:
	if not dragging:
		return
	dragging = false
	var cell_i := _board_cell(p)
	if cell_i.x < 0 or selected < 0:
		queue_redraw()
		return
	var key = session.tray[selected]
	var rot := session.rot_of(selected)
	var mv: Dictionary = session.try_place(selected, cell_i.x, cell_i.y)
	if bool(mv.get("ok", false)) and key != null:
		pop_cells.clear()
		for c in PieceCatalog.cells_of(str(key), rot):
			pop_cells.append(Vector2i(cell_i.x + c.x, cell_i.y + c.y))
		pop_t = 1.0
	selected = -1
	if not bool(mv.get("ok", false)):
		queue_redraw()
		return
	_react(mv)


func _react(mv: Dictionary) -> void:
	var lines: int = int(mv.get("lines", 0))
	var cross: bool = bool(mv.get("cross", false))
	_show_time_bonus(float(mv.get("time_bonus", 0.0)))
	if lines <= 0:
		sfx.place()
		_float_score(int(mv.get("delta", 0)), pointer, Color(0.85, 0.92, 1.0))
		if session.over:
			_record_run()
			sfx.game_over()
		queue_redraw()
		return
	clear_rows = mv.get("rows", [])
	clear_cols = mv.get("cols", [])
	clear_cross = cross
	clear_t = 0.62
	shake = 0.62 + 0.22 * float(lines)
	flash = 0.72 if cross else 0.48
	combo_pop = 1.15
	combo_label = "SUPERNOVA  +%s" % mv.get("delta", 0) if cross else ("COMBO  x%s" % mv.get("combo", 1))
	_burst(lines, cross)
	_bombs_for_clear(cross)
	_float_score(int(mv.get("delta", 0)), _board_center(), Color(1.0, 0.86, 0.35) if cross else Color(0.75, 0.95, 1.0))
	if cross:
		sfx.supernova()
		sfx.bomb()
	else:
		sfx.clear_lines(lines)
		if lines >= 2:
			sfx.bomb()
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(48 if cross else (22 if lines >= 2 else 14))
	if session.score > best:
		is_new_record = true
	best = LocalSave.write_best(session.score)
	if session.over:
		_record_run()
		sfx.game_over()
	queue_redraw()


func _board_center() -> Vector2:
	return origin + Vector2(Board.SIZE, Board.SIZE) * float(cell + GAP) * 0.5


func _burst(lines: int, cross: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var col := Color(1.0, 0.55, 0.22) if cross else Color(1.0, 0.72, 0.28)
	var ice := Color(0.70, 0.88, 1.0)
	for y in clear_rows:
		for x in range(Board.SIZE):
			_spark_at(_cell_rect(x, int(y)).get_center(), col if cross else ice, rng)
	for x in clear_cols:
		for y in range(Board.SIZE):
			_spark_at(_cell_rect(int(x), y).get_center(), col if cross else ice, rng)
	var center := _board_center()
	var n := 40 + lines * 22
	if cross:
		n += 40
	for i in range(n):
		_spark_at(center, col if i % 2 == 0 else ice, rng)
	while sparks.size() > 220:
		sparks.pop_front()


func _bombs_for_clear(cross: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var fire := Color(1.0, 0.38, 0.12)
	var gold := Color(1.0, 0.72, 0.22)
	for y in clear_rows:
		for x in range(Board.SIZE):
			_bomb_at(_cell_rect(x, int(y)).get_center(), 52.0 + float(cell), fire if x % 2 == 0 else gold, rng)
		_bomb_at(_cell_rect(3, int(y)).get_center(), 130.0 + float(cell) * 1.6, fire, rng)
	for x in clear_cols:
		for y in range(Board.SIZE):
			_bomb_at(_cell_rect(int(x), y).get_center(), 52.0 + float(cell), gold if y % 2 == 0 else fire, rng)
		_bomb_at(_cell_rect(int(x), 3).get_center(), 130.0 + float(cell) * 1.6, fire, rng)
	if cross:
		_bomb_at(_board_center(), 180.0 + float(cell) * 2.4, fire, rng)
		_bomb_at(_board_center(), 260.0 + float(cell) * 3.0, gold, rng)


func _bomb_at(p: Vector2, max_r: float, col: Color, rng: RandomNumberGenerator) -> void:
	blasts.append({
		"origin": p,
		"age": 0.0,
		"life": 0.42 + rng.randf() * 0.12,
		"max_r": max_r,
		"col": col,
	})
	for i in range(22):
		var ang := rng.randf() * TAU
		var spd := 120.0 + rng.randf() * 340.0
		shards.append({
			"p": p,
			"v": Vector2(cos(ang), sin(ang)) * spd,
			"life": 0.34 + rng.randf() * 0.40,
			"c": col.lightened(rng.randf() * 0.25),
			"s": 5.0 + rng.randf() * 9.0,
		})
	while shards.size() > 180:
		shards.pop_front()
	while blasts.size() > 28:
		blasts.pop_front()


func _spark_at(p: Vector2, col: Color, rng: RandomNumberGenerator) -> void:
	var ang := rng.randf() * TAU
	var spd := 50.0 + rng.randf() * 240.0
	sparks.append({
		"p": p + Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)),
		"v": Vector2(cos(ang), sin(ang)) * spd,
		"life": 0.30 + rng.randf() * 0.40,
		"c": col,
	})


func _float_score(delta_score: int, at: Vector2, col: Color) -> void:
	if delta_score <= 0:
		return
	floaters.append({
		"p": at + Vector2(-24, -10),
		"life": 0.85,
		"text": "+%s" % delta_score,
		"c": col,
	})


func _name_box_rect() -> Rect2:
	if name_box == null:
		return Rect2()
	return Rect2(name_box.position, name_box.size)


func _record_run() -> void:
	if recorded:
		return
	recorded = true
	_commit_name()
	last_score = session.score
	var info: Dictionary = LocalSave.write_run(session.score, player_name)
	best = int(info.get("best", best))
	top_scores = info.get("top", top_scores)
	run_rank = int(info.get("rank", 0))
	is_new_record = bool(info.get("is_record", false))


func _show_time_bonus(bonus: float) -> void:
	if play_mode != "race" or bonus <= 0.05:
		return
	time_pop = 1.0
	time_pop_text = "+%ss" % snappedf(bonus, 0.1)
	floaters.append({
		"p": _board_center() + Vector2(8, -36),
		"life": 0.9,
		"text": "+%ss" % snappedf(bonus, 0.1),
		"c": Color(0.45, 1.0, 0.62),
	})


func _try_rotate() -> void:
	# בלי בחירה — מסובבים את החלק הראשון שעדיין במגש.
	var idx := selected
	if idx < 0:
		for i in range(3):
			if session.tray[i] != null:
				idx = i
				selected = i
				break
	if idx < 0:
		return
	if session.rotate_piece(idx):
		sfx.rotate_tick()
	queue_redraw()


func _start_mode(mode: String) -> void:
	play_mode = mode
	_restart()


func _restart() -> void:
	_record_run()
	session = GameSession.new(int(Time.get_ticks_msec()) | 1, play_mode)
	selected = -1
	dragging = false
	show_scores = false
	show_privacy = false
	recorded = false
	is_new_record = false
	run_rank = 0
	sparks.clear()
	shards.clear()
	blasts.clear()
	floaters.clear()
	clear_t = 0.0
	pop_t = 0.0
	pop_cells.clear()
	combo_pop = 0.0
	time_pop = 0.0
	queue_redraw()

