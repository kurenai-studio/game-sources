# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name MapAtlas
extends SubViewport
## One sheet of pictures for every tower look, every creature frame and the status
## marks, drawn once with Silhouettes into this viewport's texture (docs/ARCHITECTURE.md
## 9.3). Every sprite on the map is then a region of this one texture, so the
## Compatibility renderer batches them into very few draw calls, and nothing runs
## Silhouettes code while a wave is playing.
##
## Sizes in an Entry are in map local pixels (a cell is MapView.CELL). The sheet is
## drawn at `texel_scale` texels per local pixel, so the sprites stay sharp on the
## screen they are shown on. Internal to src/render/.

const CELL: float = 128.0
const WIDTH: int = 2048
## The sheet never grows taller than this (contract 14.10). When the pictures would not fit at the
## asked sharpness, bake() lowers it in steps of SCALE_STEP until they do.
const MAX_HEIGHT: int = 4096
const SCALE_STEP: float = 0.25
const MIN_SCALE: float = 0.25
const PAD: int = 2
## Tower tile, as fractions of a cell: the building reaches 0.86 up and 0.42 down.
const TOWER_TILE: Vector2 = Vector2(1.12, 1.36)
const TOWER_CENTER: Vector2 = Vector2(0.56, 0.90)
## Towers are drawn a little smaller than the cell side, about their ground line. The tallest
## look reaches TOWER_REACH above its ground line at full size (measured with
## tests/render/tower_extent.gd), so at this scale it stays inside the cell above's ground
## line, and a tower on the build spot below never covers the stone steps of the one above.
## The widest look is TOWER_HALF_WIDTH each side of the center, so side neighbours stay apart.
const TOWER_SCALE: float = 0.84
const TOWER_REACH: float = 1.17
const TOWER_HALF_WIDTH: float = 0.55
## A creature tile is its box times this, so the outline has room.
const ENEMY_TILE: float = 1.26
const BUBBLE_TILE: float = 1.1
const DROWSY_TILE: Vector2 = Vector2(0.7, 0.6)
const DROWSY_ANCHOR: Vector2 = Vector2(0.1, 0.95)
const BOOST_TILE: float = 1.1

const GATE_TILE: float = 1.3
const HEART_TILE: float = 1.0
## A lured flyer is drawn this far (a fraction of its box) lower than a high one, just above the
## ring at its shadow (Silhouettes.draw_mark, &"low"), which stays where the shadow is.
const LOW_DROP: float = 0.14
## Room round a recorded mark, in drawing units (a cell is 100), for its ink edge.
const MARK_MARGIN: float = 4.0

enum Kind { TOWER, ENEMY, DROWSY, BUBBLE, BOOST, GATE, HEART, PIECE, ROUTE, MARK, LOW }


## One picture on the sheet.
class Entry:
	extends RefCounted
	var key: String = ""
	var kind: int = 0
	var type: StringName = &""
	var tier: int = 1
	var spec: int = -1
	var frame: int = 0
	## Tile size, the drawing center and the ground or feet point, in local pixels.
	var tile: Vector2 = Vector2.ZERO
	var center: Vector2 = Vector2.ZERO
	var anchor: Vector2 = Vector2.ZERO
	## Where the tile sits on the sheet, in texels.
	var rect: Rect2 = Rect2()


## Draws the entries. Counts its draws so tests can see the sheet is not redrawn.
class Painter:
	extends Node2D
	var atlas: MapAtlas

	func _draw() -> void:
		atlas.paint(self)


var texel_scale: float = 1.0
var entries: Array[Entry] = []
## How many times the sheet was laid out and queued for drawing.
var bakes: int = 0
## Frame rects per creature type, four each, for the per frame lookups.
var enemy_rects: Dictionary[StringName, Array] = {}
## The same for the lowered picture of each flyer, and for each status mark (one rect, four for &"dug").
var low_rects: Dictionary[StringName, Array] = {}
var mark_rects: Dictionary[StringName, Array] = {}

var _index: Dictionary[String, int] = {}
var _painter: Painter
var _draws: int = 0


func _init() -> void:
	transparent_bg = true
	disable_3d = true
	gui_disable_input = true
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	size = Vector2i(WIDTH, 64)
	_painter = Painter.new()
	_painter.atlas = self
	add_child(_painter)


static func tower_key(type: StringName, tier: int, spec: int) -> String:
	var t: int = clampi(tier, 1, 3)
	return "t:%s:%d:%d" % [type, t, spec if t == 3 else -1]


static func enemy_key(type: StringName, frame: int) -> String:
	return "e:%s:%d" % [type, frame]


static func low_key(type: StringName, frame: int) -> String:
	return "l:%s:%d" % [type, frame]


static func mark_key(mark: StringName, frame: int) -> String:
	return "k:%s:%d" % [mark, frame]


func has_key(key: String) -> bool:
	return _index.has(key)


func entry_for(key: String) -> Entry:
	if not _index.has(key):
		return null
	return entries[_index[key]]


func add_tower(type: StringName, tier: int, spec: int) -> void:
	var key: String = tower_key(type, tier, spec)
	if _index.has(key):
		return
	var e: Entry = Entry.new()
	e.key = key
	e.kind = Kind.TOWER
	e.type = type
	e.tier = clampi(tier, 1, 3)
	e.spec = spec if e.tier == 3 else -1
	e.tile = TOWER_TILE * CELL
	e.center = TOWER_CENTER * CELL
	e.anchor = e.center + Vector2(0.0, Silhouettes.TOWER_GROUND * CELL)
	_add(e)


## Every look of one tower: tier 1, tier 2 and both tier 3 paths.
func add_tower_looks(type: StringName) -> void:
	add_tower(type, 1, -1)
	add_tower(type, 2, -1)
	add_tower(type, 3, 0)
	add_tower(type, 3, 1)


## `flyer` also makes the lowered picture a lured flyer is drawn with.
func add_enemy(type: StringName, flyer: bool = false) -> void:
	if flyer and not low_rects.has(type):
		_add_low(type)
	if enemy_rects.has(type):
		return
	var box: float = Silhouettes.enemy_size(type, CELL)
	var side: float = box * ENEMY_TILE
	for frame: int in 4:
		var e: Entry = Entry.new()
		e.key = enemy_key(type, frame)
		e.kind = Kind.ENEMY
		e.type = type
		e.frame = frame
		e.tile = Vector2(side, side)
		e.center = e.tile * 0.5
		e.anchor = e.center + Vector2(0.0, Silhouettes.FEET * box)
		_add(e)
	enemy_rects[type] = [Rect2(), Rect2(), Rect2(), Rect2()]


## The picture of a flyer a Moth Lantern pulled low: the body sits LOW_DROP lower, the shadow stays.
func _add_low(type: StringName) -> void:
	var box: float = Silhouettes.enemy_size(type, CELL)
	var side: float = box * ENEMY_TILE
	for frame: int in 4:
		var e: Entry = Entry.new()
		e.key = low_key(type, frame)
		e.kind = Kind.LOW
		e.type = type
		e.frame = frame
		e.tile = Vector2(side, side + LOW_DROP * box)
		e.center = Vector2(side, side) * 0.5
		e.anchor = e.center + Vector2(0.0, Silhouettes.FEET * box)
		_add(e)
	low_rects[type] = [Rect2(), Rect2(), Rect2(), Rect2()]


## One picture for every status mark of Silhouettes.MARKS (four for &"dug", the only one that moves),
## each sized to what it draws. A creature mark is drawn for a box of CELL, centered on the creature,
## so MapStatus scales it to the creature. The doze mark is drawn for a tower. The &"dug" picture
## stands on the feet line, so it can take the place of a creature's sprite.
func add_status_marks() -> void:
	if not mark_rects.is_empty():
		return
	for mark: StringName in Silhouettes.MARKS:
		var frames: int = 4 if mark == &"dug" else 1
		var rects: Array = []
		for frame: int in frames:
			var pen: InkPen = InkPen.new(null)
			Silhouettes.mark_into(pen, mark, Vector2.ZERO, 100.0, frame)
			var box: Rect2 = Rect2()
			var first: bool = true
			for sh: InkPen.Shape in pen.shapes:
				if sh.color.a < 0.5:
					continue
				for p: Vector2 in sh.points:
					var r: Rect2 = Rect2(p, Vector2.ZERO).grow(sh.width * 0.5)
					box = r if first else box.merge(r)
					first = false
			box = box.grow(MARK_MARGIN)
			var e: Entry = Entry.new()
			e.key = mark_key(mark, frame)
			e.kind = Kind.MARK
			e.type = mark
			e.frame = frame
			e.tile = box.size * CELL / 100.0
			e.center = -box.position * CELL / 100.0
			e.anchor = e.center + (Vector2(0.0, Silhouettes.FEET * CELL) if mark == &"dug" else Vector2.ZERO)
			_add(e)
			rects.append(Rect2())
		mark_rects[mark] = rects


## The status marks: the drowsy "z z" (four frames), the bubble ring, the boost chevrons and
## the heart that floats up from the home when a creature gets through.
func add_marks() -> void:
	if _index.has("m:bubble"):
		return
	for frame: int in 4:
		var d: Entry = Entry.new()
		d.key = "m:drowsy:%d" % frame
		d.kind = Kind.DROWSY
		d.frame = frame
		d.tile = DROWSY_TILE * CELL
		d.center = DROWSY_ANCHOR * CELL
		d.anchor = d.center
		_add(d)
	var b: Entry = Entry.new()
	b.key = "m:bubble"
	b.kind = Kind.BUBBLE
	b.tile = Vector2(BUBBLE_TILE, BUBBLE_TILE) * CELL
	b.center = b.tile * 0.5
	b.anchor = b.center
	_add(b)
	var x: Entry = Entry.new()
	x.key = "m:boost"
	x.kind = Kind.BOOST
	x.tile = Vector2(BOOST_TILE, BOOST_TILE) * CELL
	x.center = x.tile * 0.5
	x.anchor = x.center
	_add(x)
	var h: Entry = Entry.new()
	h.key = "m:heart"
	h.kind = Kind.HEART
	h.tile = Vector2(HEART_TILE, HEART_TILE) * CELL
	h.center = h.tile * 0.5
	h.anchor = h.center
	_add(h)


## The pieces the shots and their marks are made of (ShotPieces), each drawn once.
func add_shot_pieces() -> void:
	if _index.has(ShotPieces.key(0)):
		return
	for piece: int in ShotPieces.Piece.size():
		var p: Entry = Entry.new()
		p.key = ShotPieces.key(piece)
		p.kind = Kind.PIECE
		p.frame = piece
		p.tile = ShotPieces.TILES[piece] * CELL
		p.center = ShotPieces.ANCHORS[piece] * CELL
		p.anchor = p.center
		_add(p)


## The chevron, dot and dash that route lines move (RoutePieces), each drawn once.
func add_route_pieces() -> void:
	if _index.has(RoutePieces.key(0)):
		return
	for piece: int in RoutePieces.Piece.size():
		var r: Entry = Entry.new()
		r.key = RoutePieces.key(piece)
		r.kind = Kind.ROUTE
		r.frame = piece
		r.tile = RoutePieces.TILES[piece] * CELL
		r.center = RoutePieces.ANCHORS[piece] * CELL
		r.anchor = r.center
		_add(r)


## Every look of a gate on a road that runs across or up and down the screen.
func add_gates() -> void:
	if _index.has(gate_key(0, false)):
		return
	for look: int in MapArt.Gate.size():
		for across: bool in [false, true]:
			var g: Entry = Entry.new()
			g.key = gate_key(look, across)
			g.kind = Kind.GATE
			g.tier = look
			g.frame = 1 if across else 0
			g.tile = Vector2(GATE_TILE, GATE_TILE) * CELL
			g.center = g.tile * 0.5
			g.anchor = g.center
			_add(g)


static func gate_key(look: int, across: bool) -> String:
	return "g:%d:%d" % [look, 1 if across else 0]


## Lays the sheet out at `scale` texels per local pixel and queues one draw. When that would be
## taller than MAX_HEIGHT it lowers the scale in steps of SCALE_STEP until it fits; texel_scale
## says what was used.
func bake(scale: float) -> void:
	var used: float = maxf(scale, MIN_SCALE)
	var height: int = _layout(used)
	while height > MAX_HEIGHT and used > MIN_SCALE + 0.001:
		used = maxf(used - SCALE_STEP, MIN_SCALE)
		height = _layout(used)
	size = Vector2i(WIDTH, maxi(height, 8))
	for type: StringName in enemy_rects:
		var rects: Array = enemy_rects[type]
		for frame: int in 4:
			rects[frame] = entries[_index[enemy_key(type, frame)]].rect
	for type: StringName in low_rects:
		var low: Array = low_rects[type]
		for frame: int in 4:
			low[frame] = entries[_index[low_key(type, frame)]].rect
	for mark: StringName in mark_rects:
		var marks: Array = mark_rects[mark]
		for frame: int in marks.size():
			marks[frame] = entries[_index[mark_key(mark, frame)]].rect
	bakes += 1
	_painter.queue_redraw()
	render_target_update_mode = SubViewport.UPDATE_ONCE


## The height the sheet would need at `scale`, without changing it. For tests and measuring.
func height_at(scale: float) -> int:
	return _layout(scale, false)


## Puts every entry on shelves, tallest first so a shelf wastes little, at `scale`. With `place` it
## sets texel_scale and every rect. Returns the height the sheet needs.
func _layout(scale: float, place: bool = true) -> int:
	if place:
		texel_scale = scale
	var order: Array[int] = []
	for i: int in entries.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		var ha: int = ceili(entries[a].tile.y * scale)
		var hb: int = ceili(entries[b].tile.y * scale)
		return ha > hb if ha != hb else a < b)
	var x: int = PAD
	var y: int = PAD
	var row_h: int = 0
	for i: int in order:
		var e: Entry = entries[i]
		var w: int = ceili(e.tile.x * scale)
		var h: int = ceili(e.tile.y * scale)
		if x + w + PAD > WIDTH:
			x = PAD
			y += row_h + PAD
			row_h = 0
		if place:
			e.rect = Rect2(float(x), float(y), float(w), float(h))
		x += w + PAD
		row_h = maxi(row_h, h)
	return y + row_h + PAD


## Called by the painter, inside its _draw().
func paint(canvas: CanvasItem) -> void:
	_draws += 1
	for e: Entry in entries:
		var at: Vector2 = e.rect.position + e.center * texel_scale
		match e.kind:
			Kind.TOWER:
				# Smaller about the ground line: the ground point stays where e.anchor says.
				var drop: float = Silhouettes.TOWER_GROUND * (1.0 - TOWER_SCALE) * CELL * texel_scale
				Silhouettes.draw_tower(canvas, e.type, e.tier, e.spec, at + Vector2(0.0, drop), CELL * texel_scale * TOWER_SCALE)
			Kind.ENEMY:
				Silhouettes.draw_enemy(canvas, e.type, at, Silhouettes.enemy_size(e.type, CELL) * texel_scale, e.frame)
			Kind.DROWSY:
				Silhouettes.draw_drowsy(canvas, at, CELL * texel_scale, e.frame)
			Kind.BUBBLE:
				Silhouettes.draw_bubble(canvas, at, CELL * texel_scale)
			Kind.BOOST:
				Silhouettes.draw_boost(canvas, at, CELL * texel_scale)
			Kind.HEART:
				Silhouettes.draw_glyph(canvas, &"heart", at, CELL * texel_scale * 0.92)
			Kind.GATE:
				MapArt.draw_gate_at(canvas, at, CELL * texel_scale, e.frame == 1, e.tier as MapArt.Gate)
			Kind.PIECE:
				ShotPieces.draw(canvas, e.frame, at, CELL * texel_scale)
			Kind.ROUTE:
				RoutePieces.draw(canvas, e.frame, at, CELL * texel_scale)
			Kind.MARK:
				Silhouettes.draw_mark(canvas, e.type, at, CELL * texel_scale, e.frame)
			Kind.LOW:
				_paint_low(canvas, e, at)


## A flyer with its body LOW_DROP lower and its soft shadow where it was. Silhouettes records the
## shapes (an InkPen with no canvas) and they are replayed here, the shadow apart.
func _paint_low(canvas: CanvasItem, e: Entry, at: Vector2) -> void:
	var box: float = Silhouettes.enemy_size(e.type, CELL) * texel_scale
	var pen: InkPen = InkPen.new(null)
	Silhouettes.enemy_into(pen, e.type, at, box, e.frame)
	var drop: Vector2 = Vector2(0.0, LOW_DROP * box)
	for s: InkPen.Shape in pen.shapes:
		var points: PackedVector2Array = s.points
		if s.width > 0.0 or s.color != Palette.SHADOW:
			points = PackedVector2Array()
			for p: Vector2 in s.points:
				points.append(p + drop)
		if s.width <= 0.0:
			canvas.draw_colored_polygon(points, s.color)
		else:
			canvas.draw_polyline(points, s.color, maxf(s.width, 1.0), true)


## How many times the sheet's pictures were really drawn (not just queued).
func draw_count() -> int:
	return _draws


func _add(e: Entry) -> void:
	_index[e.key] = entries.size()
	entries.append(e)
