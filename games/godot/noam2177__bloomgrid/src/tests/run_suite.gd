extends SceneTree
## טסטים headless — בלי חלון, בלי אדם.
## godot --headless --path . -s res://tests/run_suite.gd

const LayoutFit := preload("res://game/layout_fit.gd")

func _init() -> void:
	var failed := 0
	failed += _run("place_and_row_clear", func() -> String: return _place_and_row_clear())
	failed += _run("col_clear", func() -> String: return _col_clear())
	failed += _run("reject_overlap", func() -> String: return _reject_overlap())
	failed += _run("score_formula", func() -> String: return _score_formula())
	failed += _run("game_over_full", func() -> String: return _game_over_full())
	failed += _run("tray_refill", func() -> String: return _tray_refill())
	failed += _run("supernova_cross", func() -> String: return _supernova_cross())
	failed += _run("rotate_i2", func() -> String: return _rotate_i2())
	failed += _run("rotate_charges", func() -> String: return _rotate_charges())
	failed += _run("race_timeout", func() -> String: return _race_timeout())
	failed += _run("race_time_bonus", func() -> String: return _race_time_bonus())
	failed += _run("board_oob", func() -> String: return _board_oob())
	failed += _run("unknown_piece", func() -> String: return _unknown_piece())
	failed += _run("clamp_score", func() -> String: return _clamp_score())
	failed += _run("sanitize_name", func() -> String: return _sanitize_name())
	failed += _run("tick_ignores_negative", func() -> String: return _tick_ignores_negative())
	failed += _run("layout_phone_fits", func() -> String: return _layout_phone_fits())
	failed += _run("layout_graphics_scale", func() -> String: return _layout_graphics_scale())
	print("BLOOMGRID_TESTS failed=", failed)
	quit(1 if failed else 0)


func _run(name: String, fn: Callable) -> int:
	var err: String = fn.call()
	if err == "":
		print("PASS ", name)
		return 0
	print("FAIL ", name, " ", err)
	return 1


func _place_and_row_clear() -> String:
	var b := Board.new()
	for x in range(Board.SIZE - 1):
		b.set_cell(x, 0, 1)
	if not b.can_place("dot", Board.SIZE - 1, 0):
		return "expected can_place"
	b.place("dot", Board.SIZE - 1, 0, 2)
	var n: int = int(b.clear_lines().get("count", 0))
	if n != 1:
		return "lines=%s" % n
	for x in range(Board.SIZE):
		if b.get_cell(x, 0) != 0:
			return "row not empty"
	return ""


func _col_clear() -> String:
	var b := Board.new()
	for y in range(Board.SIZE - 1):
		b.set_cell(0, y, 1)
	b.place("dot", 0, Board.SIZE - 1, 3)
	if int(b.clear_lines().get("count", 0)) != 1:
		return "col not cleared"
	return ""


func _reject_overlap() -> String:
	var b := Board.new()
	b.place("o", 0, 0, 1)
	if b.can_place("dot", 0, 0):
		return "overlap allowed"
	return ""


func _score_formula() -> String:
	if Rules.score_place(4, 0) != 40:
		return "place"
	if Rules.score_place(1, 2, 1, false) != 410:
		return "lines"
	if Rules.score_place(1, 2, 2, true) != 10 + 800 + 250:
		return "combo_cross"
	return ""


func _game_over_full() -> String:
	var s := GameSession.new()
	s.rng = RngStream.new(1)
	for i in range(Board.SIZE * Board.SIZE):
		s.board.cells[i] = 1
	s.tray = ["dot", "dot", "dot"]
	s.check_over()
	if not s.over:
		return "should be over"
	return ""


func _tray_refill() -> String:
	var s := GameSession.new()
	s.rng = RngStream.new(42)
	s.board = Board.new()
	s.fill_tray()
	if s.tray.size() != 3:
		return "tray size"
	return ""


func _supernova_cross() -> String:
	var b := Board.new()
	for x in range(Board.SIZE - 1):
		b.set_cell(x, 0, 1)
	for y in range(1, Board.SIZE):
		b.set_cell(Board.SIZE - 1, y, 1)
	b.place("dot", Board.SIZE - 1, 0, 2)
	var c: Dictionary = b.clear_lines()
	if int(c.get("count", 0)) != 2:
		return "count"
	if not bool(c.get("cross", false)):
		return "cross"
	return ""


func _rotate_i2() -> String:
	var a: Array[Vector2i] = PieceCatalog.cells_of("i2", 1)
	if a.size() != 2:
		return "size"
	if a[0] != Vector2i(0, 0) or a[1] != Vector2i(0, 1):
		return "cells %s %s" % [a[0], a[1]]
	var b := Board.new()
	if not b.can_place("i2", 0, 0, 1):
		return "can_place rot"
	if b.place("i2", 0, 0, 2, 1) != 2:
		return "place"
	if b.get_cell(0, 0) == 0 or b.get_cell(0, 1) == 0:
		return "not vertical"
	return ""


func _rotate_charges() -> String:
	var s := GameSession.new(7, "classic")
	s.tray = ["i3", "dot", "o"]
	s.tray_rot = [0, 0, 0]
	s.rotates_left = 2
	s.over = false
	if not s.rotate_piece(0):
		return "first"
	if s.rot_of(0) != 1 or s.rotates_left != 1:
		return "after1"
	if not s.rotate_piece(0):
		return "second"
	if s.rotates_left != 0:
		return "charges"
	if s.rotate_piece(0):
		return "third allowed"
	return ""


func _race_timeout() -> String:
	var s := GameSession.new(3, "race")
	if s.time_left < 40.0:
		return "start"
	s.tick(s.time_left + 0.1)
	if not s.over or not s.timed_out:
		return "timeout"
	return ""


func _race_time_bonus() -> String:
	var s := GameSession.new(3, "race")
	s.board = Board.new()
	s.tray = ["dot", null, null]
	s.tray_rot = [0, 0, 0]
	s.over = false
	s.timed_out = false
	s.time_left = 10.0
	var before := s.time_left
	var mv: Dictionary = s.try_place(0, 0, 0)
	if not bool(mv.get("ok", false)):
		return "place"
	if s.time_left <= before:
		return "no bonus"
	if float(mv.get("time_bonus", 0.0)) < 1.0:
		return "bonus"
	return ""


func _board_oob() -> String:
	var b := Board.new()
	b.set_cell(-1, 0, 9)
	b.set_cell(0, 99, 9)
	if b.get_cell(-1, 0) != 0 or b.get_cell(0, 0) != 0:
		return "oob wrote"
	return ""


func _unknown_piece() -> String:
	var b := Board.new()
	if b.can_place("nope", 0, 0) or b.place("nope", 0, 0, 1) != 0:
		return "unknown placed"
	if PieceCatalog.is_known("nope") or not PieceCatalog.is_known("dot"):
		return "is_known"
	return ""


func _clamp_score() -> String:
	if Rules.clamp_score(-3) != 0:
		return "neg"
	if Rules.clamp_score(Rules.SCORE_MAX + 8) != Rules.SCORE_MAX:
		return "max"
	return ""


func _sanitize_name() -> String:
	if LocalSave.sanitize_name("  Ada\nLovelace  ") != "Ada Lovelace":
		return "ws"
	if LocalSave.sanitize_name("a@b.com") != "":
		return "email"
	if LocalSave.sanitize_name("https://x.test") != "":
		return "url"
	if LocalSave.sanitize_name("www.x.test") != "":
		return "www"
	return ""


func _tick_ignores_negative() -> String:
	var s := GameSession.new(3, "race")
	s.over = false
	s.timed_out = false
	s.time_left = 20.0
	s.tick(-4.0)
	if s.time_left != 20.0 or s.over:
		return "neg tick"
	return ""


func _layout_phone_fits() -> String:
	if not LayoutFit.fits(Vector2(720, 1280), 0.0, 0.0, 0.0, 0.0):
		return "720x1280"
	if not LayoutFit.fits(Vector2(720, 1280), 0.0, 48.0, 0.0, 36.0):
		return "notch"
	if not LayoutFit.fits(Vector2(390, 844), 0.0, 44.0, 0.0, 34.0):
		return "390x844"
	return ""


func _layout_graphics_scale() -> String:
	var m: Dictionary = LayoutFit.compute(Vector2(720, 1280), 0.0, 0.0, 0.0, 0.0)
	var c: int = int(m["cell"])
	if c < 40:
		return "cell_too_small=%s" % c
	if c > 88:
		return "cell_too_large=%s" % c
	var m2: Dictionary = LayoutFit.compute(Vector2(390, 844), 0.0, 44.0, 0.0, 34.0)
	if int(m2["cell"]) < LayoutFit.MIN_CELL:
		return "iphone_mini_cell"
	return ""
