class_name ForestMap
extends RefCounted
## The map of the forest the cats carved on the board at the gate, drawn: the canopy from above,
## the river, the village at its western edge, and the path from it through every area in the order
## they're found. An area held by the company is drawn wrecked, stumps and ash and smoke; one that's
## free is drawn green again; one not found yet is under mist. Endless lies off the map's top
## corner, beyond the paths.

## Where each place is on the map, as a share of its width and height.
const SPOTS := {
	"village": Vector2(0.07, 0.8), "edge": Vector2(0.19, 0.6), "deep": Vector2(0.3, 0.3),
	"sawpits": Vector2(0.44, 0.6), "clearing": Vector2(0.56, 0.27), "slide": Vector2(0.67, 0.66),
	"offices": Vector2(0.81, 0.45), "airstrip": Vector2(0.91, 0.2), "endless": Vector2(0.09, 0.2),
}
## The river, as a share of the map: it runs down past the log slide, under the path.
const RIVER: Array[Vector2] = [
	Vector2(0.77, 0.0), Vector2(0.74, 0.2), Vector2(0.75, 0.4), Vector2(0.72, 0.58),
	Vector2(0.62, 0.8), Vector2(0.6, 1.0),
]
## How big an area's picture is, in pixels.
const PATCH := Vector2(40, 28)


## Draws the map in a box: rows are the board's places ({id, found, free}) in order, the area
## chosen is framed, and the one the next run goes to is pinned.
static func draw(canvas: CanvasItem, box: Rect2, rows: Array[Dictionary], choice: int, next_run: String) -> void:
	canvas.draw_rect(box, Palette.JUNGLE_DARK)
	_canopy(canvas, box)
	_river(canvas, box)
	# The path: from the village through each area found, and on into the mist at the first not
	# found yet.
	var from := _at(box, "village")
	for row in rows:
		if row.id == "endless":
			continue
		var to := _at(box, row.id)
		_dotted(canvas, from, to, Palette.DRY_GRASS if row.found else Palette.SMOKE)
		if not row.found:
			break
		from = to
	_village(canvas, _at(box, "village"))
	for index in rows.size():
		var row: Dictionary = rows[index]
		var patch := Rect2((_at(box, row.id) - PATCH / 2.0).floor(), PATCH)
		if row.id == "endless":
			_endless(canvas, patch)
		elif not row.found:
			_mist(canvas, patch)
		else:
			_area(canvas, patch, row.id, row.free)
		if index == choice:
			canvas.draw_rect(patch.grow(2), Palette.PINK, false, 1.0)
			canvas.draw_rect(patch.grow(3), Palette.GRAPHITE, false, 1.0)
		if row.id == next_run:
			_pin(canvas, Vector2(patch.end.x - 4, patch.position.y - 2))
	canvas.draw_rect(box, Palette.BARK, false, 1.0)
	canvas.draw_rect(box.grow(1), Palette.OUTLINE, false, 1.0)


static func _at(box: Rect2, id: String) -> Vector2:
	return (box.position + box.size * (SPOTS[id] as Vector2)).floor()


## The canopy from above: crowns of trees, dark below and lit from the top left, the same every
## time.
static func _canopy(canvas: CanvasItem, box: Rect2) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 39
	for crown in int(box.size.x * box.size.y / 90.0):
		var at := box.position + Vector2(random.randi_range(1, int(box.size.x) - 6), random.randi_range(1, int(box.size.y) - 6))
		var size := random.randi_range(3, 5)
		canvas.draw_rect(Rect2(at + Vector2(1, 1), Vector2(size, size)), Palette.JUNGLE_DEEP)
		canvas.draw_rect(Rect2(at, Vector2(size, size)), Palette.JUNGLE)
		canvas.draw_rect(Rect2(at, Vector2(1, 1)), Palette.LEAF)


static func _river(canvas: CanvasItem, box: Rect2) -> void:
	for index in RIVER.size() - 1:
		var from := box.position + box.size * RIVER[index]
		var to := box.position + box.size * RIVER[index + 1]
		var steps := int(from.distance_to(to))
		for step in steps:
			var at := from.lerp(to, float(step) / steps).floor()
			canvas.draw_rect(Rect2(at - Vector2(2, 0), Vector2(5, 1)), Palette.CLOTH)
			canvas.draw_rect(Rect2(at - Vector2(1, 0), Vector2(1, 1)), Palette.CLOTH_LIGHT)


static func _dotted(canvas: CanvasItem, from: Vector2, to: Vector2, color: Color) -> void:
	var steps := int(from.distance_to(to) / 4.0)
	for step in steps:
		var at := from.lerp(to, float(step) / steps).floor()
		canvas.draw_rect(Rect2(at, Vector2(2, 2)), color)


## The village: three huts and a banner, where every path starts.
static func _village(canvas: CanvasItem, at: Vector2) -> void:
	for hut: Vector2 in [Vector2(-9, -2), Vector2(-1, -5), Vector2(6, -1)]:
		var corner := at + hut
		canvas.draw_rect(Rect2(corner + Vector2(0, 3), Vector2(6, 4)), Palette.BARK_LIGHT)
		canvas.draw_rect(Rect2(corner + Vector2(-1, 1), Vector2(8, 2)), Palette.DRY_GRASS)
		canvas.draw_rect(Rect2(corner + Vector2(1, 0), Vector2(4, 1)), Palette.DRY_GRASS)
		canvas.draw_rect(Rect2(corner + Vector2(2, 5), Vector2(2, 2)), Palette.OUTLINE)
	canvas.draw_rect(Rect2(at + Vector2(3, -12), Vector2(1, 8)), Palette.BARK)
	canvas.draw_rect(Rect2(at + Vector2(4, -12), Vector2(3, 2)), Palette.PINK)


## An area found: wrecked while the company holds it, green again once it's free, with what makes
## it that place drawn on top.
static func _area(canvas: CanvasItem, patch: Rect2, id: String, free: bool) -> void:
	canvas.draw_rect(patch, Palette.LEAF if free else Palette.MUD)
	var random := RandomNumberGenerator.new()
	random.seed = absi(hash(id))
	# The ground: saplings and flowers, or ash and stumps.
	for mark in 14:
		var at := patch.position + Vector2(random.randi_range(1, int(patch.size.x) - 3), random.randi_range(1, int(patch.size.y) - 3))
		if free:
			canvas.draw_rect(Rect2(at, Vector2(2, 2)), Palette.LEAF_LIGHT if mark % 3 != 0 else Palette.JUNGLE)
			if mark % 5 == 0:
				canvas.draw_rect(Rect2(at + Vector2(0, -1), Vector2(1, 1)), Palette.PINK)
		else:
			canvas.draw_rect(Rect2(at, Vector2(3, 2)), Palette.BURNT if mark % 2 == 0 else Palette.MUD_DARK)
			if mark % 4 == 0:
				canvas.draw_rect(Rect2(at + Vector2(0, -1), Vector2(2, 2)), Palette.BARK_LIGHT)
	var middle := (patch.get_center() - Vector2(0, 1)).floor()
	match id:
		"edge":
			# The village's last hut, and the nest beside it.
			canvas.draw_rect(Rect2(middle + Vector2(-9, -1), Vector2(7, 5)), Palette.BARK_LIGHT)
			canvas.draw_rect(Rect2(middle + Vector2(-10, -3), Vector2(9, 2)), Palette.DRY_GRASS)
			if not free:
				canvas.draw_rect(Rect2(middle + Vector2(3, 0), Vector2(7, 4)), Palette.MUD_DARK)
				canvas.draw_rect(Rect2(middle + Vector2(4, -1), Vector2(5, 1)), Palette.RAT)
		"deep":
			# Tall trees, felled ones lying among them while it's held.
			for tree in [-10, -3, 5]:
				canvas.draw_rect(Rect2(middle + Vector2(tree, -8), Vector2(6, 7)), Palette.JUNGLE if free else Palette.JUNGLE_DARK)
				canvas.draw_rect(Rect2(middle + Vector2(tree + 2, -1), Vector2(2, 6)), Palette.BARK)
			if not free:
				canvas.draw_rect(Rect2(middle + Vector2(-8, 7), Vector2(14, 2)), Palette.BARK_LIGHT)
		"sawpits":
			# Two pits, and the saw's blade.
			for pit in [-11, 4]:
				canvas.draw_rect(Rect2(middle + Vector2(pit, 1), Vector2(7, 4)), Palette.MUD_DARK)
			if not free:
				canvas.draw_rect(Rect2(middle + Vector2(-3, -7), Vector2(6, 6)), Palette.STEEL)
				canvas.draw_rect(Rect2(middle + Vector2(-1, -5), Vector2(2, 2)), Palette.STEEL_DARK)
				canvas.draw_rect(Rect2(middle + Vector2(-4, -8), Vector2(1, 1)), Palette.STEEL_LIGHT)
		"clearing":
			# Stumps in rows where the fig grove was; saplings between them once it's free.
			for row in 2:
				for column in 4:
					var stump := middle + Vector2(-12 + column * 7, -5 + row * 7)
					canvas.draw_rect(Rect2(stump, Vector2(3, 2)), Palette.BARK_LIGHT)
					if free:
						canvas.draw_rect(Rect2(stump + Vector2(1, -2), Vector2(1, 2)), Palette.LEAF_LIGHT)
		"slide":
			# The chute of mud down to the river, logs on it while it's held.
			for step in 16:
				canvas.draw_rect(Rect2(middle + Vector2(-14 + step * 2, -8 + step), Vector2(3, 2)), Palette.MUD_DARK if not free else Palette.MOSS)
			if not free:
				canvas.draw_rect(Rect2(middle + Vector2(-6, -5), Vector2(5, 2)), Palette.BARK_LIGHT)
				canvas.draw_rect(Rect2(middle + Vector2(4, 1), Vector2(5, 2)), Palette.BARK_LIGHT)
		"offices":
			# Cabins in a row, with the hum of their lights while it's held.
			for cabin in [-12, -2, 8]:
				canvas.draw_rect(Rect2(middle + Vector2(cabin, -3), Vector2(7, 6)), Palette.STEEL if not free else Palette.BARK_LIGHT)
				canvas.draw_rect(Rect2(middle + Vector2(cabin - 1, -4), Vector2(9, 1)), Palette.STEEL_DARK if not free else Palette.MOSS)
				canvas.draw_rect(Rect2(middle + Vector2(cabin + 2, -1), Vector2(2, 2)), Palette.SPARK if not free else Palette.OUTLINE)
		"airstrip":
			# The strip, and the ribbon strung across it.
			canvas.draw_rect(Rect2(middle + Vector2(-16, -2), Vector2(32, 5)), Palette.STEEL_DARK if not free else Palette.DRY_GRASS)
			for dash in 5:
				canvas.draw_rect(Rect2(middle + Vector2(-13 + dash * 6, 0), Vector2(3, 1)), Palette.OFF_WHITE if not free else Palette.LEAF_LIGHT)
			if not free:
				canvas.draw_rect(Rect2(middle + Vector2(-1, -5), Vector2(1, 11)), Palette.SCARF_RED)
	if not free:
		# Smoke from what's burning, and the company's orange where it's working.
		canvas.draw_rect(Rect2(patch.position + Vector2(patch.size.x - 8, 2), Vector2(2, 2)), Palette.SMOKE)
		canvas.draw_rect(Rect2(patch.position + Vector2(patch.size.x - 6, 0), Vector2(2, 1)), Palette.SMOKE)
		canvas.draw_rect(Rect2(patch.position + Vector2(3, patch.size.y - 5), Vector2(2, 3)), Palette.HI_VIS)
	canvas.draw_rect(patch, Palette.OUTLINE, false, 1.0)


## Somewhere not found yet: mist over the trees, and a question.
static func _mist(canvas: CanvasItem, patch: Rect2) -> void:
	for y in int(patch.size.y):
		for x in int(patch.size.x):
			if (x + y) % 2 == 0:
				canvas.draw_rect(Rect2(patch.position + Vector2(x, y), Vector2(1, 1)), Palette.SMOKE)
	PixelFont.draw(canvas, (patch.get_center() - Vector2(PixelFont.width("?") / 2.0, PixelFont.ASCENT / 2.0 + 1)).floor(), "?", Palette.GRAPHITE)


## Endless: off the map, a fresh clearing every time, past where the paths go.
static func _endless(canvas: CanvasItem, patch: Rect2) -> void:
	canvas.draw_rect(patch, Palette.DRY_GRASS)
	for ring in 3:
		canvas.draw_rect(patch.grow(-4 - ring * 4), Palette.MOSS if ring % 2 == 0 else Palette.DRY_GRASS, false, 1.0)
	canvas.draw_rect(Rect2(patch.get_center() - Vector2(1, 1), Vector2(2, 2)), Palette.HI_VIS)
	canvas.draw_rect(patch, Palette.OUTLINE, false, 1.0)


## The pin on where the next run goes.
static func _pin(canvas: CanvasItem, at: Vector2) -> void:
	canvas.draw_rect(Rect2(at + Vector2(1, 3), Vector2(1, 4)), Palette.OUTLINE)
	canvas.draw_rect(Rect2(at - Vector2(1, 1), Vector2(5, 5)), Palette.OUTLINE)
	canvas.draw_rect(Rect2(at, Vector2(3, 3)), Palette.BRASS_LIGHT)
