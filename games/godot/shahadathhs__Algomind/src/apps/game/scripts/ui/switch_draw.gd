class_name SwitchDraw
extends RefCounted
## Switches and gates (`switches`), drawn the same way on the flat and the depth board; `place`
## maps a point in board units to the canvas, as in LockDraw. A switch is a plate with a lever
## whose knob sits at the left when its gate has not been flipped and at the right when it has. A
## shut gate is a block with bars; an open gate is only two posts. With several pairs, a switch and
## its gate carry the same number of pips, so the pairing is never only a color.

const POST := 0.12


## Which pairs are flipped (their switch cell entered an odd number of times in `trail`) and which
## gates are open, by pair index.
static func state(level: Dictionary, trail: Array[Vector2i]) -> Dictionary:
	var flipped := {}
	var open := {}
	var pairs: Array = level.get("switches", [])
	for i in pairs.size():
		var at := LockDraw.cell_of(pairs[i], "switch")
		var count := 0
		for cell in trail:
			if cell == at:
				count += 1
		if count % 2 == 1:
			flipped[i] = true
		if pairs[i].get("open", false) != flipped.has(i):
			open[i] = true
	return {"flipped": flipped, "open": open}


## Draws the switch plates, the knob showing which way each is set.
static func draw_switches(
	canvas: CanvasItem, level: Dictionary, trail: Array[Vector2i], place: Callable, ink: Color
) -> void:
	var flipped: Dictionary = state(level, trail)["flipped"]
	var pairs: Array = level["switches"]
	for i in pairs.size():
		var cell := LockDraw.cell_of(pairs[i], "switch")
		var plate := LockDraw.box(Vector2(0.18, 0.18), Vector2(0.82, 0.82))
		var outline := PackedVector2Array()
		for point in plate:
			outline.append(place.call(Vector2(cell) + point))
		outline.append(outline[0])
		canvas.draw_polyline(outline, ink, 2.0)
		LockDraw.fill(
			canvas, place, cell, LockDraw.box(Vector2(0.3, 0.46), Vector2(0.7, 0.52)), ink
		)
		var knob_x := 0.64 if flipped.has(i) else 0.36
		var knob := LockDraw.box(Vector2(knob_x - 0.09, 0.38), Vector2(knob_x + 0.09, 0.6))
		LockDraw.fill(canvas, place, cell, knob, ink)
		if pairs.size() > 1:
			LockDraw.pips(canvas, place, cell, i, ink)


## Draws a gate: two posts when open; when shut, the bars, on a flat block (`flat_block`) or on the
## top of the raised block the depth board has already drawn.
static func draw_gate(
	canvas: CanvasItem,
	level: Dictionary,
	index: int,
	open: bool,
	place: Callable,
	flat_block: bool,
	colors: Dictionary
) -> void:
	var pairs: Array = level["switches"]
	var cell := LockDraw.cell_of(pairs[index], "gate")
	if open:
		var low := LockDraw.box(Vector2(0.1, 0.4), Vector2(0.1 + POST, 0.6))
		var high := LockDraw.box(Vector2(0.9 - POST, 0.4), Vector2(0.9, 0.6))
		LockDraw.fill(canvas, place, cell, low, colors["block"])
		LockDraw.fill(canvas, place, cell, high, colors["block"])
	else:
		if flat_block:
			LockDraw.fill(
				canvas,
				place,
				cell,
				LockDraw.box(Vector2(0.1, 0.1), Vector2(0.9, 0.9)),
				colors["block"]
			)
		for n in 3:
			var x := 0.28 + 0.22 * float(n)
			var bar := LockDraw.box(Vector2(x - 0.04, 0.2), Vector2(x + 0.04, 0.8))
			LockDraw.fill(canvas, place, cell, bar, colors["bar"])
	if pairs.size() > 1:
		LockDraw.pips(canvas, place, cell, index, colors["block"] if open else colors["bar"])
