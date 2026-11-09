class_name Starfield
extends Node2D
## רקע: כוכבים בשכבות + ערפילית. seed קבוע כדי שהרקע לא יקפוץ בכל פריים.

var stars: Array[Dictionary] = []
var nebulae: Array[Dictionary] = []
var streaks: Array[Dictionary] = []
var dust: Array[Dictionary] = []
var _spawn_cd: float = 1.2


func rebuild(vp: Vector2) -> void:
	stars.clear()
	nebulae.clear()
	streaks.clear()
	dust.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 939001
	for i in range(160):
		var layer := 1 + (i % 3)
		stars.append({
			"p": Vector2(rng.randf() * vp.x, rng.randf() * vp.y),
			"layer": layer,
			"r": 0.7 + layer * 0.55 + rng.randf() * 0.45,
			"tw": rng.randf() * TAU,
			"flare": i % 11 == 0,
			"tint": Color.from_hsv(0.52 + float(i % 6) * 0.07, 0.35, 1.0),
		})
	for i in range(8):
		var warm := i % 2 == 0
		nebulae.append({
			"p": Vector2(rng.randf() * vp.x, rng.randf() * vp.y * 0.78),
			"s": 110.0 + rng.randf() * 200.0,
			"c": Color(0.22, 0.10, 0.42, 0.16) if warm else Color(0.06, 0.20, 0.36, 0.15),
			"c2": Color(0.40, 0.16, 0.28, 0.08) if warm else Color(0.10, 0.32, 0.40, 0.07),
		})
	for i in range(40):
		dust.append({
			"p": Vector2(rng.randf() * vp.x, rng.randf() * vp.y),
			"v": Vector2(rng.randf_range(-6.0, 6.0), 8.0 + rng.randf() * 14.0),
			"a": 0.04 + rng.randf() * 0.06,
		})


func _process(delta: float) -> void:
	var vp := get_viewport_rect().size
	for s in stars:
		var layer: int = int(s["layer"])
		s["p"].y += (5.0 + layer * 9.0) * delta
		s["tw"] = float(s["tw"]) + delta * (1.1 + layer * 0.45)
		if s["p"].y > vp.y + 6.0:
			s["p"].y = -6.0
			s["p"].x = fmod(float(s["p"].x) + 21.0, maxf(vp.x, 1.0))
	for d in dust:
		d["p"] = d["p"] + d["v"] * delta
		if d["p"].y > vp.y + 8.0:
			d["p"].y = -8.0
			d["p"].x = fmod(float(d["p"].x) + 40.0, maxf(vp.x, 1.0))
	var live: Array[Dictionary] = []
	for st in streaks:
		st["p"] = st["p"] + st["v"] * delta
		st["life"] = float(st["life"]) - delta
		if float(st["life"]) > 0.0 and st["p"].y < vp.y + 40.0:
			live.append(st)
	streaks = live
	_spawn_cd -= delta
	if _spawn_cd <= 0.0:
		_spawn_cd = 2.4 + randf() * 3.2
		_spawn_streak(vp)
	queue_redraw()


func _spawn_streak(vp: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	streaks.append({
		"p": Vector2(rng.randf() * vp.x, -20.0),
		"v": Vector2(80.0 + rng.randf() * 140.0, 260.0 + rng.randf() * 180.0),
		"life": 0.55 + rng.randf() * 0.35,
		"w": 1.2 + rng.randf() * 1.4,
	})


func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.012, 0.014, 0.035))
	draw_rect(Rect2(Vector2.ZERO, Vector2(vp.x, vp.y * 0.42)), Color(0.08, 0.03, 0.14, 0.28))
	draw_circle(Vector2(vp.x * 0.5, vp.y * 1.05), vp.x * 0.55, Color(0.10, 0.16, 0.32, 0.22))
	for n in nebulae:
		draw_circle(n["p"], float(n["s"]) * 1.15, n["c"])
		draw_circle(n["p"] + Vector2(48, -24), float(n["s"]) * 0.62, n["c2"])
		draw_circle(n["p"] + Vector2(-30, 18), float(n["s"]) * 0.28, Color(n["c2"].r, n["c2"].g, n["c2"].b, 0.12))
	for d in dust:
		draw_circle(d["p"], 1.3, Color(0.75, 0.84, 1.0, float(d["a"])))
	for s in stars:
		var tw: float = 0.35 + 0.65 * absf(sin(float(s["tw"])))
		var tint: Color = s["tint"]
		var col := Color(tint.r, tint.g, tint.b, tw)
		if bool(s["flare"]):
			draw_circle(s["p"], float(s["r"]) * 3.2, Color(tint.r, tint.g, tint.b, tw * 0.16))
		draw_circle(s["p"], float(s["r"]), col)
		if bool(s["flare"]) and tw > 0.72:
			var f: float = float(s["r"]) * 6.5
			var arm := Color(1, 1, 1, tw * 0.45)
			draw_line(s["p"] + Vector2(-f, 0), s["p"] + Vector2(f, 0), arm, 1.3)
			draw_line(s["p"] + Vector2(0, -f), s["p"] + Vector2(0, f), arm, 1.3)
	for st in streaks:
		var a: float = clampf(float(st["life"]) / 0.6, 0.0, 1.0)
		var tail: Vector2 = st["v"].normalized() * -28.0
		draw_line(st["p"], st["p"] + tail, Color(0.85, 0.95, 1.0, a), float(st["w"]))
		draw_circle(st["p"], 2.0, Color(1, 1, 1, a))
	var vig := Color(0, 0, 0, 0.42)
	draw_rect(Rect2(0, 0, vp.x, 36), vig)
	draw_rect(Rect2(0, vp.y - 70, vp.x, 70), vig)
	draw_rect(Rect2(0, 0, 18, vp.y), vig)
	draw_rect(Rect2(vp.x - 18, 0, 18, vp.y), vig)
