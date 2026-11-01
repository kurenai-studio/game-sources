# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name MapRoutes
extends Node2D
## Route lines for every entrance (docs/ARCHITECTURE.md 4.8, 14.10): solid for walkers, dashed
## with a crack on each closed gate for gate breakers, dotted and straight for flyers. The
## points are worked out once when the lines are set. Internal to src/render/.
##
## A route is split where it takes a twin step (two cells in a row that are not neighbors), so a
## line runs into a stump and starts again at its twin. The base layer draws every line under
## the feature layer, so a deck or a mound covers it. The deck layer (`deck_layer`, a second
## MapRoutes drawn above the feature layer) draws again the part of a walker or breaker line
## that crosses a deck east to west, so it runs on top of the deck, and the flyers' dotted
## line, because flyers fly over every feature. A route that crosses a bridge north to south
## is not drawn again, so the deck cuts it.
##
## Draw calls (docs/ARCHITECTURE.md 9.3). The lines are polylines, a casing and a core for each
## walker part. What moves along them is not: the arrow chevrons, the dashes of a breaker's line
## and the dots of a flyer's line are turned quads of the MapAtlas sheet (RoutePieces), drawn by
## two child layers, one behind the polylines and one over them. So a layer of any length costs
## two draw calls for its marks. The look and the order are those of MapArt.draw_route. A layer
## with no sheet (`use_atlas()` not called) draws no marks.

const CELL: float = 128.0
## How the deck layer draws only a piece of a line and still puts its arrows and dashes where
## the whole line has them: MapArt.draw_route places arrows from the start of the points it is
## given, so a piece starts early enough to hold the arrows of the deck, and the phase is moved
## by the distance of its start. These match MapArt.draw_route's own numbers.
const ARROW_START: float = 0.7
const ARROW_STEP: float = 1.25
const ARROW_END: float = 0.4
const DASH_PERIOD: float = 0.36
## Half the length of a deck with its stone feet, in cells.
const DECK_HALF: float = 0.68

## The piece of a line over one deck.
class Deck:
	extends RefCounted
	var points: PackedVector2Array = PackedVector2Array()
	## Distance along the whole part to where `points` starts, in px.
	var start: float = 0.0
	var lengths: PackedFloat32Array = PackedFloat32Array()

## One entrance's lines, ready to draw. Walker and breaker lines come in parts, one for each
## stretch between twin steps.
class Line:
	extends RefCounted
	var walk: Array[PackedVector2Array] = []
	var breaker: Array[PackedVector2Array] = []
	var fly: PackedVector2Array = PackedVector2Array()
	var cracks: PackedVector2Array = PackedVector2Array()
	var walk_decks: Array[Deck] = []
	var break_decks: Array[Deck] = []
	## The distance along each part to each of its points, for the marks.
	var walk_lengths: Array[PackedFloat32Array] = []
	var break_lengths: Array[PackedFloat32Array] = []
	var fly_lengths: PackedFloat32Array = PackedFloat32Array()

var lines: Array[Line] = []
var phase: float = 0.0
## True for the layer above the features (see the top of this file).
var deck_layer: bool = false
## True for the base layer when the deck layer draws the flyers' line.
var fly_above: bool = false
## The sheet the marks are drawn from.
var atlas: MapAtlas

var _under: MarkLayer
var _over: MarkLayer
var _chevron: MapAtlas.Entry
var _dot: MapAtlas.Entry
var _dash: MapAtlas.Entry
var _texture: Texture2D


## One of the two layers of marks: `above` is false for the one behind the polylines.
class MarkLayer:
	extends Node2D
	var routes: MapRoutes
	var above: bool = false

	func _draw() -> void:
		routes.draw_marks(self, above)


## Gives the layer its sheet, which must hold the route pieces (MapAtlas.add_route_pieces), and
## the material the marks are drawn with: the sheet's premultiplied blend.
func use_atlas(sheet: MapAtlas, marks_material: Material) -> void:
	atlas = sheet
	_texture = sheet.get_texture()
	_chevron = sheet.entry_for(RoutePieces.key(RoutePieces.Piece.CHEVRON))
	_dot = sheet.entry_for(RoutePieces.key(RoutePieces.Piece.DOT))
	_dash = sheet.entry_for(RoutePieces.key(RoutePieces.Piece.DASH))
	if _under != null:
		return
	_under = MarkLayer.new()
	_under.routes = self
	_under.show_behind_parent = true
	_under.material = marks_material
	add_child(_under)
	_over = MarkLayer.new()
	_over.routes = self
	_over.above = true
	_over.material = marks_material
	add_child(_over)


func _redraw() -> void:
	queue_redraw()
	if _under != null:
		_under.queue_redraw()
		_over.queue_redraw()


## `routes` are Battle.routes() entries. An empty list hides the lines.
func set_routes(routes: Array[Dictionary], level: LevelData) -> void:
	lines.clear()
	for r: Dictionary in routes:
		var line: Line = Line.new()
		line.walk = _parts(_cells(r.get("walk", [])), level, line.walk_decks)
		line.breaker = _parts(_cells(r.get("break", [])), level, line.break_decks)
		for part: PackedVector2Array in line.walk:
			line.walk_lengths.append(_lengths(part))
		for part: PackedVector2Array in line.breaker:
			line.break_lengths.append(_lengths(part))
		for c: Vector2i in _cells(r.get("cracks", [])):
			line.cracks.append((Vector2(c) + Vector2(0.5, 0.5)) * CELL)
		var index: int = int(r.get("entrance", 1)) - 1
		if bool(r.get("fly", false)) and index >= 0 and index < level.entrances.size():
			line.fly = PackedVector2Array([
				(Vector2(level.entrances[index]) + Vector2(0.5, 0.5)) * CELL,
				(Vector2(level.base) + Vector2(0.5, 0.5)) * CELL])
			line.fly_lengths = _lengths(line.fly)
		lines.append(line)
	_redraw()


func is_showing() -> bool:
	return not lines.is_empty()


## How many deck pieces the lines hold, for tests.
func deck_count() -> int:
	var n: int = 0
	for line: Line in lines:
		n += line.walk_decks.size() + line.break_decks.size()
	return n


func advance(seconds: float) -> void:
	if lines.is_empty():
		return
	phase = fposmod(phase + seconds * 0.35, 1.0)
	_redraw()


## The polylines: the breakers' cracks and the walkers' lines, or on the deck layer the pieces of
## walker lines over decks. What moves along them is in the two MarkLayers (draw_marks).
func _draw() -> void:
	if deck_layer:
		for line: Line in lines:
			for deck: Deck in line.walk_decks:
				_solid(deck.points)
		return
	for line: Line in lines:
		for c: Vector2 in line.cracks:
			var zig: PackedVector2Array = PackedVector2Array([
				c + Vector2(-2, -44) * CELL / 100.0, c + Vector2(6, -32) * CELL / 100.0,
				c + Vector2(-4, -22) * CELL / 100.0, c + Vector2(5, -10) * CELL / 100.0,
				c + Vector2(-1, 2) * CELL / 100.0])
			draw_polyline(zig, Palette.INK_LINE, CELL * 0.1, true)
			draw_polyline(zig, Palette.FLOUR, CELL * 0.05, true)
	for line: Line in lines:
		for part: PackedVector2Array in line.walk:
			_solid(part)


## A solid line with a dark casing, as MapArt.draw_route draws a walker's.
func _solid(points: PackedVector2Array) -> void:
	if points.size() < 2:
		return
	draw_polyline(points, Palette.INK_LINE, CELL * 0.11, true)
	draw_polyline(points, Palette.ROUTE, CELL * 0.055, true)


## The marks, in the order MapArt.draw_route puts them: behind the polylines the flyers' dots,
## then the breakers' dashes with their arrows; over them the walkers' arrows. On the deck layer
## the flyers' line is whole and the breaker and walker marks are those of the deck pieces.
func draw_marks(canvas: Node2D, above: bool) -> void:
	if lines.is_empty() or atlas == null or _chevron == null:
		return
	for line: Line in lines:
		if above:
			if deck_layer:
				for deck: Deck in line.walk_decks:
					_arrows(canvas, deck.points, deck.lengths, fposmod(phase - deck.start / (ARROW_STEP * CELL), 1.0))
			else:
				for i: int in line.walk.size():
					_arrows(canvas, line.walk[i], line.walk_lengths[i], phase)
			continue
		if line.fly.size() >= 2 and (deck_layer or not fly_above):
			_dots(canvas, line.fly, line.fly_lengths)
		if deck_layer:
			for deck: Deck in line.break_decks:
				var ph: float = fposmod(phase - deck.start / (DASH_PERIOD * CELL), 1.0)
				_dashes(canvas, deck.points, deck.lengths, ph)
				_arrows(canvas, deck.points, deck.lengths, ph)
		else:
			for i: int in line.breaker.size():
				_dashes(canvas, line.breaker[i], line.break_lengths[i], phase)
				_arrows(canvas, line.breaker[i], line.break_lengths[i], phase)
	_end_marks(canvas)


## Puts the canvas's transform back after the quads. Tests replace _quad and this to record the marks.
func _end_marks(canvas: Node2D) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Arrow chevrons along a line, as MapArt.draw_route places them.
func _arrows(canvas: Node2D, points: PackedVector2Array, lengths: PackedFloat32Array, ph: float) -> void:
	if points.size() < 2 or lengths.size() != points.size():
		return
	var total: float = lengths[lengths.size() - 1]
	var step: float = ARROW_STEP * CELL
	var a: float = ARROW_START * CELL + fposmod(ph, 1.0) * step
	var seg: int = 1
	while a < total - ARROW_END * CELL:
		seg = _seg_for(lengths, a, seg)
		var p: Vector2 = _lerp_at(points, lengths, a, seg)
		var q: Vector2 = _lerp_at(points, lengths, a + 1.0, _seg_for(lengths, a + 1.0, seg))
		_quad(canvas, _chevron, p, (q - p).normalized().angle(), 1.0)
		a += step


## Dashes along a breaker's line: DASH_PERIOD cells apart, each 0.55 of that long. A dash is a
## straight piece turned along its chord, which on a bend of the road is off by under a pixel.
func _dashes(canvas: Node2D, points: PackedVector2Array, lengths: PackedFloat32Array, ph: float) -> void:
	if points.size() < 2 or lengths.size() != points.size():
		return
	var total: float = lengths[lengths.size() - 1]
	var period: float = DASH_PERIOD * CELL
	var full: float = RoutePieces.DASH_LENGTH * CELL
	var d: float = fposmod(ph, 1.0) * period
	var seg: int = 1
	while d < total:
		var end: float = minf(d + period * 0.55, total)
		if end - d >= 1.0:
			seg = _seg_for(lengths, d, seg)
			var mid: float = (d + end) * 0.5
			var mid_seg: int = _seg_for(lengths, mid, seg)
			var p0: Vector2 = _lerp_at(points, lengths, d, seg)
			var p1: Vector2 = _lerp_at(points, lengths, end, _seg_for(lengths, end, mid_seg))
			_quad(canvas, _dash, _lerp_at(points, lengths, mid, mid_seg), (p1 - p0).normalized().angle(), (end - d) / full)
		d += period


## Dots along a flyer's line, 0.24 of a cell apart.
func _dots(canvas: Node2D, points: PackedVector2Array, lengths: PackedFloat32Array) -> void:
	if points.size() < 2 or lengths.size() != points.size():
		return
	var total: float = lengths[lengths.size() - 1]
	var gap: float = CELL * 0.24
	var d: float = fposmod(phase, 1.0) * gap
	var seg: int = 1
	while d < total:
		seg = _seg_for(lengths, d, seg)
		_quad(canvas, _dot, _lerp_at(points, lengths, d, seg), 0.0, 1.0)
		d += gap


## One piece of the sheet, anchored at `at`, turned by `angle` and stretched along its length.
func _quad(canvas: Node2D, e: MapAtlas.Entry, at: Vector2, angle: float, stretch: float) -> void:
	canvas.draw_set_transform(at, angle, Vector2(stretch, 1.0))
	canvas.draw_texture_rect_region(_texture, Rect2(-e.anchor, e.tile), e.rect)


## The segment of `lengths` that holds distance `d`, looking on from segment `from`.
static func _seg_for(lengths: PackedFloat32Array, d: float, from: int) -> int:
	var i: int = maxi(from, 1)
	var last: int = lengths.size() - 1
	while i < last and d > lengths[i]:
		i += 1
	return i


## The point at distance `d` along `points`, which lies on segment `i` (see _seg_for).
static func _lerp_at(points: PackedVector2Array, lengths: PackedFloat32Array, d: float, i: int) -> Vector2:
	var span: float = lengths[i] - lengths[i - 1]
	if span <= 0.0:
		return points[i]
	return points[i - 1].lerp(points[i], clampf((d - lengths[i - 1]) / span, 0.0, 1.0))


## The drawn points of every stretch of `cells` between twin steps, and the pieces over decks.
func _parts(cells: Array[Vector2i], level: LevelData, decks: Array[Deck]) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var start: int = 0
	for i: int in range(1, cells.size() + 1):
		if i < cells.size() and absi(cells[i].x - cells[i - 1].x) + absi(cells[i].y - cells[i - 1].y) == 1:
			continue
		if i - start >= 2:
			var part: Array[Vector2i] = []
			for k: int in range(start, i):
				part.append(cells[k])
			var points: PackedVector2Array = MapArt.route_points(part, CELL)
			out.append(points)
			_find_decks(part, points, level, decks)
		start = i
	return out


## The pieces of `points` that cross a deck east to west. `cells` are the cells they were
## made from. Only a bridge that the line crosses straight and level counts: the line is then
## a vertex at the center of the bridge cell.
func _find_decks(cells: Array[Vector2i], points: PackedVector2Array, level: LevelData, decks: Array[Deck]) -> void:
	var lengths: PackedFloat32Array = PackedFloat32Array()
	for k: int in range(1, cells.size() - 1):
		if level.feature_at(cells[k]) != LevelData.Feature.BRIDGE:
			continue
		if cells[k - 1].y != cells[k].y or cells[k + 1].y != cells[k].y:
			continue
		if lengths.is_empty():
			lengths = _lengths(points)
		var center: Vector2 = (Vector2(cells[k]) + Vector2(0.5, 0.5)) * CELL
		var at: int = -1
		for j: int in points.size():
			if points[j].distance_to(center) < 0.5:
				at = j
				break
		if at < 0:
			continue
		var total: float = lengths[lengths.size() - 1]
		var from: float = lengths[at] - DECK_HALF * CELL
		var to: float = lengths[at] + DECK_HALF * CELL
		# More line on each side holds the arrows of the deck, but only over plain road.
		if _plain(level, cells[k - 1]):
			from -= ARROW_START * CELL
		if _plain(level, cells[k + 1]):
			to += ARROW_END * CELL
		var deck: Deck = Deck.new()
		deck.start = maxf(from, 0.0)
		deck.points = _slice(points, lengths, deck.start, minf(to, total))
		if deck.points.size() >= 2:
			deck.lengths = _lengths(deck.points)
			decks.append(deck)


static func _plain(level: LevelData, cell: Vector2i) -> bool:
	var feature: LevelData.Feature = level.feature_at(cell)
	return feature == LevelData.Feature.NONE or feature == LevelData.Feature.SLIDE


static func _lengths(points: PackedVector2Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	var sum: float = 0.0
	for i: int in points.size():
		if i > 0:
			sum += points[i].distance_to(points[i - 1])
		out.append(sum)
	return out


## The points from distance `d0` to `d1` along the line.
static func _slice(points: PackedVector2Array, lengths: PackedFloat32Array, d0: float, d1: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	if points.size() < 2 or d1 <= d0:
		return out
	out.append(_point_at(points, lengths, d0))
	for i: int in points.size():
		if lengths[i] > d0 and lengths[i] < d1:
			out.append(points[i])
	out.append(_point_at(points, lengths, d1))
	return out


static func _point_at(points: PackedVector2Array, lengths: PackedFloat32Array, d: float) -> Vector2:
	for i: int in range(1, points.size()):
		if d <= lengths[i]:
			var span: float = lengths[i] - lengths[i - 1]
			return points[i - 1] if span <= 0.0 else points[i - 1].lerp(points[i], (d - lengths[i - 1]) / span)
	return points[points.size() - 1]


static func _cells(raw: Variant) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if raw is Array:
		for c: Variant in raw as Array:
			if c is Vector2i:
				out.append(c)
	return out
