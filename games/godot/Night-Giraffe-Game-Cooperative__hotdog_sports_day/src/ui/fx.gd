class_name Fx
extends Node2D
## Little bits of life: words that pop up and float away (PERFECT!), dust from a
## bounce, sand from a landing, water from a dive, sparkles, confetti, and the
## beat rings that close in on a hot dog as it comes down to land.
## Everything is drawn in whole pixels, in the palette's colours.

var _bits: Array = []        ## particles: {p, v, g, life, age, col, size, kind}
var _words: Array = []       ## {text, p, col, age, life, big}
var rings: Array = []        ## set each frame by the event: {p, k (0..1 closed), col}
## The JUMP cue, set each frame by the event: {p, k (0..1: the circle shrinks
## onto the hot dog at 1), now} or, while JUMP is held, {p, hold (0..1)}.
var cues: Array = []

const DUST := [Color("d4d4e0"), Color("a8a6ba"), Color("fffaf0")]
const SAND := [Color("e2b870"), Color("c08e52"), Color("f6dc9a")]
const WATER := [Color("9ad8f0"), Color("e0f6ff"), Color("56b2d8")]
const CONFETTI := [Color("f7d331"), Color("e0383a"), Color("38a03a"), Color("2a4ad2"), Color("f04aa8"), Color("fffaf0")]
const SPARK := [Color("fff07a"), Color("fffaf0"), Color("ffd060")]
const FLAME := [Color("ffd060"), Color("f0701e"), Color("e0383a"), Color("fff07a")]


func _process(delta: float) -> void:
	for b in _bits:
		b.age += delta
		b.v.y += b.g * delta
		b.v *= pow(b.get("drag", 1.0), delta)
		b.p += b.v * delta
	_bits = _bits.filter(func(b): return b.age < b.life)
	for w in _words:
		w.age += delta
	_words = _words.filter(func(w): return w.age < w.life)
	queue_redraw()


## A word that pops up and floats away. A word with a `key` replaces the last
## one with that key (one athlete's PERFECT! doesn't stack on its last GOOD).
func word(text: String, at: Vector2, col: Color, big := false, life := 0.8, key := "") -> void:
	if key != "":
		_words = _words.filter(func(w): return w.get("key", "") != key)
	_words.append({"text": text, "p": at, "col": col, "age": 0.0, "life": life, "big": big, "key": key})


func burst(kind: String, at: Vector2, n := 8, power := 1.0) -> void:
	var cols: Array = DUST
	var g := 60.0
	var speed := 30.0
	var life := 0.45
	var drag := 0.2
	match kind:
		"sand":
			cols = SAND
			g = 240.0
			speed = 70.0
			life = 0.9
			drag = 0.6
		"water":
			cols = WATER
			g = 260.0
			speed = 110.0
			life = 1.1
			drag = 0.7
		"confetti":
			cols = CONFETTI
			g = 40.0
			speed = 60.0
			life = 2.6
			drag = 0.4
		"spark":
			cols = SPARK
			g = 0.0
			speed = 40.0
			life = 0.5
			drag = 0.05
		"flame":
			cols = FLAME
			g = -50.0
			speed = 14.0
			life = 0.35
			drag = 0.2
	for i in n:
		var a := randf_range(PI * 1.05, PI * 1.95) if kind != "confetti" and kind != "spark" else randf() * TAU
		if kind == "dust":
			a = randf_range(PI * 0.9, PI * 2.1)
		var v := Vector2(cos(a), sin(a)) * speed * power * randf_range(0.5, 1.2)
		if kind == "confetti":
			v.y = -absf(v.y) * 1.4 - 40.0
		_bits.append({"p": at + Vector2(randf_range(-3, 3), randf_range(-1, 1)), "v": v, "g": g, "drag": drag,
			"life": life * randf_range(0.7, 1.2), "age": 0.0, "col": cols[randi() % cols.size()],
			"size": 1 if randf() < 0.6 else 2, "kind": kind})


func _draw() -> void:
	for r in rings:
		_ring(r.p, lerpf(18.0, 7.0, float(r.k)), Color(r.col, 0.35 + 0.65 * float(r.k)))
	for c in cues:
		_cue(c)
	for b in _bits:
		var fade: float = 1.0 - b.age / b.life
		var c: Color = b.col
		if b.kind == "dust":
			c.a = fade
			var s := 1 + int((1.0 - fade) * 3.0)
			draw_rect(Rect2(b.p.round() - Vector2(s, s) * 0.5, Vector2(s, s)), c)
		elif b.kind == "spark":
			c.a = fade
			var p: Vector2 = b.p.round()
			draw_rect(Rect2(p, Vector2(1, 1)), c)
			if fade > 0.4:
				draw_rect(Rect2(p + Vector2(-1, 0), Vector2(3, 1)), Color(c, c.a * 0.6))
				draw_rect(Rect2(p + Vector2(0, -1), Vector2(1, 3)), Color(c, c.a * 0.6))
		else:
			if fade < 0.3:
				c.a = fade / 0.3
			draw_rect(Rect2(b.p.round(), Vector2(b.size, b.size)), c)
	for w in _words:
		var k: float = w.age / w.life
		var f := Kit.font("big" if w.big else "small")
		var fs := 18 if w.big else 9
		var size := f.get_string_size(w.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var rise := 10.0 * (1.0 - pow(1.0 - minf(k * 2.0, 1.0), 2.0))
		var pop := 1.0
		var p: Vector2 = (w.p - Vector2(size.x / 2.0, rise)).round()
		var a := 1.0 if k < 0.7 else (1.0 - k) / 0.3
		Kit.outlined(self, f, p, w.text, fs, Color(w.col, a * pop))


const CUE_R := 17.0           ## the target: the circle meets the hot dog here


## The JUMP cue: a circle closing in on the hot dog, reaching the target ring
## at the moment to press JUMP; then, held, a ring that fills.
func _cue(c: Dictionary) -> void:
	var p: Vector2 = (c.p as Vector2).round()
	var f := Kit.font("small")
	if c.has("aim"):
		_dial(c, p, f)
		return
	if c.has("hold"):
		var k := clampf(float(c.hold), 0.0, 1.0)
		draw_arc(p, CUE_R + 2, 0.0, TAU, 40, Color(Kit.INK, 0.6), 4.0)
		if k > 0.0:
			draw_arc(p, CUE_R + 2, -PI / 2.0, -PI / 2.0 + TAU * k, 40, Kit.MUSTARD.lerp(Kit.RELISH, k), 3.0)
		_cue_word(f, p, "HOLD!" if k < 1.0 else "GO!", Kit.MUSTARD)
		return
	var k := clampf(float(c.k), 0.0, 1.0)
	var now := bool(c.get("now", false))
	# the target, a dotted ring round the hot dog
	for i in 24:
		var a := TAU * i / 24.0
		draw_rect(Rect2((p + Vector2(cos(a), sin(a)) * CUE_R).round(), Vector2(1, 1)), Color(Kit.PAPER, 0.7))
	var r := lerpf(CUE_R * 3.6, CUE_R, k)
	var col := Kit.MUSTARD if now else Kit.SKY
	draw_arc(p, r, 0.0, TAU, 48, Color(Kit.INK, 0.5 + 0.5 * k), 4.0)
	draw_arc(p, r, 0.0, TAU, 48, Color(col, 0.45 + 0.55 * k), 2.0)
	if now:
		draw_arc(p, CUE_R + 2.5, 0.0, TAU, 36, Color(Kit.MUSTARD, 0.55), 1.5)
		_cue_word(f, p, "JUMP!", Kit.MUSTARD)


## The aim while the action button's held (game/aim.gd): a quarter dial from
## flat to straight up, in front of the hot dog's feet, with the green on it, a
## needle that climbs, and the degrees.
func _dial(c: Dictionary, p: Vector2, f: Font) -> void:
	var a: Dictionary = c.aim
	var deg := float(a.angle)
	var lo := float(a.lo)
	var hi := float(a.hi)
	var o := (p + Vector2(15, 23)).round()
	var r := 27.0
	var at := func(d: float, rr: float) -> Vector2: return o + Vector2(cos(deg_to_rad(d)), -sin(deg_to_rad(d))) * rr
	# the face: a dark quarter, the green on it, ticks every 15 degrees
	var face := PackedVector2Array([o])
	for k in 19:
		face.append(at.call(k * 5.0, r))
	draw_colored_polygon(face, Color(Kit.INK, 0.6))
	var green := PackedVector2Array([o])
	for k in 9:
		green.append(at.call(lerpf(lo, hi, k / 8.0), r))
	draw_colored_polygon(green, Color(Kit.RELISH, 0.75))
	draw_arc(o, r, -PI / 2.0, 0.0, 24, Kit.INK, 2.0)
	for k in 7:
		draw_line(at.call(k * 15.0, r - 4.0), at.call(k * 15.0, r), Color(Kit.PAPER, 0.7), 1.0)
	# the needle
	var good := deg >= lo and deg <= hi
	var col := Kit.RELISH.lightened(0.3) if good else (Kit.MUSTARD if deg < lo else Kit.KETCHUP)
	draw_line(o, at.call(deg, r + 3.0), Kit.INK, 4.0)
	draw_line(o, at.call(deg, r + 3.0), col, 2.0)
	draw_circle(o, 3.0, Kit.INK)
	draw_circle(o, 1.5, col)
	# the degrees, and what to do
	Kit.outlined(self, f, Vector2(o.x + r + 4, o.y - r + 6), "%d°" % int(roundf(deg)), 9, col)
	var word := "LET GO!" if deg >= lo else "HOLD..."
	Kit.outlined(self, f, Vector2(o.x + r + 4, o.y - r + 17), word, 9, col if deg >= lo else Kit.PAPER)


func _cue_word(f: Font, p: Vector2, text: String, col: Color) -> void:
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	Kit.outlined(self, f, Vector2(roundf(p.x - w / 2.0), roundf(p.y - CUE_R - 14)), text, 9, col)


## An ellipse of single pixels on the ground (the beat ring).
func _ring(c: Vector2, r: float, col: Color) -> void:
	var n := int(r * 4.0)
	var last := Vector2(INF, INF)
	for i in n:
		var a := TAU * i / n
		var p := (c + Vector2(cos(a) * r, sin(a) * r * 0.32)).round()
		if p != last:
			draw_rect(Rect2(p, Vector2(1, 1)), col)
			last = p
