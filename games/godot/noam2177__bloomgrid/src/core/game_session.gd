class_name GameSession
extends RefCounted
## כל החוקים חיים כאן. game/ רק מצייר ומעביר מגע.
## classic = בלי שעון. race = זמן יורד, ניקוי מחזיר שניות.
## Spin הוא משאב לריצה (פעמיים), לא סיבוב חופשי לכל חלק.

var board: Board = Board.new()
var rng: RngStream = RngStream.new(1)
var tray: Array = []
var tray_rot: Array = [0, 0, 0]
var score: int = 0
var over: bool = false
var combo: int = 0
var max_combo: int = 0
var trays_dealt: int = 0
var lines_cleared: int = 0
var last_move: Dictionary = {}
var mode: String = "classic"
var rotates_left: int = 2
var time_left: float = 0.0
var last_time_bonus: float = 0.0
var timed_out: bool = false


func _init(p_seed: int = 1, p_mode: String = "classic") -> void:
	rng = RngStream.new(p_seed)
	mode = p_mode
	rotates_left = Rules.rotate_charges()
	if mode == "race":
		time_left = Rules.race_start_time()
	fill_tray()


func fill_tray() -> void:
	var tier := Rules.difficulty_tier(trays_dealt)
	tray = [
		PieceCatalog.pick_weighted(rng, tier),
		PieceCatalog.pick_weighted(rng, tier),
		PieceCatalog.pick_weighted(rng, tier),
	]
	tray_rot = [0, 0, 0]
	trays_dealt += 1
	check_over()


func remaining() -> Array:
	var out: Array = []
	for k in tray:
		if k != null and str(k) != "":
			out.append(k)
	return out


func rot_of(tray_i: int) -> int:
	if tray_i < 0 or tray_i >= tray_rot.size():
		return 0
	return int(tray_rot[tray_i])


func _fits_with_spins(key: String, rot: int, spins: int) -> bool:
	# אם נשאר Spin, בודקים גם סיבובים עתידיים כדי לא להרוג את השחקן על מגש "עקום".
	for extra in range(spins + 1):
		if board.fits_anywhere(key, (rot + extra) % 4):
			return true
	return false


func check_over() -> void:
	if mode == "race" and time_left <= 0.0:
		over = true
		timed_out = true
		return
	var left := remaining()
	if left.is_empty():
		fill_tray()
		return
	over = true
	for i in range(3):
		var key = tray[i]
		if key == null or str(key) == "":
			continue
		if _fits_with_spins(str(key), rot_of(i), rotates_left):
			over = false
			return


func rotate_piece(tray_i: int) -> bool:
	# 90° עם כיוון השעון. נגמר כשנגמרים 2 הסיבובים.
	if over or rotates_left <= 0 or tray_i < 0 or tray_i >= 3:
		return false
	var key = tray[tray_i]
	if key == null or str(key) == "":
		return false
	tray_rot[tray_i] = (rot_of(tray_i) + 1) % 4
	rotates_left -= 1
	check_over()
	return true


func tick(delta: float) -> void:
	if over or mode != "race" or not is_finite(delta) or delta <= 0.0:
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 0.0:
		timed_out = true
		over = true


func try_place(tray_i: int, x: int, y: int) -> Dictionary:
	var fail := {"ok": false, "cells": 0, "lines": 0, "cross": false, "combo": combo, "delta": 0, "time_bonus": 0.0}
	if over or tray_i < 0 or tray_i >= 3:
		last_move = fail
		return fail
	var key = tray[tray_i]
	if key == null or str(key) == "":
		last_move = fail
		return fail
	var rot := rot_of(tray_i)
	var n := board.place(str(key), x, y, PieceCatalog.color_of(str(key)), rot)
	if n == 0:
		last_move = fail
		return fail
	var cleared: Dictionary = board.clear_lines()
	var lines: int = int(cleared.get("count", 0))
	var cross: bool = bool(cleared.get("cross", false))
	if lines > 0:
		combo += 1
	else:
		combo = 0
	max_combo = maxi(max_combo, combo)
	lines_cleared += lines
	var delta := Rules.score_place(n, lines, combo, cross)
	score = Rules.clamp_score(score + delta)
	var bonus := 0.0
	if mode == "race":
		bonus = Rules.race_time_bonus(n, lines, combo, cross)
		time_left = minf(Rules.race_time_cap(), time_left + bonus)
		last_time_bonus = bonus
	tray[tray_i] = null
	if remaining().is_empty():
		fill_tray()
	else:
		check_over()
	last_move = {
		"ok": true,
		"cells": n,
		"lines": lines,
		"cross": cross,
		"combo": combo,
		"delta": delta,
		"rows": cleared.get("rows", []),
		"cols": cleared.get("cols", []),
		"over": over,
		"time_bonus": bonus,
		"rot": rot,
	}
	return last_move
